# ONNX Runtime with TensorRT and OpenVINO

Docker scripts for building [ONNX Runtime](https://github.com/microsoft/onnxruntime) with [TensorRT](https://github.com/NVIDIA/TensorRT) and [OpenVINO](https://github.com/openvinotoolkit/openvino) in manylinux environment.

Supports `x86_64` and `aarch64 (JetPack)` architectures.

## Build requirements

 - [CUDA 11.6](https://developer.nvidia.com/cuda-downloads) (and CUDA 11.1 for tests)
 - [cuDNN 8.4](https://developer.nvidia.com/cudnn-download-survey)
 - [TensorRT 8.4](https://developer.nvidia.com/nvidia-tensorrt-download)

Place CUDA (`.run`), cuDNN (`tar.gz`) and TensorRT (`tar.gz`) files into `distrib` folder.

## Building

Simply type the following command in your terminal and press `Enter`:
```
bash docker-run.sh
```

Wheels will be placed into `wheelhouse` folder.

## Customization

 - To specify `Python` versions for which wheels will be built, edit `PYTHON_TARGETS` variable in `docker-run.sh`
 - To change number of parallel threads edit `THREADS_NUM` variable in `docker-run.sh`

## Using

Wheels compiled for `x86_64` architecture depend on the following packages from NVIDIA repository:
 - `nvidia-cuda-runtime-cu116 (11.6)`
 - `nvidia-cublas-cu116 (11.9)`
 - `nvidia-cudnn-cu116 (8.4)`
 - `nvidia-cufft-cu116 (10.7)`
 - `nvidia-curand-cu116 (10.2)`
 - `nvidia-tensorrt (8.4)`

and `openvino (2022.1)` from standard PyPI repository.\
Compiled wheels do not explicitly depend on NVIDIA packages, you can install them by the following commands:
```
pip install --no-deps --extra-index-url https://pypi.ngc.nvidia.com \
    nvidia-cuda-runtime-cu116==11.6.55 \
    nvidia-cudnn-cu116==8.4.0.27 \
    nvidia-cufft-cu116==10.7.2.124 \
    nvidia-curand-cu116==10.2.9.124 \
    nvidia-cublas-cu116==11.9.2.110 \
    nvidia-tensorrt==8.4.3.1

pip install openvino==2022.1 openvino-dev==2022.1
```

The **recommended way** to install this ONNX Runtime package is to use our `install.sh` script,
which installs ONNX Runtime with all dependencies automatically.

Install `GPU` version (with all NVIDIA dependencies):
```
wget -O - https://raw.githubusercontent.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/master/install.sh | bash
```
Install `CPU`-only version (without NVIDIA packages, use this version if your target device has no `GPU`):
```
wget -O - https://raw.githubusercontent.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/master/install.sh | bash -s -- -t CPU
```
