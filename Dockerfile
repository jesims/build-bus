FROM node:13-alpine

ENV \
AWS_CLI_VERSION=1.17.1 \
BOOT_INSTALL=/usr/local/bin/ \
BOOT_VERSION=2.8.3 \
CLJOG_VERSION=0.2.1 \
CLJ_TOOLS_VERSION=1.10.1.492 \
DEBUG=1 \
LEIN_INSTALL=/usr/local/bin/ \
LEIN_ROOT=1 \
LEIN_VERSION=2.9.1 \
MAVEN_HOME=/usr/lib/mvn \
MAVEN_VERSION=3.5.4 \
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
_JAVA_OPTIONS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAM=3g"

WORKDIR /tmp

RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories \
 && apk --no-cache upgrade \
 && apk add --verbose --no-cache --upgrade --virtual .build-bus \
    bash \
    build-base \
    ca-certificates \
    chromium \
    chromium-chromedriver \
    coreutils \
    curl \
    docker \
    docker-compose \
    file \
    fontconfig \
    gifsicle \
    git \
    gnupg \
    jq \
    libjpeg-turbo-utils \
    maven \
    ncurses \
    openjdk8 \
    openssh \
    openssl \
    optipng \
    pngquant \
    postgresql \
    py3-pip \
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
 && chromedriver --version \
 && chromium-browser --version

#--- Leiningen
# https://hub.docker.com/_/clojure
# https://github.com/Quantisan/docker-clojure/blob/master/target/openjdk-8-stretch/lein/Dockerfile
RUN mkdir -p $LEIN_INSTALL \
 && wget -q https://raw.githubusercontent.com/technomancy/leiningen/$LEIN_VERSION/bin/lein-pkg \
 && echo 'Comparing lein-pkg checksum ...' \
 && sha1sum lein-pkg \
 && echo '93be2c23ab4ff2fc4fcf531d7510ca4069b8d24a *lein-pkg' | sha1sum -c - \
 && mv lein-pkg $LEIN_INSTALL/lein \
 && chmod 0755 $LEIN_INSTALL/lein \
 && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip \
 && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip.asc \
 && gpg --batch --keyserver pool.sks-keyservers.net --recv-key 2B72BF956E23DE5E830D50F6002AF007D1A7CC18 \
 && echo 'Verifying Jar file signature ...' \
 && gpg --verify leiningen-$LEIN_VERSION-standalone.zip.asc \
 && rm leiningen-$LEIN_VERSION-standalone.zip.asc \
 && mkdir -p /usr/share/java \
 && mv leiningen-$LEIN_VERSION-standalone.zip /usr/share/java/leiningen-$LEIN_VERSION-standalone.jar

RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.10.1"]])' > project.clj \
 && lein deps \
 && rm project.clj

#--- Boot
# https://github.com/Quantisan/docker-clojure/blob/master/target/openjdk-8/debian/boot/Dockerfile
RUN mkdir -p $BOOT_INSTALL \
 && wget -q https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh \
 && echo "Comparing installer checksum..." \
 && echo "f717ef381f2863a4cad47bf0dcc61e923b3d2afb *boot.sh" | sha1sum -c - \
 && mv boot.sh $BOOT_INSTALL/boot \
 && chmod 0755 $BOOT_INSTALL/boot

ENV PATH=$PATH:$BOOT_INSTALL
ENV BOOT_AS_ROOT=yes
RUN boot --update \
 && boot --version | sed 's/BOOT_CLOJURE_VERSION.*/BOOT_CLOJURE_VERSION=1.10.1/' > ~/.boot/boot.properties

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
    'colorama<0.4.0,>=0.3.9' \
    'urllib3<1.25,>=1.24.1' \
 && aws --version

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
