#!/usr/bin/env bash
tag=jesiio/build-bus:test
docker build . -t ${tag}
if [ $? -ne 0 ];then
	docker build --no-cache . -t ${tag}
fi
