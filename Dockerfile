FROM node:12.4.0-alpine

ENV AWS_CLI_VERSION=1.18.41
ENV CLJOG_VERSION=1.0.0
ENV CLOJURE_VERSION=1.10.1
ENV CLJ_TOOLS_VERSION=${CLOJURE_VERSION}.536
ENV DEBUG=1
ENV MAVEN_HOME=/usr/lib/mvn
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR /tmp

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/main' > /etc/apk/repositories \
 && echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' >> /etc/apk/repositories \
 && apk update --verbose \
 && apk upgrade --verbose \
 #TODO remove specifying respository once we're using terraform 0.12 JESI-3036
 && apk add --verbose --no-cache --repository 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' \
    'terraform<0.12' \
 #TODO remove specifying respository once openjdk14 is in latest-stable branch
 && apk add --verbose --no-cache --repository 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
    openjdk14 \
 #TODO move build specific deps (e.g. gcc, lib*) to build specific virtual packages
 && apk add --verbose \
    bash \
    build-base \
    chromium \
    chromium-chromedriver \
    coreutils \
    curl \
    docker \
    file \
    fontconfig \
    gcc \
    gifsicle \
    git \
    gnupg \
    jq \
    libc-dev \
    libffi-dev \
    libjpeg-turbo-utils \
    make \
    maven \
    ncurses \
    openssh \
    openssl \
    openssl-dev \
    optipng \
    pngquant \
    postgresql \
    py3-pip \
    python3-dev \
    python3 \
    rsync \
    shellcheck \
    tar \
    the_silver_searcher \
    ttf-opensans \
    udev \
    util-linux \
    wget \
    zip \
 && rm -rf /var/cache/apk \
 && chromedriver --version \
 && chromium-browser --version \
 && java -version \
 && mvn --version

#--- Leiningen
# Based on https://github.com/juxt/docker/blob/master/alpine-clojure/Dockerfile
ENV LEIN_INSTALL=/usr/local/bin/lein \
    LEIN_ROOT=1

RUN apk add --no-cache --virtual .lein ca-certificates \
 && wget 'https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein' \
    -O $LEIN_INSTALL \
 && chmod +x $LEIN_INSTALL \
 && apk del .lein \
 && lein --version

#--- Clojure-Tools
# https://clojure.org/guides/getting_started#_installation_on_linux
RUN wget "https://download.clojure.org/install/linux-install-${CLJ_TOOLS_VERSION}.sh" \
 && chmod +x "linux-install-${CLJ_TOOLS_VERSION}.sh" \
 && ./linux-install-${CLJ_TOOLS_VERSION}.sh \
 && clojure -e '(println "IT WORKS!")' \
 && rm linux-install-${CLJ_TOOLS_VERSION}.sh

#--- Node
RUN npm install --global npm \
 && npm install --global \
    dry-dry \
    gulp-cli \
    local-web-server \
    lumo-cljs \
    progress \
    remark-cli \
    wait-on \
 && rm -rf $HOME/.npm

#-- Python
RUN ln -s /usr/bin/python3 /usr/bin/python \
 && ln -s /usr/bin/pip3 /usr/bin/pip \
 && pip3 install --upgrade pip setuptools \
 && pip3 install \
    awscli==${AWS_CLI_VERSION} \
    azure-cli \
    'colorama<0.4.0,>=0.3.9' \
    'urllib3<1.25,>=1.24.1' \
    docker-compose \
 && rm -rf $HOME/.cache \
 && aws --version \
 && az --version \
 && docker-compose --version

#-- CircleCI Tools
RUN wget 'https://raw.githubusercontent.com/jesims/circleci-tools/master/cancel-redundant-builds.sh' \
    -O /usr/local/bin/cancel-redundant-builds.sh

#-- cljog
RUN wget "https://raw.githubusercontent.com/axrs/cljog/${CLJOG_VERSION}/cljog" \
    -O /usr/local/bin/cljog \
 && chmod +x /usr/local/bin/cljog \
 && wget "https://raw.githubusercontent.com/axrs/cljog/${CLJOG_VERSION}/example-scripts/echo.clj" \
 && chmod +x echo.clj \
 && ./echo.clj \
 && rm echo.clj

#-- permissions
RUN chmod -R a+rx /usr/local/bin/

#-- cleanup
RUN rm -rf \
    /tmp/* \
    /var/cache/apk \
    $HOME/.cache \
    $HOME/.npm

#Bug in npm on AWS's Hyperv virtualization on M5 instances https://github.com/nodejs/docker-node/issues/813
RUN npm config set unsafe-perm true

USER node

ENV LEIN_ROOT=0

WORKDIR /home/node

#-- create .node_version
RUN node -v > .node_version

ENTRYPOINT ["bash"]
