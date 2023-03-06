FROM axrs/anvil:base-dart_2.17-dotnet_6.0-java_17-cloud

ENV CLJOG_VERSION=1.3.1
ENV CLOJURE_VERSION=1.10.3
ENV CLJ_TOOLS_VERSION=${CLOJURE_VERSION}.967
ENV DEBUG=1
ENV MAVEN_HOME=/usr/lib/mvn
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR /tmp

RUN apt update
RUN apt upgrade --yes
RUN apt install --yes \
    bash \
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
    make \
    maven \
    openssl \
    optipng \
    pngquant \
    postgresql \
    python3 \
    python3-dev \
    python3-pip \
    rsync \
    shellcheck \
    silversearcher-ag \
    tar \
    tidy \
    udev \
    util-linux \
    wget \
    zip
RUN aws --version \
 && az --version \
 && java -version \
 && lein --version \
 && mvn --version \
 && pip3 --version \
 && python3 --version

#--- Newer versions
RUN echo 'deb http://deb.debian.org/debian testing main' >> /etc/apt/sources.list
RUN apt update
RUN apt install --yes \
    nodejs \
    npm \
    shfmt
RUN node --version \
 && npm --version \

#--- Terraform
# https://www.hashicorp.com/official-packaging-guide
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
 && gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint \
 && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
 && apt update \
 && apt install --yes terraform

#--- Clojure-Tools
# https://clojure.org/guides/install_clojure#_linux_instructions
RUN wget "https://download.clojure.org/install/linux-install-${CLJ_TOOLS_VERSION}.sh" \
 && chmod +x "linux-install-${CLJ_TOOLS_VERSION}.sh" \
 && ./linux-install-${CLJ_TOOLS_VERSION}.sh \
 && clojure -e '(println "IT WORKS!")' \
 && rm linux-install-${CLJ_TOOLS_VERSION}.sh

#--- Node
RUN npm install --global npm
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

#-- CircleCI Tools
RUN wget 'https://raw.githubusercontent.com/jesims/circleci-tools/master/cancel-redundant-builds.sh' \
    -O /usr/local/bin/cancel-redundant-builds.sh

#-- cljog
RUN wget "https://raw.githubusercontent.com/axrs/cljog/${CLJOG_VERSION}/cljog" -O /usr/local/bin/cljog \
 && chmod +x /usr/local/bin/cljog \
 && wget "https://raw.githubusercontent.com/axrs/cljog/${CLJOG_VERSION}/example-scripts/echo.clj" \
 && chmod +x echo.clj \
 && ./echo.clj \
 && rm echo.clj

#-- permissions
RUN chmod -R a+rx /usr/local/bin/

#-- cleanup
RUN apt clean \
 && apt autoremove --yes \
 && rm -rf \
    /tmp/* \
    /var/cache/apk \
    $HOME/.cache \
    $HOME/.npm

#-- docker-compose
RUN pipx install docker-compose \
 && docker-compose --version

USER node
WORKDIR /home/node
ENV PATH="/usr/local/bin/dotnet:/home/node/.local/bin:${PATH}"

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
