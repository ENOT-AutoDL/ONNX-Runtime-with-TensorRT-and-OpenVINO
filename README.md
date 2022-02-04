# ONNX Runtime with TensorRT and OpenVINO

Docker scripts for building [ONNX Runtime](https://github.com/microsoft/onnxruntime) with [TensorRT](https://github.com/NVIDIA/TensorRT) and [OpenVINO](https://github.com/openvinotoolkit/openvino) in manylinux environment.

Supports `x86_64` and `aarch64 (JetPack)` architectures.

## Build requirements

 - [CUDA 11.4](https://developer.nvidia.com/cuda-downloads) (and CUDA 11.1 for tests)
 - [cuDNN 8.2](https://developer.nvidia.com/cudnn-download-survey)
 - [TensorRT 8.0](https://developer.nvidia.com/nvidia-tensorrt-download)

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

There are two types of builds: `GPU` and `CPU`, if your target device has only `CPU`, then you should use `CPU` version.

Wheels compiled for `x86_64` architecture depend on the following packages from NVIDIA repository:
 - `nvidia-cudnn (8.2)`
 - `nvidia-tensorrt (8.0)`
 - `nvidia-curand (10.2)`
 - `nvidia-cufft (10.4)`

and `openvino (2021.4)` from standard PyPI repository.\
To automatically install these dependencies add `--extra-index-url https://pypi.ngc.nvidia.com` to `pip install` command:
```
pip install onnxruntime-*.whl --extra-index-url https://pypi.ngc.nvidia.com
```

Also you can use `install.sh` script to install `GPU` version:
```
wget -O - https://raw.githubusercontent.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/master/install.sh | bash
```
or:
```
wget -O - https://raw.githubusercontent.com/ENOT-AutoDL/ONNX-Runtime-with-TensorRT-and-OpenVINO/master/install.sh | bash -s -- -t CPU
```
to install `CPU`-only version.

which installs `ONNX Runtime` with all dependencies automatically.
