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

# x86_64
ORT_PY37_x86_64_WHL_URL="${RELEASES_URL}/v1.12.1/onnxruntime_gpu-1.12.1-cp37-cp37m-manylinux_2_28_x86_64.whl"
ORT_PY38_x86_64_WHL_URL="${RELEASES_URL}/v1.12.1/onnxruntime_gpu-1.12.1-cp38-cp38-manylinux_2_28_x86_64.whl"
ORT_PY39_x86_64_WHL_URL="${RELEASES_URL}/v1.12.1/onnxruntime_gpu-1.12.1-cp39-cp39-manylinux_2_28_x86_64.whl"

# JP 4.5.1 (32.5.1)
ORT_PY36_AARCH64_JP_32_5_1_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp36-cp36m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY37_AARCH64_JP_32_5_1_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY38_AARCH64_JP_32_5_1_WHL_URL="${RELEASES_URL}/v1.8.2_JetPack4.5/onnxruntime_gpu_tensorrt-1.8.2-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"

# JP 4.6.0 (32.6.1)
ORT_PY36_AARCH64_JP_32_6_1_WHL_URL="${RELEASES_URL}/v1.10.0/onnxruntime_gpu-1.10.0-cp36-cp36m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY37_AARCH64_JP_32_6_1_WHL_URL="${RELEASES_URL}/v1.10.0/onnxruntime_gpu-1.10.0-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY38_AARCH64_JP_32_6_1_WHL_URL="${RELEASES_URL}/v1.10.0/onnxruntime_gpu-1.10.0-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"

# JP 4.6.1 (32.7.1)
ORT_PY36_AARCH64_JP_32_7_1_WHL_URL="${RELEASES_URL}/v1.10.0_JP461/onnxruntime_gpu-1.10.0-cp36-cp36m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY37_AARCH64_JP_32_7_1_WHL_URL="${RELEASES_URL}/v1.10.0_JP461/onnxruntime_gpu-1.10.0-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY38_AARCH64_JP_32_7_1_WHL_URL="${RELEASES_URL}/v1.10.0_JP461/onnxruntime_gpu-1.10.0-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"

# JP 4.6.2 (32.7.2)
ORT_PY36_AARCH64_JP_32_7_2_WHL_URL="$ORT_PY36_AARCH64_JP_32_7_1_WHL_URL"
ORT_PY37_AARCH64_JP_32_7_2_WHL_URL="$ORT_PY37_AARCH64_JP_32_7_1_WHL_URL"
ORT_PY38_AARCH64_JP_32_7_2_WHL_URL="$ORT_PY38_AARCH64_JP_32_7_1_WHL_URL"

# JP 5.0.2 (35.1.0)
ORT_PY38_AARCH64_JP_35_1_0_WHL_URL="${RELEASES_URL}/v1.12.1_JP35.1.0/onnxruntime_gpu-1.12.1-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ORT_PY39_AARCH64_JP_35_1_0_WHL_URL="${RELEASES_URL}/v1.12.1_JP35.1.0/onnxruntime_gpu-1.12.1-cp39-cp39-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
TRT_PY38_AARCH64_JP_35_1_0_WHL_URL="${RELEASES_URL}/v1.12.1_JP35.1.0/tensorrt-8.4.1.5-cp38-none-linux_aarch64.whl"
TRT_PY39_AARCH64_JP_35_1_0_WHL_URL="${RELEASES_URL}/v1.12.1_JP35.1.0/tensorrt-8.4.1.5-cp39-none-linux_aarch64.whl"

PIP_UPDATE_URL="https://bootstrap.pypa.io/pip/get-pip.py"
PIP_UPDATE_URL_36="https://bootstrap.pypa.io/pip/3.6/get-pip.py"

ONNXOPTIMIZER_PY36_AARCH64_WHL_URL="${RELEASES_URL}/v1.12.1_JP35.1.0/onnxoptimizer-0.3.1-cp36-cp36m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ONNXOPTIMIZER_PY37_AARCH64_WHL_URL="${RELEASES_URL}/v1.12.1_JP35.1.0/onnxoptimizer-0.3.1-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ONNXOPTIMIZER_PY38_AARCH64_WHL_URL="${RELEASES_URL}/v1.12.1_JP35.1.0/onnxoptimizer-0.3.1-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
ONNXOPTIMIZER_PY39_AARCH64_WHL_URL="${RELEASES_URL}/v1.12.1_JP35.1.0/onnxoptimizer-0.3.1-cp39-cp39-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"

arch="$(uname -m)"
python_version="$(python3 -c 'import platform; print(platform.python_version())')"


