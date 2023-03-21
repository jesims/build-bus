#!/usr/bin/env bash
set -e
tag="${1:-latest}"
image="jesiio/build-bus:$tag"
echo "Building $image"
docker build \
	--pull \
	--no-cache \
	--platform=x86_64 \
	--tag="$image" \
	.
echo "Deploying $image"
docker push "$image"
