#!/usr/bin/env bash
set -e
tag="${1:-latest}"
image="jesiio/build-bus:$tag"
echo "Building $image"
docker build . -t $image --no-cache
echo "Deploying $image"
docker push $image
