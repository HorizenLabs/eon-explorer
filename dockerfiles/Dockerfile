ARG ARG_IMAGE_NAME=hexpm/elixir
ARG ARG_IMAGE_VERSION=1.14.5-erlang-25.3.2.6-ubuntu-jammy-20230126

FROM $ARG_IMAGE_NAME:$ARG_IMAGE_VERSION as builder

SHELL ["/bin/bash", "-c"]

ARG ARG_MIX_ENV=prod
ARG ARG_NODE_MAJOR=18
ARG ARG_WORKDIR=/app

ENV DEBIAN_FRONTEND=noninteractive \
    WORKDIR=$ARG_WORKDIR \
    NODE_MAJOR=$ARG_NODE_MAJOR \
    MIX_ENV=$ARG_MIX_ENV \
    MIX_HOME=/opt/mix

WORKDIR $WORKDIR

COPY ./mix.exs ./mix.lock ./
COPY ./apps ./apps
COPY ./config ./config
COPY ./rel ./rel

RUN set -euxo pipefail \
    && apt update \
    && apt -y install build-essential libtool ca-certificates curl gnupg git \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt update \
    && apt -y install nodejs \
    && mix local.hex --force \
    && mix do deps.get, local.rebar --force, deps.compile, compile \
    && cd /app/apps/block_scout_web/assets/ && npm ci && npm run deploy \
    && cd /app/apps/explorer/ && npm ci \
    && cd /app && mix release blockscout

##############################################################
FROM ${ARG_IMAGE_NAME}:${ARG_IMAGE_VERSION}

SHELL ["/bin/bash", "-c"]

ARG ARG_GOSU_VERSION=1.16
ARG ARG_TINI_VERSION=v0.19.0
ARG ARG_WORKDIR=/app
ARG ARG_MIX_ENV=prod

ENV DEBIAN_FRONTEND=noninteractive \
    GOSU_VERSION=$ARG_GOSU_VERSION \
    TINI_VERSION=$ARG_TINI_VERSION \
    WORKDIR=$ARG_WORKDIR \
    MIX_ENV=$ARG_MIX_ENV

WORKDIR $WORKDIR

COPY --from=builder /app/_build/$MIX_ENV/rel/blockscout ./
COPY --from=builder /app/apps/explorer/node_modules ./node_modules
COPY --from=builder /app/config/config_helper.exs ./config/config_helper.exs
COPY ./dockerfiles/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -eEuo pipefail  \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /app/bin/blockscout \
    && apt-get update && apt-get -y install apt-utils && apt-get -y dist-upgrade \
    && apt-get -y --no-install-recommends install ca-certificates curl libpcre3 \
    && savedAptMark="$(apt-mark showmanual)" \
    && if ! command -v gosu &> /dev/null; then \
      if ! command -v gpg2 &> /dev/null; then \
        apt-get install -y --no-install-recommends gnupg2 dirmngr; \
      fi \
      && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
      && curl -sSfL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" > /usr/local/bin/gosu \
      && curl -sSfL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" > /usr/local/bin/gosu.asc \
      && export GNUPGHOME="$(mktemp -d)" \
      && ( gpg2 --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 || \
       gpg2 --batch --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 || \
       gpg2 --batch --keyserver pgp.mit.edu --recv-key B42F6819007F00F88E364FD4036A9C25BF357DD4 ) \
      && gpg2 --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
      && ( gpgconf --kill dirmngr || true ) \
      && ( gpgconf --kill gpg-agent || true ) \
      && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
      && unset GNUPGHOME \
      && chmod +x /usr/local/bin/gosu \
      && gosu --version; \
    fi \
    && if ! command -v tini &> /dev/null; then \
      if ! command -v gpg2 &> /dev/null; then \
        apt-get install -y --no-install-recommends gnupg2 dirmngr; \
      fi \
      && curl -sSfL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini" > /usr/local/bin/tini \
      && curl -sSfL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini.asc" > /usr/local/bin/tini.asc \
      && export GNUPGHOME="$(mktemp -d)" \
      && ( gpg2 --batch --keyserver hkps://keys.openpgp.org --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 || \
       gpg2 --batch --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 || \
       gpg2 --batch --keyserver pgp.mit.edu --recv-key 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 ) \
      && gpg2 --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
      && ( gpgconf --kill dirmngr || true ) \
      && ( gpgconf --kill gpg-agent || true ) \
      && rm -rf "$GNUPGHOME" /usr/local/bin/tini.asc \
      && unset GNUPGHOME \
      && chmod +x /usr/local/bin/tini \
      && tini --version; \
    fi \
    && apt-mark auto '.*' &> /dev/null && [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark &> /dev/null \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/cache/apt/archives/*.deb /var/lib/apt/lists/* /root/.cache /tmp/*


ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

CMD ["/app/bin/blockscout", "start"]
