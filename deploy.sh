#!/usr/bin/env bash
set -e
tag="${1:-latest}"
image="jesiio/build-bus:$tag"
echo "Building $image"
#FIXME squash layers
docker build \
	--pull \
	--platform linux/amd64 \
	--tag "$image" \
	.
echo "Deploying $image"
docker push "$image"
