# ONNX Runtime with TensorRT and OpenVINO

Docker scripts for building [ONNX Runtime](https://github.com/microsoft/onnxruntime) with [TensorRT](https://github.com/NVIDIA/TensorRT) and [OpenVINO](https://github.com/openvinotoolkit/openvino) in manylinux environment.

## Requirements

 - [CUDA 11.2](https://developer.nvidia.com/cuda-downloads) (and CUDA 11.1 for tests)
 - [cuDNN 8.2.1](https://developer.nvidia.com/cudnn-download-survey)
 - [TensorRT 7.2.3.4](https://developer.nvidia.com/nvidia-tensorrt-download)

Place CUDA (`.run`), cuDNN (`tar.gz`) and TensorRT (`tar.gz`) files into `distrib` folder.

## Building

Simply type the following command in your terminal and press `Enter`:
```
bash docker-run.sh
```

Wheels will be placed into `wheelhouse` folder.

## Customization

 - To specify `Python` versions for which wheels will be built edit `PYTHON_TARGETS` variable in `docker-run.sh`
 - To change number of parallel threads edit `THREADS_NUM` variable in `docker-run.sh`

## Using

After installation of compiled wheel you have to install the following packages from `nvidia-pyindex` repository:
 - `nvidia-cudnn (8.2.0)`
 - `nvidia-tensorrt (7.2.3)`
 - `nvidia-curand (10.2.4)`
 - `nvidia-cufft (10.4.2)`

and `openvino (2021.4)` from standard PyPI repository.\
Then populate `LD_LIBRARY_PATH` variable with `lib` folders of these packages or load them dynamically.

Also you can use `install.sh` script, which installs `ONNX Runtime` with necessary libraries automatically (but you need to patch `LD_LIBRARY_PATH` or load libraries manually).
