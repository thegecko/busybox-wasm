#!/bin/bash

SRC=$(dirname $0)

pushd $SRC/docker
docker build \
    -t busybox_build \
    .
popd

mkdir -p $(pwd)/build/emsdk_cache

docker run \
    -it --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd):$(pwd) \
    -v $(pwd)/build/emsdk_cache:/emsdk/upstream/emscripten/cache \
    -u $(id -u):$(id -g) \
    $(id -G | tr ' ' '\n' | xargs -I{} echo --group-add {}) \
    busybox_build:latest \
    bash -c "cd $(pwd) && ./build.sh"
