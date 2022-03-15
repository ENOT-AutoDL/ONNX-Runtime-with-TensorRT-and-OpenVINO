#ifndef COMMON_CUDA_HELPER
#define COMMON_CUDA_HELPER

#include <cuda.h>
#include <cuda_fp16.h>

#define CUDA_1D_KERNEL_LOOP(i, n)                              \
  for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < (n); \
       i += blockDim.x * gridDim.x)

#define CUDA_2D_KERNEL_LOOP(i, n, j, m)                             \
  for (size_t i = blockIdx.x * blockDim.x + threadIdx.x; i < (n);   \
       i += blockDim.x * gridDim.x)                                 \
    for (size_t j = blockIdx.y * blockDim.y + threadIdx.y; j < (m); \
         j += blockDim.y * gridDim.y)

#define CUDA_2D_KERNEL_BLOCK_LOOP(i, n, j, m)          \
  for (size_t i = blockIdx.x; i < (n); i += gridDim.x) \
    for (size_t j = blockIdx.y; j < (m); j += gridDim.y)

#define THREADS_PER_BLOCK 512

inline int GET_BLOCKS(const int N, const int num_threads = THREADS_PER_BLOCK) {
  int optimal_block_num = (N + num_threads - 1) / num_threads;
  int max_block_num = 4096;
  return min(optimal_block_num, max_block_num);
}

template <typename T>
__device__ T bilinear_interpolate(
    const T* bottom_data,
    const int height,
    const int width,
    T y,
    T x,
    const bool is_mode_avg,
    const int index /* index for debug only*/) {
  // deal with cases that inverse elements are out of feature map boundary
  if (y < -1.0 || y > height || x < -1.0 || x > width) {
    // empty
    return 0;
  }

  if (y <= 0) {
    y = 0;
  }
  if (x <= 0) {
    x = 0;
  }

  int y_low = (int)y;
  int x_low = (int)x;
  int y_high;
  int x_high;

  if (y_low >= height - 1) {
    y_high = y_low = height - 1;
    y = (T)y_low;
  } else {
    y_high = y_low + 1;
  }

  if (x_low >= width - 1) {
    x_high = x_low = width - 1;
    x = (T)x_low;
  } else {
    x_high = x_low + 1;
  }

  T ly = y - y_low;
  T lx = x - x_low;
  T hy = 1. - ly, hx = 1. - lx;
  // do bilinear interpolation
  T v1 = bottom_data[y_low * width + x_low];
  T v2 = bottom_data[y_low * width + x_high];
  T v3 = bottom_data[y_high * width + x_low];
  T v4 = bottom_data[y_high * width + x_high];
  T w1 = hy * hx, w2 = hy * lx, w3 = ly * hx, w4 = ly * lx;

  T val = is_mode_avg
            ? (w1 * v1 + w2 * v2 + w3 * v3 + w4 * v4)  // mode Avg
            : max(max(max(w1 * v1, w2 * v2), w3 * v3), w4 * v4);  // mode Max

  return val;
}

template <typename T>
__device__ __inline__ T _Ceil(T a);

template <>
__device__ __inline__ float _Ceil(float a) { return ceilf(a); }

template <>
__device__ __inline__ double _Ceil(double a) { return ceil(a); }

template <>
__device__ __inline__ half _Ceil(half a) { return half(ceilf((float)a)); }

#endif  // COMMON_CUDA_HELPER
