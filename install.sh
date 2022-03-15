#!/usr/bin/env bash
set -e -u

CHECK_DRIVER_VERSION=1
DEVICE_TYPE="GPU"

function display_help {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -t <DEVICE>        Select device type: GPU or CPU, default value is GPU"
    echo "                      Use CPU if target device only has CPU (GPU includes CPU)"
    echo "   -d                 Disable driver version checking (useful for docker container building)"
}

while getopts "h?dt:" opt; do
  case "$opt" in
    d) CHECK_DRIVER_VERSION=0;;
    t)
        DEVICE_TYPE=$OPTARG;
        if ! [[ "$DEVICE_TYPE" =~ ^CPU$|^GPU$ ]]; then
            display_help
            exit 1
        fi
        ;;
    h|\?)
        display_help
        exit 0
        ;;
  esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

function ver { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); }

REPO_URL="https://github.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO"
RELEASES_URL="${REPO_URL}/releases/download"
REPO_RAW_URL="https://raw.githubusercontent.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO"
MASTER_URL="${REPO_RAW_URL}/master"
ORT_GPU_PY37_WHL_URL="${RELEASES_URL}/v1.10.0/onnxruntime_gpu-1.10.0-cp37-cp37m-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_GPU_PY38_WHL_URL="${RELEASES_URL}/v1.10.0/onnxruntime_gpu-1.10.0-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_GPU_PY39_WHL_URL="${RELEASES_URL}/v1.10.0/onnxruntime_gpu-1.10.0-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_CPU_PY37_WHL_URL="${RELEASES_URL}/v1.9.1/onnxruntime_openvino-1.9.1-cp37-cp37m-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_CPU_PY38_WHL_URL="${RELEASES_URL}/v1.9.1/onnxruntime_openvino-1.9.1-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_CPU_PY39_WHL_URL="${RELEASES_URL}/v1.9.1/onnxruntime_openvino-1.9.1-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_PY36_AARCH64_JP46_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.6/onnxruntime_gpu_tensorrt-1.8.2-cp36-cp36m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY37_AARCH64_JP46_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.6/onnxruntime_gpu_tensorrt-1.8.2-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY38_AARCH64_JP46_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.6/onnxruntime_gpu_tensorrt-1.8.2-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY36_AARCH64_JP45_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp36-cp36m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY37_AARCH64_JP45_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY38_AARCH64_JP45_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
MO_QDQ_PATCH_URL="${MASTER_URL}/patches/mo_quantize_dequantize_linear.patch"
MO_LOADER_PATCH_URL="${MASTER_URL}/patches/mo_loader.patch"

if [[ "$DEVICE_TYPE" == "GPU" ]]; then
    ORT_PY37_WHL_URL=$ORT_GPU_PY37_WHL_URL
    ORT_PY38_WHL_URL=$ORT_GPU_PY38_WHL_URL
    ORT_PY39_WHL_URL=$ORT_GPU_PY39_WHL_URL
else
    ORT_PY37_WHL_URL=$ORT_CPU_PY37_WHL_URL
    ORT_PY38_WHL_URL=$ORT_CPU_PY38_WHL_URL
    ORT_PY39_WHL_URL=$ORT_CPU_PY39_WHL_URL
fi

arch="$(uname -m)"
python_version="$(python -c 'import platform; print(platform.python_version())')"

if ! [[ -x "$(command -v patch)" ]]; then
    printf "patch command is not installed, install it before running this script (ubuntu: apt install patch). Abort.\n"
    exit 1
fi

if [[ $arch == "x86_64" ]]; then

    if [[ $CHECK_DRIVER_VERSION == 1 && $DEVICE_TYPE == "GPU" ]]; then
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

    mo_path=$(python -c 'import mo; import pathlib; print(pathlib.Path(mo.__path__[0]).parent.absolute())')
    wget -O - "$MO_QDQ_PATCH_URL" | patch "${mo_path}/extensions/front/onnx/quantize_dequantize_linear.py"
    wget -O - "$MO_LOADER_PATCH_URL" | patch "${mo_path}/extensions/load/onnx/loader.py"

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
