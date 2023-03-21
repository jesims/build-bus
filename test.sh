#!/usr/bin/env bash
image='jesiio/build-bus:test'
docker build \
	--platform=x86_64 \
	--tag=$image \
	.
