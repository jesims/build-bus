FROM alpine:latest

# ENV CLJ_TOOLS_VERSION=1.9.0.348
ENV LEIN_VERSION=2.8.1
ENV MAVEN_VERSION=3.5.2
ENV MAVEN_HOME=/usr/lib/mvn

WORKDIR /tmp

RUN apk add --verbose --update --upgrade --no-cache \
	bash \
	build-base \
	ca-certificates \
	curl \
	docker \
	file \
	fontconfig \
	git \
	gnupg \
	jq \
	ncurses \
	nodejs-npm \
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
	zip

#--- Maven (from https://github.com/Zenika/alpine-maven/blob/master/jdk8/Dockerfile)
ENV PATH=$PATH:$MAVEN_HOME/bin

RUN wget http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz && \
  tar -zxvf apache-maven-$MAVEN_VERSION-bin.tar.gz && \
  rm apache-maven-$MAVEN_VERSION-bin.tar.gz && \
  mv apache-maven-$MAVEN_VERSION /usr/lib/mvn

# Todo: Uncomment when clj tools required (will need to install rlwrap)
#--- Clojure-Tools
# RUN curl -O https://download.clojure.org/install/linux-install-$CLJ_TOOLS_VERSION.sh \
#  && chmod +x linux-install-$CLJ_TOOLS_VERSION.sh \
#  ./linux-install-$CLJ_TOOLS_VERSION.sh

#--- Leiningen (from https://github.com/sgerrand/alpine-pkg-leiningen)
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-leiningen/master/sgerrand.rsa.pub \
	&& wget https://github.com/sgerrand/alpine-pkg-leiningen/releases/download/${LEIN_VERSION}-r0/leiningen-${LEIN_VERSION}-r0.apk \
	&& apk add leiningen-${LEIN_VERSION}-r0.apk
ENV LEIN_ROOT 1

# Install clojure 1.9.0 so users don't have to download it every time
RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.9.0"]])' > project.clj \
  && lein deps && rm project.clj

#--- Typical Node Tools
RUN npm install --global --unsafe-perm \
	gulp-cli \
#	lumo-cljs \
	cljs \
	wait-on

#--- Typical Ruby Tools
RUN gem install \
    bundler

#-- Typical Python Tools
RUN ln -s /usr/bin/python3 /usr/bin/python \
  && ln -s /usr/bin/pip3 /usr/bin/pip
RUN pip3 install --upgrade \
    awscli \
    awsebcli

#-- Install CircleCI Tools
RUN git clone -b master https://github.com/jesims/circleci-tools.git \
  && cd circleci-tools \
  && git pull \
  && chmod +x ./cancel-redundant-builds.sh
ENV PATH=$PATH:/tmp/circleci-tools/
RUN node -v > .node_version
