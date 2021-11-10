#!/usr/bin/env bash

MANYLINUX_IMAGE='quay.io/pypa/manylinux2014_x86_64'
PYTHON_TARGETS='cp37|cp38|cp39'
THREADS_NUM=16

docker pull "$MANYLINUX_IMAGE"
docker run -it --rm \
    --name onnx_runtime_build \
    -e PYTHON_TARGETS=$PYTHON_TARGETS \
    -e THREADS_NUM=$THREADS_NUM \
    -v $(pwd):/io \
    $MANYLINUX_IMAGE /io/build-onnx-runtime.sh
