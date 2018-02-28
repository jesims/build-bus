FROM alpine:latest

ENV LEIN_VERSION=2.8.1
ENV LEIN_INSTALL=/usr/local/bin/
ENV LEIN_GPG_KEY=2B72BF956E23DE5E830D50F6002AF007D1A7CC18

WORKDIR /tmp

RUN apk add --verbose --update --upgrade --no-cache \
	bash \
	build-base \
	ca-certificates \
	curl \
	docker \
	fontconfig \
	git \
	gnupg \
	jq \
	nodejs-npm \
	openjdk8-jre \
	openssh \
	openssl \
	postgresql \
	py-pip \
	python \
	rsync \
	ruby \
	ruby-bundler \
	ruby-irb \
	ruby-rdoc \
	tar \
	the_silver_searcher \
	wget

#--- Leiningen (from  https://github.com/Quantisan/docker-clojure/blob/master/alpine/lein/Dockerfile)

# Download the whole repo as an archive
RUN mkdir -p $LEIN_INSTALL \
  && wget -q https://raw.githubusercontent.com/technomancy/leiningen/$LEIN_VERSION/bin/lein-pkg \
  && echo "Comparing lein-pkg checksum ..." \
  && echo "019faa5f91a463bf9742c3634ee32fb3db8c47f0 *lein-pkg" | sha1sum -c - \
  && mv lein-pkg $LEIN_INSTALL/lein \
  && chmod 0755 $LEIN_INSTALL/lein \
  && echo "Fetching lein standalone zip ..." \
  && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip \
  && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip.asc \
  && (gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-key "$LEIN_GPG_KEY" || \
      gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-key "$LEIN_GPG_KEY" || \
      gpg --keyserver hkp://pgp.mit.edu:80 --recv-key "$LEIN_GPG_KEY") \
  && echo "Verifying Jar file signature ..." \
  && gpg --verify leiningen-$LEIN_VERSION-standalone.zip.asc \
  && rm leiningen-$LEIN_VERSION-standalone.zip.asc \
  && mkdir -p /usr/share/java \
  && mv leiningen-$LEIN_VERSION-standalone.zip /usr/share/java/leiningen-$LEIN_VERSION-standalone.jar

ENV PATH=$PATH:$LEIN_INSTALL
ENV LEIN_ROOT 1

# Install clojure 1.9.0 so users don't have to download it every time
RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.9.0"]])' > project.clj \
  && lein deps && rm project.clj

#--- PhantomJS 
# Refer: https://hub.docker.com/r/fgrehm/phantomjs2/builds/bh7pii47dsynpsbhtwd38nk/
RUN curl -Ls https://github.com/arobson/docker-phantomjs2/releases/download/v2.1.1-20160523/dockerized-phantomjs.tar.gz | tar xz -C /
RUN ln -s /usr/local/bin/phantomjs /usr/bin/phantomjs

RUN node --version
#--- Typical Node Tools
RUN npm install --global --unsafe-perm \
	cljs \
	gulp-cli \
	lumo \
	wait-on

#--- Typical Ruby Tools
RUN gem install \
    bundler

#-- Typical Python Tools
RUN pip install --upgrade \
    awscli \
    awsebcli

RUN mvn --version
RUN pg_dump --version
RUN pg_restore --version
RUN phantomjs --version
RUN lumo --version
