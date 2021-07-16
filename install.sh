#!/usr/bin/env bash
set -e -u

ASSUME_YES=0 # Automatic yes to prompts.

while getopts “:y” opt; do
  case $opt in
    y) ASSUME_YES=1;;
  esac
done

function is_package_has_version {
    package="$1"
    version="$2"
    installed_version=$(pip show --disable-pip-version-check $package | grep "Version" | sed 's/Version: \(.*\)/\1/')
    if ! [[ $installed_version == "$version"* ]]; then
        packages_to_update[$package]=$version
    fi
}

function is_package_installed {
    package="$1"
    if ! [[ -z $(pip list --disable-pip-version-check | grep "$package") ]]; then
        return 0
    else
        return 1
    fi
}

function check_package {
    package="$1"
    version="$2"
    if is_package_installed $package; then
        is_package_has_version $package $version
    else
        packages_to_install[$package]=$version
    fi
}

declare -A packages=(\
    ["numpy"]="1.19" \
    ["nvidia-pyindex"]="1.0" \
    ["nvidia-cudnn"]="8.2.0" \
    ["nvidia-tensorrt"]="7.2.3" \
    ["nvidia-curand"]="10.2.4" \
    ["nvidia-cufft"]="10.4.2" \
    ["openvino"]="2021.4" \
    ["onnxruntime-gpu-tensorrt"]="1.8.1" \
)
declare -A packages_to_install
declare -A packages_to_update

printf "Checking packages... "
for package in "${!packages[@]}"; do check_package "$package" "${packages[$package]}"; done
printf "Done\n"

if [ -v packages_to_install[@] ]; then
    printf "The following NEW packages will be installed:\n  "
    for x in "${!packages_to_install[@]}"; do printf "%s " "$x"; done
fi

if [ -v packages_to_update[@] ]; then
    printf "\nThe following packages will be updated:\n  "
    for x in "${!packages_to_update[@]}"; do printf "%s==%s " "$x" "${packages_to_update[$x]}"; done
fi

if ! [ -v packages_to_install[@] ] && ! [ -v packages_to_update[@] ]; then
    printf "All necessary packages are installed. Exit.\n"
    exit 0
fi

if [ $ASSUME_YES = 0 ]; then
    echo
    read -p "Do you want to continue? [Y/n] " -n 1 -r
else
    REPLY=y
fi

if [[ $REPLY =~ ^[Yy]$ ]]; then
    printf "\nInstalling packages...\n"
    python -m pip install -U pip
    pip install wheel

    # Install nvidia-pyindex.
    if [ -v packages_to_install["nvidia-pyindex"] ] || [ -v packages_to_update["nvidia-pyindex"] ]; then
        pip install "nvidia-pyindex~=${packages["nvidia-pyindex"]}"
        unset packages_to_install["nvidia-pyindex"]
        unset packages_to_update["nvidia-pyindex"]
    fi

    if [ -v packages_to_install["onnxruntime-gpu-tensorrt"] ] || [ -v packages_to_update["onnxruntime-gpu-tensorrt"] ]; then
        install_onnxruntime=1
        unset packages_to_install["onnxruntime-gpu-tensorrt"]
        unset packages_to_update["onnxruntime-gpu-tensorrt"]
    fi

    # Update packages.
    for package in "${!packages_to_update[@]}"; do
        pip install "$package~=${packages_to_update[$package]}"
    done

    # Install new packages.
    for package in "${!packages_to_install[@]}"; do
        pip install "$package~=${packages_to_install[$package]}"
    done

    # @TODO: Install ONNX Runtime package from Github.
    if [ -v install_onnxruntime ]; then
        pip install "onnxruntime_gpu_tensorrt-${packages["onnxruntime-gpu-tensorrt"]}"
    fi

    printf "Done.\n"
    exit 0
else
    printf "\nAbort.\n"
    exit 0
fi
