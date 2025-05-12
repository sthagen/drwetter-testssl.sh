## Usage

Run the image with `testssl.sh` options appended (default is `--help`). The container entrypoint is already set to `testsl.sh` as the command for convenience.

```bash
docker run --rm -it ghcr.io/testssl/testssl.sh:3.2 --fs github.com
```

### Output files

Keep in mind that any output file (_`--log`, `--html`, `--json`, etc._) will be created within the container.

Use a volume bind mount to a local host directory to access the files outside of the container. Set a working directory for the container and any options output prefix can then use a relative path, like this example for `--htmfile`:

```bash
# Writes the HTML output to the host path: /tmp/example.com_p443-<date>-<time>.html
docker run --rm -it -v /tmp:/data --workdir /data ghcr.io/testssl/testssl.sh:3.2 --htmlfile ./ example.com
```

> [!NOTE]
> - The UID/GID ownership of the file will be created by the container user `testssl` (`1000:1000`), with permissions `644`.
> - Your host directory must permit the `testssl` container user or group to write to that host volume. You could alternatively use [`docker cp`](https://docs.docker.com/reference/cli/docker/container/cp/).

## Images

### Available at DockerHub and GHCR

You can pull the image from either of these registries:
- DockerHub: [`drwetter/testssl.sh`](https://hub.docker.com/r/drwetter/testssl.sh)
- GHCR: [`ghcr.io/testssl/testssl.sh`](https://github.com/testssl/testssl.sh/pkgs/container/testssl.sh)

Supported tags:
- `3.2` / `latest`
- `3.0` is the old stable version ([soon to become EOL](https://github.com/testssl/testssl.sh/tree/3.0#status))

### Building the `testssl.sh` container image

You can build with a standard `git clone` + `docker build`. Tagging the image will make it easier to reference.

```bash
mkdir /tmp/testssl && cd /tmp/testssl
git clone --branch 3.2 --depth 1 https://github.com/testssl/testssl.sh .
docker build --tag localhost/testssl.sh:3.2 .
```

There are two base images supported:
- openSUSE Leap ([`Dockerfile`](./Dockerfile)), glibc-based + faster.
- Alpine ([`Dockerfile`](./Dockerfile.alpine)), musl-based + half the size.

The Alpine variant is made available if you need broarder platform support, or an image about 30MB smaller at the expense of slightly slower performance.

#### Tip - Remote build context + `Dockerfile`

You can build with a single command instead via:

```bash
docker build --tag localhost/testssl.sh:3.2 https://github.com/testssl/testssl.sh.git#3.2
```

> [!NOTE]
> This will produce a slightly larger image as [`.dockerignore` is not supported with remote build contexts](https://github.com/docker/buildx/issues/3169).

---

To build the Alpine image instead, additionally provide the ([alternative `Dockerfile`](./Dockerfile.alpine)) via the `--file` option:

```bash
docker build \
  --tag localhost/testssl.sh:3.2-alpine \
  --file https://raw.githubusercontent.com/testssl/testssl.sh/3.2/Dockerfile.alpine \
  https://github.com/testssl/testssl.sh.git#3.2
```
