# syntax=docker/dockerfile:1.4
#
# Multi-stage build for miso.
# Builder installs git and fetches the Atlantis and OpenTofu binaries.
# Runtime is UBI micro: no package manager and no interactive shell.
# git is dynamically linked here, so its helper binaries and shared libraries
# must be copied explicitly for Atlantis to clone repositories at runtime.

FROM registry.access.redhat.com/ubi9/ubi:latest AS builder

# Build-time version pins keep Atlantis and OpenTofu aligned with compose config.
ARG OPENTOFU_VERSION=1.9.0
ARG ATLANTIS_VERSION=0.42.0

# UBI already includes curl-minimal, so avoid installing full curl to prevent
# package conflicts during the builder setup.
RUN dnf install -y git unzip findutils && dnf clean all

# OpenTofu is a Go binary and can be copied directly into the runtime image.
RUN curl -fsSL \
      "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.zip" \
      -o /tmp/tofu.zip \
    && unzip /tmp/tofu.zip tofu -d /tmp/ \
    && chmod +x /tmp/tofu

# Atlantis is also a static Go binary, so no additional runtime packaging is needed.
RUN curl -fsSL \
      "https://github.com/runatlantis/atlantis/releases/download/v${ATLANTIS_VERSION}/atlantis_linux_amd64.zip" \
      -o /tmp/atlantis.zip \
    && unzip /tmp/atlantis.zip atlantis -d /tmp/ \
    && chmod +x /tmp/atlantis

# git helpers such as git-remote-https are required for Atlantis clone operations.
RUN mkdir -p /gitdeps \
    && for bin in /usr/bin/git \
                  /usr/libexec/git-core/git-remote-https \
                  /usr/libexec/git-core/git-remote-http; do \
         ldd "$bin" 2>/dev/null \
           | awk '/=>/{print $3}' \
           | xargs -I{} cp -Lv {} /gitdeps/ 2>/dev/null || true; \
       done

# ubi-micro has no useradd, so the runtime user database is assembled manually.
RUN echo "atlantis:x:1000:1000::/home/atlantis:/sbin/nologin" > /tmp/passwd \
    && echo "atlantis:x:1000:" > /tmp/group \
    && mkdir -p /home/atlantis && chown 1000:1000 /home/atlantis

FROM registry.access.redhat.com/ubi9/ubi-micro:latest

# Required for HTTPS access to GitHub, providers, and other remote registries.
COPY --from=builder /etc/pki /etc/pki

# Carry over the non-root user and home directory prepared in the builder image.
COPY --from=builder /tmp/passwd /etc/passwd
COPY --from=builder /tmp/group /etc/group
COPY --from=builder --chown=1000:1000 /home/atlantis /home/atlantis

# Copy git, its helper executables, shared assets, and runtime libraries.
COPY --from=builder /usr/bin/git /usr/bin/git
COPY --from=builder /usr/libexec/git-core/ /usr/libexec/git-core/
COPY --from=builder /usr/share/git-core/ /usr/share/git-core/
COPY --from=builder /gitdeps/ /usr/lib64/

# OpenTofu and Atlantis are the only first-class runtime binaries in the image.
COPY --from=builder /tmp/tofu /usr/local/bin/tofu
COPY --from=builder /tmp/atlantis /usr/local/bin/atlantis

ENV HOME=/home/atlantis \
    GIT_EXEC_PATH=/usr/libexec/git-core

USER 1000
WORKDIR /home/atlantis
EXPOSE 4141

ENTRYPOINT ["/usr/local/bin/atlantis"]
CMD ["server"]
