# syntax=docker.io/docker/dockerfile:1

ARG LEAP_VERSION=15.6
ARG INSTALL_ROOT=/rootfs

FROM opensuse/leap:${LEAP_VERSION} AS builder
ARG CACHE_ZYPPER=/tmp/cache/zypper
ARG INSTALL_ROOT
RUN \
  # /etc/os-release provides ${VERSION_ID} for usage in ZYPPER_OPTIONS:
  source /etc/os-release \
  # We don't need the openh264.repo and the non-oss repos, just costs build time (repo caches).
  && zypper removerepo repo-openh264 repo-non-oss repo-update-non-oss \
  && export ZYPPER_OPTIONS=( --releasever "${VERSION_ID}" --installroot "${INSTALL_ROOT}" --cache-dir "${CACHE_ZYPPER}" ) \
  && zypper "${ZYPPER_OPTIONS[@]}" --gpg-auto-import-keys refresh \
  && zypper "${ZYPPER_OPTIONS[@]}" --non-interactive install --download-in-advance --no-recommends \
       bash procps grep gawk sed coreutils busybox ldns libidn2-0 socat openssl curl \
  && zypper "${ZYPPER_OPTIONS[@]}" clean --all \
  ## Cleanup (reclaim approx 13 MiB):
  # None of this content should be relevant to the container:
  && rm -r "${INSTALL_ROOT}/usr/share/"{licenses,man,locale,doc,help,info} \
           "${INSTALL_ROOT}/usr/share/misc/termcap" \
           "${INSTALL_ROOT}/usr/lib/sysimage/rpm"


# Create a new image with the contents of ${INSTALL_ROOT}
FROM scratch AS base-leap
ARG INSTALL_ROOT
COPY --link --from=builder ${INSTALL_ROOT} /
RUN \
  # Creates symlinks for any other commands that busybox can provide that
  # aren't already provided by coreutils (notably hexdump + tar, see #2403):
  # NOTE: `busybox --install -s` is not supported via the leap package, manually symlink commands.
  ln -s /usr/bin/busybox /usr/bin/tar \
  && ln -s /usr/bin/busybox /usr/bin/hexdump \
  && ln -s /usr/bin/busybox /usr/bin/xxd \
  # Add a non-root user `testssl`, this is roughly equivalent to the `useradd` command:
  # useradd --uid 1000 --user-group --create-home --shell /bin/bash testssl
  && echo 'testssl:x:1000:1000::/home/testssl:/bin/bash' >> /etc/passwd \
  && echo 'testssl:x:1000:' >> /etc/group \
  && echo 'testssl:!::0:::::' >> /etc/shadow \
  && install --mode 2755 --owner testssl --group testssl --directory /home/testssl \
  # The home directory will install a copy of `testssl.sh`, symlink the script to be used as a command:
  && ln -s /home/testssl/testssl.sh /usr/local/bin/testssl.sh

# Runtime config:
USER testssl
ENTRYPOINT ["testssl.sh"]
CMD ["--help"]

# Final image stage (add `testssl.sh` project files)
# Choose either one as the final stage (defaults to last stage, `dist-local`)

# 62MB Image (Remote repo clone, cannot filter content through `.dockerignore`):
FROM base-leap AS dist-git
ARG GIT_URL=https://github.com/testssl/testssl.sh.git
ARG GIT_BRANCH
ADD --chown=testssl:testssl ${GIT_URL}#${GIT_BRANCH?branch-required} /home/testssl

# 54MB Image (Local repo copy from build context, uses `.dockerignore`):
FROM base-leap AS dist-local
COPY --chown=testssl:testssl . /home/testssl/
