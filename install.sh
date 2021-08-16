#!/usr/bin/env bash
set -e -u

ORT_PY37_WHL_URL="https://github.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/releases/download/v1.8.1/onnxruntime_gpu_tensorrt-1.8.1-cp37-cp37m-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
ORT_PY38_WHL_URL="https://github.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/releases/download/v1.8.1/onnxruntime_gpu_tensorrt-1.8.1-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"

ASSUME_YES=0 # Automatic yes to prompts.

while getopts ":y" opt; do
  case $opt in
    y) ASSUME_YES=1;;
    *) echo "got unknown option" && exit 1;;
  esac
done

function is_package_installed {
    package="$1"
    if [[ $(pip list --disable-pip-version-check) =~ $package ]]; then
        true
    else
        false
    fi
}

function check_package {
    package="$1"
    version="$2"
    if is_package_installed "$package"; then
        installed_version=$(pip show --disable-pip-version-check "$package" | grep "Version" | sed 's/Version: \(.*\)/\1/')
        if ! [[ "$installed_version" =~ $version ]]; then
            packages_to_update[$package]=$version
        fi
    else
        packages_to_install[$package]=$version
    fi
}

declare -A packages=(\
    ["numpy"]="1.19.*" \
    ["nvidia-pyindex"]="1.*" \
    ["nvidia-cudnn"]="8.2.*" \
    ["nvidia-tensorrt"]="7.2.*" \
    ["nvidia-curand"]="10.2.*" \
    ["nvidia-cufft"]="10.4.*" \
    ["openvino"]="2021.4" \
    ["onnxruntime-gpu-tensorrt"]="1.8.1" \
)
declare -A packages_to_install
declare -A packages_to_update

printf "Checking packages...\n"
for package in "${!packages[@]}"; do check_package "$package" "${packages[$package]}"; done
printf "Done\n"

if [[ -v packages_to_install[@] ]]; then
    printf "The following NEW packages will be installed:\n  "
    for x in "${!packages_to_install[@]}"; do printf "%s " "$x"; done
fi

if [[ -v packages_to_update[@] ]]; then
    printf "\nThe following packages will be updated:\n  "
    for x in "${!packages_to_update[@]}"; do printf "%s==%s " "$x" "${packages_to_update[$x]}"; done
fi

if ! [[ -v packages_to_install[@] ]] && ! [[ -v packages_to_update[@] ]]; then
    printf "All necessary packages are installed. Exit.\n"
    exit 0
fi

if [ $ASSUME_YES = 0 ]; then
    read -p $'\nDo you want to continue? [Y/n] ' -n 1 -r
    if [[ -z $REPLY ]]; then
      REPLY=y
    fi
else
    REPLY=y
fi

if [[ $REPLY =~ ^[Yy]$ ]]; then
    printf "\nInstalling packages...\n"
    python -m pip install -U pip
    pip install wheel

    # Install nvidia-pyindex.
    if [ -v packages_to_install["nvidia-pyindex"] ] || [ -v packages_to_update["nvidia-pyindex"] ]; then
        pip install "nvidia-pyindex==${packages["nvidia-pyindex"]}"
        unset packages_to_install["nvidia-pyindex"]
        unset packages_to_update["nvidia-pyindex"]
    fi

    if [ -v packages_to_install["onnxruntime-gpu-tensorrt"] ] || [ -v packages_to_update["onnxruntime-gpu-tensorrt"] ]; then
        python_version="$(python -c 'import platform; print(platform.python_version())')"
        if [[ $python_version == "3.7"* ]]; then
            pip install $ORT_PY37_WHL_URL
        elif [[ $python_version == "3.8"* ]]; then
            pip install $ORT_PY38_WHL_URL
        else
            printf "\nUnsupported python version. Abort.\n"
            exit 1
        fi

        unset packages_to_install["onnxruntime-gpu-tensorrt"]
        unset packages_to_update["onnxruntime-gpu-tensorrt"]
    fi

    # Update packages.
    for package in "${!packages_to_update[@]}"; do
        pip install "$package==${packages_to_update[$package]}"
    done

    # Install new packages.
    for package in "${!packages_to_install[@]}"; do
        pip install "$package==${packages_to_install[$package]}"
    done

    printf "Done.\n"
else
    printf "\nAbort.\n"
fi
