#!/usr/bin/env bash
set -e -u

CHECK_DRIVER_VERSION=1

while getopts ":d" opt; do
  case $opt in
    d) CHECK_DRIVER_VERSION=0;;
    *) echo "got unknown option" && exit 1;;
  esac
done

function ver { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

BASE_URL="https://github.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/releases/download"
ORT_PY37_WHL_URL="${BASE_URL}/v1.9.1/onnxruntime_gpu_tensorrt-1.9.1-cp37-cp37m-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_PY38_WHL_URL="${BASE_URL}/v1.9.1/onnxruntime_gpu_tensorrt-1.9.1-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_PY39_WHL_URL="${BASE_URL}/v1.9.1/onnxruntime_gpu_tensorrt-1.9.1-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_PY36_AARCH64_JP46_WHL_URL="${BASE_URL}/v1.8.2_JetPack4.6/onnxruntime_gpu_tensorrt-1.8.2-cp36-cp36m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY37_AARCH64_JP46_WHL_URL="${BASE_URL}/v1.8.2_JetPack4.6/onnxruntime_gpu_tensorrt-1.8.2-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY38_AARCH64_JP46_WHL_URL="${BASE_URL}/v1.8.2_JetPack4.6/onnxruntime_gpu_tensorrt-1.8.2-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY36_AARCH64_JP45_WHL_URL="${BASE_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp36-cp36m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY37_AARCH64_JP45_WHL_URL="${BASE_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY38_AARCH64_JP45_WHL_URL="${BASE_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"

arch="$(uname -m)"
python_version="$(python -c 'import platform; print(platform.python_version())')"

if [[ $arch == "x86_64" ]]; then

    if [[ $CHECK_DRIVER_VERSION == 1 ]]; then
        driver_version="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
        minimal_driver_version='460.27.04'

        if [[ $(ver "$driver_version") < $(ver "$minimal_driver_version") ]]; then
            printf "NVIDIA driver version should be %s or higher.\n" "$minimal_driver_version"
            printf "Current NVIDIA driver version %s. Abort.\n" "$driver_version"
            exit 1
        fi
    fi

    if ! [[ "$python_version" =~ 3\.[7-9]\.* ]]; then
        printf "Unsupported python version. Abort.\n"
        exit 1
    fi

    python -m pip install -U pip
    pip install wheel
    pip install onnxruntime # Hack, will be removed in the future.

    if [[ $python_version == "3.7"* ]]; then
        pip install -U --force $ORT_PY37_WHL_URL --extra-index-url https://pypi.ngc.nvidia.com
    elif [[ $python_version == "3.8"* ]]; then
        pip install -U --force $ORT_PY38_WHL_URL --extra-index-url https://pypi.ngc.nvidia.com
    elif [[ $python_version == "3.9"* ]]; then
        pip install -U --force $ORT_PY39_WHL_URL --extra-index-url https://pypi.ngc.nvidia.com
    fi

elif [[ $arch == "aarch64" ]]; then

    declare -A supported_jetpacks=(["6.1"]="JetPack 4.6" ["5.1"]="JetPack 4.5")
    latest_jetpack="6.1"
    jetpack_revision="$(cat /etc/nv_tegra_release | sed 's/.*REVISION: \([^,]*\).*/\1/')"

    if ! [[ "$python_version" =~ 3\.[6-8]\.* ]]; then
        printf "Unsupported python version. Abort.\n"
        exit 1
    fi

    python -m pip install -U pip

    if [[ $jetpack_revision == "6.1" ]]; then
        if [[ $python_version == "3.6"* ]]; then
            pip install $ORT_PY36_AARCH64_JP46_WHL_URL
	elif [[ $python_version == "3.7"* ]]; then
            pip install $ORT_PY37_AARCH64_JP46_WHL_URL
	elif [[ $python_version == "3.8"* ]]; then
            pip install $ORT_PY38_AARCH64_JP46_WHL_URL
	fi
    elif [[ $jetpack_revision == "5.1" ]]; then
        if [[ $python_version == "3.6"* ]]; then
            pip install $ORT_PY36_AARCH64_JP45_WHL_URL
	elif [[ $python_version == "3.7"* ]]; then
            pip install $ORT_PY37_AARCH64_JP45_WHL_URL
	elif [[ $python_version == "3.8"* ]]; then
            pip install $ORT_PY38_AARCH64_JP45_WHL_URL
	fi
        printf "Please update installed ${supported_jetpacks[$jetpack_revision]} to ${supported_jetpacks[$latest_jetpack]}.\n"
    else
        printf "Unsupported JetPack. Abort.\n"
        exit 1
    fi

else
    printf "Unsupported architecture. Abort.\n"
        exit 1
fi
