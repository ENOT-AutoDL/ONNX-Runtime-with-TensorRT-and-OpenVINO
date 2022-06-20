#!/usr/bin/env bash
set -e -u -x

DISTRIB_DIR=/io/distrib
BUILD_DIR=/io/build
WHEELHOUSE_DIR=/io/wheelhouse
CUDA_DIR=/io/devtools/cuda
CUDA_11_1_DIR=/io/devtools/cuda-11_1
TENSOR_RT_DIR=/io/devtools/tensorrt
ONNX_RUNTIME_DIR=/io/onnxruntime
ORT_TRT_SUBMODULE_DIR=$ONNX_RUNTIME_DIR/cmake/external/onnx-tensorrt
ORT_PROTOBUF_SUBMODULE_DIR=$ONNX_RUNTIME_DIR/cmake/external/protobuf
PATCHES_DIR=/io/patches

# Unpack CUDA toolkit and add executables to PATH.
bash $DISTRIB_DIR/cuda_11.4.4_470.82.01_linux.run --silent --toolkit --toolkitpath=$CUDA_DIR
export PATH=$CUDA_DIR/bin:$PATH

# Install CUDA 11.1 toolkit (for tests only).
# From https://docs.nvidia.com/deeplearning/tensorrt/release-notes/tensorrt-7.html:
# If you are developing an application that is being compiled with CUDA 11.2 or you are using CUDA 11.2 libraries
# to run your application, then you must install CUDA 11.1.
# NVRTC from CUDA 11.1 is a runtime requirement of TensorRT and must be present to run TensorRT applications.
#bash $DISTRIB_DIR/cuda_11.1.1_455.32.00_linux.run --silent --toolkit --toolkitpath=$CUDA_11_1_DIR
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_DIR/lib64:$CUDA_11_1_DIR/lib64

# Unpack cuDNN headers and libs.
tar -zxvf /io/distrib/cudnn-11.4-linux-x64-v8.2.4.15.tgz -C $CUDA_DIR/include cuda/include --strip-component=2
tar -zxvf /io/distrib/cudnn-11.4-linux-x64-v8.2.4.15.tgz -C $CUDA_DIR/lib64 cuda/lib64 --strip-component=2

# Unpack TensorRT.
mkdir -p $TENSOR_RT_DIR
tar -zxvf $DISTRIB_DIR/TensorRT-8.4.1.5.Linux.x86_64-gnu.cuda-11.6.cudnn8.4.tar.gz -C $TENSOR_RT_DIR --strip-component=1

# Install OpenVINO.
yum install yum-utils
yum-config-manager --add-repo https://yum.repos.intel.com/openvino/2021/setup/intel-openvino-2021.repo
rpm --import https://yum.repos.intel.com/openvino/2021/setup/RPM-GPG-KEY-INTEL-OPENVINO-2021
yum -y install intel-openvino-runtime-centos7

# Remove libinference_engine.so dependency from libinference_engine_c_api.
# We don't want to pack all OpenVINO libraries to wheel, because all libraries except libinference_engine_c_api.so
# can be installed from OpenVINO PyPI package.
patchelf --remove-needed libinference_engine.so /opt/intel/openvino_2021/inference_engine/lib/intel64/libinference_engine_c_api.so

# Clone ONNX Runtime.
git clone --depth 1 --recursive --branch v1.11.1 https://github.com/microsoft/onnxruntime $ONNX_RUNTIME_DIR

git --git-dir $ORT_TRT_SUBMODULE_DIR/.git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git --git-dir $ORT_TRT_SUBMODULE_DIR/.git fetch --all
git --git-dir $ORT_TRT_SUBMODULE_DIR/.git checkout 8.4-GA

# Apply patches to ONNX Runtime.
patch $ONNX_RUNTIME_DIR/setup.py $PATCHES_DIR/setup.patch
cp $PATCHES_DIR/_libs_loader.py $ONNX_RUNTIME_DIR/onnxruntime/python/
patch $ONNX_RUNTIME_DIR/onnxruntime/core/providers/tensorrt/tensorrt_execution_provider.cc $PATCHES_DIR/tensorrt_execution_provider_dim_fix.patch
patch $ONNX_RUNTIME_DIR/onnxruntime/core/optimizer/constant_folding.cc $PATCHES_DIR/disable_qdq_constant_folding.patch
patch -d $ONNX_RUNTIME_DIR -p1 < $PATCHES_DIR/openvino_execution_provider_native_support.patch
cp -r $PATCHES_DIR/tensorrt_plugins $ONNX_RUNTIME_DIR/onnxruntime/core/providers/tensorrt/plugins
patch -d $ONNX_RUNTIME_DIR -p1 < $PATCHES_DIR/tensorrt_plugins.patch
patch $ONNX_RUNTIME_DIR/cmake/external/onnx-tensorrt/ModelImporter.cpp $PATCHES_DIR/onnx-tensorrt.patch

# Create directory for wheels.
mkdir -p $WHEELHOUSE_DIR

# Save PATH, because we will add different versions of Python to PATH.
PATH_ORIG=$PATH

PYBINS=$(find /opt/python/*/bin -regextype gnu-awk -regex ".*/($PYTHON_TARGETS)-.*/bin$")
for PYBIN in ${PYBINS[@]}; do

    # Add Python with specified version to path.
    export PATH=$PYBIN:$PATH_ORIG

    # Initialize OpenVINO environment.
    set +u # Ignore errors if an variable is referenced before being set.
    source /opt/intel/openvino_2021/bin/setupvars.sh
    set -u

    # Install dependencies.
    $PYBIN/pip install wheel flake8 numpy==1.19.5 flatbuffers

    # Directory for current build.
    mkdir -p $BUILD_DIR

    # Build ONNX Runtime.
    bash $ONNX_RUNTIME_DIR/build.sh \
        --cudnn_home $CUDA_DIR/lib64 \
        --cuda_home $CUDA_DIR \
        --cuda_version 11.4 \
        --use_tensorrt \
        --tensorrt_home $TENSOR_RT_DIR \
        --use_openvino \
        --parallel $THREADS_NUM \
        --build_wheel \
        --enable_pybind \
        --config RelWithDebInfo \
        --build_dir $BUILD_DIR \
        --skip_tests \
        --skip_submodule_sync \
        --cmake_extra_defines PYTHON_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
        --cmake_extra_defines PYTHON_LIBRARY=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
        --cmake_extra_defines CUDA_TOOLKIT_ROOT_DIR=$CUDA_DIR

    # Save wheels to wheelhouse.
    cp $BUILD_DIR/RelWithDebInfo/dist/* $WHEELHOUSE_DIR

    rm -rf $BUILD_DIR
done

# Clean up directories.
rm -rf $CUDA_DIR
rm -rf $CUDA_11_1_DIR
rm -rf $TENSOR_RT_DIR
rm -rf $ONNX_RUNTIME_DIR
