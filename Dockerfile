FROM node:12.22.12-alpine3.15

ENV AWS_CLI_VERSION=1.25.63
ENV AZ_CLI_VERSION=2.33.1
ENV CLJOG_VERSION=1.3.1
ENV CLOJURE_VERSION=1.10.3
ENV CLJ_TOOLS_VERSION=${CLOJURE_VERSION}.967
ENV DEBUG=1
ENV MAVEN_HOME=/usr/lib/mvn
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV DOT_NET_SDK_VERSION=6.0

WORKDIR /tmp

RUN apk update --verbose
RUN apk upgrade --verbose
RUN apk add --verbose --repository 'http://dl-cdn.alpinelinux.org/alpine/v3.15/community' \
    shellcheck
#TODO remove specifying repository once we're using terraform 0.12 JESI-3036
RUN apk add --verbose --repository 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' \
    'terraform<0.12'
#TODO move build specific deps (e.g. gcc, lib*) to build specific virtual packages
RUN apk add --verbose \
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
    tidyhtml \
    jq \
    libc-dev \
    libffi-dev \
    libjpeg-turbo-utils \
    make \
    maven \
    ncurses \
    openjdk15 \
    openssh \
    openssl \
    openssl-dev \
    optipng \
    pngquant \
    postgresql \
    py3-pip \
    python3-dev \
    python3 \
    # NPM node-sass requirement
    python2 \
    rsync \
    shfmt \
    tar \
    the_silver_searcher \
    ttf-opensans \
    udev \
    util-linux \
    wget \
    zip \
    # requirements for dotnet sdk
    icu-libs \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    zlib
RUN rm -rf /var/cache/apk
RUN chromedriver --version \
 && chromium-browser --version \
 && java -version \
 && mvn --version \
 && python --version \
 && python2 --version \
 && python3 --version

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
RUN npm install --global \
    dry-dry \
    gulp-cli \
    local-web-server \
    lumo-cljs \
    progress \
    remark-cli \
    wait-on \
 && rm -rf $HOME/.npm

#-- Python
RUN rm -f /usr/bin/python /usr/bin/pip \
 && ln -s /usr/bin/python3 /usr/bin/python \
 && ln -s /usr/bin/pip3 /usr/bin/pip \
 && pip3 install --upgrade pipx \
 && python3 -m pipx ensurepath

#-- .NET SDK
RUN wget https://dot.net/v1/dotnet-install.sh \
 && chmod +x ./dotnet-install.sh \
 && ./dotnet-install.sh -c ${DOT_NET_SDK_VERSION} --install-dir /usr/local/bin/dotnet \
 && chmod -R a+x /usr/local/bin/dotnet \
 && rm dotnet-install.sh

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
WORKDIR /home/node
ENV PATH="/usr/local/bin/dotnet:/home/node/.local/bin:${PATH}"

# verify installs for node user
RUN lein --version
RUN dotnet --version

RUN pipx install awscli==${AWS_CLI_VERSION}
RUN pipx install azure-cli==${AZ_CLI_VERSION}
RUN pipx install docker-compose
RUN aws --version \
 && az --version \
 && docker-compose --version

#AZ configuration is user specific. This needs to be run under the node user
RUN az config set extension.use_dynamic_install=yes_without_prompt \
 && az extension add --name automation \
 && az automation --help

ENV LEIN_ROOT=0

# Environment Vars for tools versions
RUN export NODE_VERSION=$(node -v)
RUN export JAVA_VERSION=$(java --version | head -1 | cut -f2 -d' ')
RUN export DOTNET_VERSION=$(dotnet --version)

RUN mkdir -p /home/node/.ssh
COPY --chown=node:node ssh-config /home/node/.ssh/config

ENTRYPOINT ["bash"]
