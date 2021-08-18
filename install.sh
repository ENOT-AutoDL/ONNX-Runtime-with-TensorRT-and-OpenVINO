#!/usr/bin/env bash
set -e -u

function ver { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

ORT_PY37_WHL_URL="https://github.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/releases/download/v1.8.1_with_embedded_deps/onnxruntime_gpu_tensorrt-1.8.1-cp37-cp37m-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_PY38_WHL_URL="https://github.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/releases/download/v1.8.1_with_embedded_deps/onnxruntime_gpu_tensorrt-1.8.1-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"

driver_version="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
minimal_driver_version='460.27.04'

if [[ $(ver "$driver_version") < $(ver "$minimal_driver_version") ]]; then
    printf "NVIDIA driver version should be %s or higher.\n" "$minimal_driver_version"
    printf "Current NVIDIA driver version %s. Abort.\n" "$driver_version"
    exit 1
fi

python_version="$(python -c 'import platform; print(platform.python_version())')"
if ! [[ "$python_version" =~ 3\.[7-8]\.* ]]; then
    printf "Unsupported python version. Abort.\n"
    exit 1
fi

python -m pip install -U pip
pip install wheel

if [[ $python_version == "3.7"* ]]; then
    pip install $ORT_PY37_WHL_URL --extra-index-url https://pypi.ngc.nvidia.com
elif [[ $python_version == "3.8"* ]]; then
    pip install $ORT_PY38_WHL_URL --extra-index-url https://pypi.ngc.nvidia.com
fi
