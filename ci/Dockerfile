ARG ARG_TEST_IMAGE_NAME=hexpm/elixir
ARG ARG_TEST_IMAGE_VERSION=1.14.5-erlang-25.3.2.6-ubuntu-jammy-20230126

FROM ${ARG_TEST_IMAGE_NAME}:${ARG_TEST_IMAGE_VERSION}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    DISPLAY=:99.0 \
    CHROMEDRIVER_VERSION='123.0.6312.105' \
    NODE_MAJOR=18

RUN set -euxo pipefail \
    && apt update \
    && apt -y install autoconf build-essential libgmp3-dev libtool ca-certificates curl gnupg unzip wget git postgresql gosu\
    && curl -L -O "https://storage.googleapis.com/chrome-for-testing-public/${CHROMEDRIVER_VERSION}/linux64/chromedriver-linux64.zip" \
    && unzip chromedriver-linux64.zip \
    && chmod +x chromedriver-linux64/chromedriver \
    && mv chromedriver-linux64/chromedriver /usr/local/bin \
    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt -y install ./google-chrome-stable_current_amd64.deb \
    && apt update \
    && apt -y install libstdc++6 \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt update \
    && apt -y install nodejs

