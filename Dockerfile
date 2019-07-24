FROM node:12-alpine

#ENV CLJ_TOOLS_VERSION=1.9.0.381
ENV LEIN_VERSION=2.9.1
ENV LEIN_INSTALL=/usr/local/bin/
ENV MAVEN_VERSION=3.5.4
ENV MAVEN_HOME=/usr/lib/mvn
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV LEIN_ROOT=1
ENV DEBUG=1
ENV _JAVA_OPTIONS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAM=3g"

WORKDIR /tmp

RUN apk update --verbose && apk upgrade --verbose && apk add --verbose --upgrade \
	bash \
	build-base \
	ca-certificates \
	chromium \
	coreutils \
	curl \
	docker \
	file \
	fontconfig \
	git \
	gnupg \
	jq \
	maven \
	ncurses \
	openjdk8 \
	openssh \
	openssl \
	postgresql \
	py3-pip \
	python3 \
	rsync \
	ruby \
	ruby-bundler \
	ruby-dev \
	ruby-irb \
	ruby-rdoc \
	tar \
	the_silver_searcher \
	util-linux \
	wget \
	zip \
	&& rm -rf /var/cache/apk

#--- Leiningen
# https://github.com/docker-library/repo-info/blob/master/repos/clojure/remote/lein-2.9.1-alpine.md
RUN mkdir -p $LEIN_INSTALL \
      && wget -q https://raw.githubusercontent.com/technomancy/leiningen/$LEIN_VERSION/bin/lein-pkg \
      && echo "Comparing lein-pkg checksum ..." \ 
      && sha1sum lein-pkg \
      && echo "93be2c23ab4ff2fc4fcf531d7510ca4069b8d24a *lein-pkg" | sha1sum -c - \
      && mv lein-pkg $LEIN_INSTALL/lein \
      && chmod 0755 $LEIN_INSTALL/lein \
      && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip \
      && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip.asc \
      && gpg --batch --keyserver pool.sks-keyservers.net --recv-key 2B72BF956E23DE5E830D50F6002AF007D1A7CC18 \
      && echo "Verifying Jar file signature ..." \
      && gpg --verify leiningen-$LEIN_VERSION-standalone.zip.asc \
      && rm leiningen-$LEIN_VERSION-standalone.zip.asc \
      && mkdir -p /usr/share/java \
      && mv leiningen-$LEIN_VERSION-standalone.zip /usr/share/java/leiningen-$LEIN_VERSION-standalone.jar

RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.10.0"]])' > project.clj && lein deps && rm project.clj

#TODO: Uncomment when clj tools required (will need to install rlwrap)
#--- Clojure-Tools
#RUN curl -O https://download.clojure.org/install/linux-install-${CLJ_TOOLS_VERSION}.sh \
#	&& chmod +x linux-install-${CLJ_TOOLS_VERSION}.sh \
#	&& ./linux-install-${CLJ_TOOLS_VERSION}.sh

#--- Typical Node Tools
RUN npm install --global --unsafe-perm \
	dry-dry \
	gulp-cli \
	local-web-server \
	lumo-cljs \
	progress \
	wait-on

#-- Typical Python Tools
RUN ln -s /usr/bin/python3 /usr/bin/python \
  && ln -s /usr/bin/pip3 /usr/bin/pip
RUN pip3 install --upgrade pip && pip3 install --upgrade \
	awscli \
	awsebcli \
	&& rm -rf ~/.cache/pip
RUN aws --version && eb --version

#-- Install CircleCI Tools
RUN git clone -b master https://github.com/jesims/circleci-tools.git \
	&& cd circleci-tools \
	&& git pull \
	&& chmod +x ./cancel-redundant-builds.sh
ENV PATH=$PATH:/tmp/circleci-tools/
RUN node -v > .node_version

#Bug in npm on AWS's Hyperv virtualization on M5 instances https://github.com/nodejs/docker-node/issues/813
CMD npm config set unsafe-perm true

#TODO don't run as root

CMD ["bash"]
