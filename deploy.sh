#!/usr/bin/env bash
docker build . -t jesiio/build-bus:latest --no-cache \
	&& docker push jesiio/build-bus:latest
