FROM node:12.4.0-alpine

ENV AWS_CLI_VERSION=1.18.41 \
    CLJOG_VERSION=1.0.0 \
    CLJ_TOOLS_VERSION=1.10.1.536 \
    DEBUG=1 \
    LEIN_INSTALL=/usr/local/bin/ \
    LEIN_ROOT=1 \
    LEIN_VERSION=2.9.3 \
    MAVEN_HOME=/usr/lib/mvn \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR /tmp

RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" > /etc/apk/repositories \
 && echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories \
 && apk upgrade \
 #TODO remove specifying respository once openjdk14 is in latest-stable branch
 && apk add --verbose --repository "http://dl-cdn.alpinelinux.org/alpine/edge/testing" \
    openjdk14 \
 && java -version \
 && apk add --verbose --upgrade \
    bash \
    build-base \
    ca-certificates \
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
 && mvn --version \
 && apk add --verbose --repository "http://dl-cdn.alpinelinux.org/alpine/3.9/community" \
    'terraform<0.12'

#--- Leiningen
# https://hub.docker.com/_/clojure
# https://github.com/Quantisan/docker-clojure/blob/master/target/openjdk-8-stretch/lein/Dockerfile
RUN mkdir -p $LEIN_INSTALL \
 && wget -q https://raw.githubusercontent.com/technomancy/leiningen/$LEIN_VERSION/bin/lein-pkg \
 && echo 'Comparing lein-pkg checksum ...' \
 && sha256sum lein-pkg \
 && echo '36f879a26442648ec31cfa990487cbd337a5ff3b374433a6e5bf393d06597602 *lein-pkg' | sha256sum -c - \
 && mv lein-pkg $LEIN_INSTALL/lein \
 && chmod 0755 $LEIN_INSTALL/lein \
 && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip \
 && mkdir -p /usr/share/java \
 && mv leiningen-$LEIN_VERSION-standalone.zip /usr/share/java/leiningen-$LEIN_VERSION-standalone.jar

RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.10.1"]])' > project.clj \
 && lein deps \
 && rm project.clj

#--- Clojure-Tools
# https://clojure.org/guides/getting_started#_installation_on_linux
RUN curl -O https://download.clojure.org/install/linux-install-${CLJ_TOOLS_VERSION}.sh \
 && chmod +x linux-install-${CLJ_TOOLS_VERSION}.sh \
 && ./linux-install-${CLJ_TOOLS_VERSION}.sh \
 && clojure -e '(println "IT WORKS!")'

#--- Typical Node Tools
RUN npm install --global npm \
 && npm install --global \
    dry-dry \
    gulp-cli \
    local-web-server \
    lumo-cljs \
    progress \
    remark-cli \
    wait-on

#-- Typical Python Tools
RUN ln -s /usr/bin/python3 /usr/bin/python \
 && ln -s /usr/bin/pip3 /usr/bin/pip \
 && pip3 --no-cache-dir install --upgrade pip setuptools \
 && pip3 --no-cache-dir install  \
    awscli==${AWS_CLI_VERSION} \
    azure-cli \
    'colorama<0.4.0,>=0.3.9' \
    'urllib3<1.25,>=1.24.1' \
    docker-compose \
 && aws --version \
 && az --version \
 && docker-compose --version

#-- Install CircleCI Tools
RUN git clone -b master https://github.com/jesims/circleci-tools.git \
 && cd circleci-tools \
 && git pull \
 && chmod +x ./cancel-redundant-builds.sh
ENV PATH=$PATH:/tmp/circleci-tools/
RUN node -v > .node_version

#-- Install cljog
RUN wget https://raw.githubusercontent.com/axrs/cljog/${CLJOG_VERSION}/cljog \
 && chmod ua+x cljog \
 && mv cljog /usr/local/bin/ \
 && wget https://raw.githubusercontent.com/axrs/cljog/${CLJOG_VERSION}/example-scripts/echo.clj \
 && chmod u+x echo.clj \
 && ./echo.clj \
 && rm echo.clj

#Bug in npm on AWS's Hyperv virtualization on M5 instances https://github.com/nodejs/docker-node/issues/813
CMD npm config set unsafe-perm true

USER node

ENV LEIN_ROOT=0

CMD ["bash"]
