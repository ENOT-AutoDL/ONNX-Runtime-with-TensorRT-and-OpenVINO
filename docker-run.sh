#!/usr/bin/env bash

MANYLINUX_IMAGE='quay.io/pypa/manylinux_2_28_x86_64'
PYTHON_TARGETS='cp37|cp38|cp39'
THREADS_NUM=64

docker pull "$MANYLINUX_IMAGE"
docker run -it --rm \
    --name onnxruntime_build \
    -e PYTHON_TARGETS=$PYTHON_TARGETS \
    -e THREADS_NUM=$THREADS_NUM \
    -v $(pwd):/io \
    $MANYLINUX_IMAGE /io/build-onnx-runtime.sh
