FROM bitnami/minideb:stretch

WORKDIR /home/flux

RUN install_packages \
  openssh-client \
  ca-certificates \
  git \
  gnupg

COPY --from=bitnami/minideb-extras:stretch /usr/local/bin/tini /usr/local/bin/tini

# Add git hosts to known hosts file so we can use
# StrickHostKeyChecking with git+ssh
ADD ./known_hosts.sh /home/flux/known_hosts.sh
RUN sh /home/flux/known_hosts.sh /etc/ssh/ssh_known_hosts && \
    rm /home/flux/known_hosts.sh

# Add default SSH config, which points at the private key we'll mount
COPY ./ssh_config /etc/ssh/ssh_config

COPY ./kubectl /usr/local/bin/

# These are pretty static
LABEL maintainer="Weaveworks <help@weave.works>" \
      org.opencontainers.image.title="flux" \
      org.opencontainers.image.description="The Flux daemon, for synchronising your cluster with a git repo, and deploying new images" \
      org.opencontainers.image.url="https://github.com/weaveworks/flux" \
      org.opencontainers.image.source="git@github.com:weaveworks/flux" \
      org.opencontainers.image.vendor="Weaveworks" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="flux" \
      org.label-schema.description="The Flux daemon, for synchronising your cluster with a git repo, and deploying new images" \
      org.label-schema.url="https://github.com/weaveworks/flux" \
      org.label-schema.vcs-url="git@github.com:weaveworks/flux" \
      org.label-schema.vendor="Weaveworks"

ENTRYPOINT [ "/usr/local/bin/tini", "--", "fluxd" ]

# Get the kubeyaml binary (files) and put them on the path
COPY --from=quay.io/squaremo/kubeyaml:0.5.2 /usr/lib/kubeyaml /usr/lib/kubeyaml/
ENV PATH=/bin:/usr/bin:/usr/local/bin:/usr/lib/kubeyaml

COPY ./kubeconfig /root/.kube/config
COPY ./fluxd /usr/local/bin/

ARG BUILD_DATE
ARG VCS_REF

# These will change for every build
LABEL org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.build-date="$BUILD_DATE"
