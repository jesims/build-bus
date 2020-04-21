#!/usr/bin/env bash
#FIXME restore to 'latest'
tag='java-14'
image="jesiio/build-bus:$tag"
docker build . -t $image --no-cache && docker push $image