if [[ $arch == "x86_64" ]]; then

    if [[ $CHECK_DRIVER_VERSION == 1 && $DEVICE_TYPE == "GPU" ]]; then
        driver_version="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
        minimal_driver_version='510.39.01'

        if [[ $(ver "$driver_version") < $(ver "$minimal_driver_version") ]]; then
            printf "NVIDIA driver version should be %s or higher.\n" "$minimal_driver_version"
            printf "Current NVIDIA driver version %s. Abort.\n" "$driver_version"
            printf "Or use older versions of this script: commit 98bed531b7c408370febd88c106beac4ca0518d7."
            exit 1
        fi
    fi

    if ! [[ "$python_version" =~ 3\.[7-9]\.* ]]; then
        printf "Unsupported python version. Abort.\n"
        exit 1
    fi

    python3 -m pip install --upgrade pip
    python3 -m pip install wheel
    # Install OpenVINO without redundant dependecies.
    python3 -m pip install networkx~=2.5 defusedxml~=0.7.1 # OpenVINO mo minimal dependecies.
    python3 -m pip install --no-deps openvino==2022.1 openvino-dev==2022.1 'numpy<1.24.0'

    if [[ "$DEVICE_TYPE" == "GPU" ]]; then
        python3 -m pip install --no-deps --extra-index-url https://pypi.ngc.nvidia.com \
            nvidia-cuda-runtime-cu116==11.6.55 \
            nvidia-cudnn-cu116==8.4.0.27 \
            nvidia-cufft-cu116==10.7.2.124 \
            nvidia-curand-cu116==10.2.9.124 \
            nvidia-cublas-cu116==11.9.2.110 \
            nvidia-tensorrt==8.4.3.1
    fi

    if [[ $python_version == "3.7"* ]]; then
        python3 -m pip install --force-reinstall $ORT_PY37_x86_64_WHL_URL
    elif [[ $python_version == "3.8"* ]]; then
        python3 -m pip install --force-reinstall $ORT_PY38_x86_64_WHL_URL
    elif [[ $python_version == "3.9"* ]]; then
        python3 -m pip install --force-reinstall $ORT_PY39_x86_64_WHL_URL
    fi

    # Install additional dependecies.
    python3 -m pip install onnx six protobuf~=3.0 cuda-python~=11.6.0

elif [[ $arch == "aarch64" ]]; then

    declare -A supported_jetpacks=(
    	["35.1.0"]="JetPack 5.0.2" \
    	["32.7.2"]="JetPack 4.6.2" \
        ["32.7.1"]="JetPack 4.6.1" \
        ["32.6.1"]="JetPack 4.6.0" \
        ["32.5.1"]="JetPack 4.5.1" \
    )

    jetpack_release="$(cat /etc/nv_tegra_release | sed 's/.*R\([0-9][0-9]\).*/\1/')"
    jetpack_revision="$(cat /etc/nv_tegra_release | sed 's/.*REVISION: \([^,]*\).*/\1/')"
    jetpack_version="$jetpack_release.$jetpack_revision"

    if [[ -v "supported_jetpacks[$jetpack_version]" ]]; then
        printf "OS: ${supported_jetpacks[$jetpack_version]} ($jetpack_version)\n"
    else
        printf "Unsupported JetPack. Abort.\n"
        exit 1
    fi

    if [[ $jetpack_release == "35" ]]; then  # JetPack 5.x
        if ! [[ "$python_version" == "3.8"* ]]; then
            printf "Unsupported python version. Abort.\n"
            exit 1
        fi

        # Update pip to latest version.
        python3 -m pip install --upgrade pip

        if [[ $jetpack_revision == "1.0" ]]; then  # JP 5.0.2 (35.1.0)
            python3 -m pip install cuda-python~=11.6.0
            python3 -m pip install $ONNXOPTIMIZER_PY38_AARCH64_WHL_URL
            python3 -m pip install $TRT_PY38_AARCH64_JP_35_1_0_WHL_URL
            python3 -m pip install --force-reinstall $ORT_PY38_AARCH64_JP_35_1_0_WHL_URL
        else
            printf "Unsupported JetPack. Abort.\n"
            exit 1
        fi

        # Install additional dependecies.
        python3 -m pip install six protobuf~=3.0

    elif [[ $jetpack_release == "32" ]]; then  # JetPack 4.x
        if ! [[ "$python_version" == "3.6"* ]]; then
            printf "Unsupported python version. Abort.\n"
            exit 1
        fi

        # Update pip to latest version.
        wget -O - $PIP_UPDATE_URL_36 | python3

        # Install ONNX Optimizer.
        python3 -m pip install onnx~=1.11.0
        python3 -m pip install $ONNXOPTIMIZER_PY36_AARCH64_WHL_URL

        if [[ $jetpack_revision == "5.1" ]]; then  # JP 4.5.1 (32.5.1)
            python3 -m pip install --force-reinstall $ORT_PY36_AARCH64_JP_32_5_1_WHL_URL
        elif [[ $jetpack_revision == "6.1" ]]; then  # JP 4.6.0 (32.6.1)
            python3 -m pip install --force-reinstall $ORT_PY36_AARCH64_JP_32_6_1_WHL_URL
        elif [[ $jetpack_revision == "7.1" ]]; then  # JP 4.6.1 (32.7.1)
            python3 -m pip install --force-reinstall $ORT_PY36_AARCH64_JP_32_7_1_WHL_URL
        elif [[ $jetpack_revision == "7.2" ]]; then  # JP 4.6.2 (32.7.2)
            python3 -m pip install --force-reinstall $ORT_PY36_AARCH64_JP_32_7_2_WHL_URL
        else
            printf "Unsupported JetPack. Abort.\n"
            exit 1
        fi

        # Install additional dependecies.
        python3 -m pip install sympy packaging six protobuf~=3.0

        # Link nvidia-tensorrt package.
        site_packages_dir="$(python3 -c 'import site; print(site.getsitepackages()[0])')"
        if ! [[ "$site_packages_dir" == "/usr/local/lib/python3.6/dist-packages" ]]; then
            ln -sf /usr/lib/python3.6/dist-packages/tensorrt $site_packages_dir
        fi
    fi

else
    printf "Unsupported architecture. Abort.\n"
        exit 1
fi
