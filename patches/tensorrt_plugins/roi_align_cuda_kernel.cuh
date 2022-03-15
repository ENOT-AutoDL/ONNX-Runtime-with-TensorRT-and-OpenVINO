#pragma once

#include "common_cuda_helper.h"

template <typename T>
__global__ void RoIAlignForward( const int nthreads
                               , const T* bottom_data
                               , const T spatial_scale
                               , const int channels
                               , const int height
                               , const int width
                               , const int pooled_height
                               , const int pooled_width
                               , const int sampling_ratio
                               , const T* bottom_rois
                               , int roi_cols
                               , T* top_data
                               , const bool is_mode_avg
                               , const int* batch_indices_ptr) {
  for (size_t index = blockIdx.x * blockDim.x + threadIdx.x; index < nthreads; index += blockDim.x * gridDim.x) {
    // (n, c, ph, pw) is an element in the pooled output
    int pw = index % pooled_width;
    int ph = (index / pooled_width) % pooled_height;
    int c  = (index / pooled_width / pooled_height) % channels;
    int n  = index / pooled_width / pooled_height / channels;

    // RoI could have 4 or 5 columns
    const T* offset_bottom_rois = bottom_rois + n * roi_cols;
    const auto roi_batch_ind = batch_indices_ptr[n];

    bool continuous_coordinate = false;
    // Do not using rounding; this implementation detail is critical
    T roi_offset = continuous_coordinate ? T(0.5) : T(0);
    T roi_start_w = offset_bottom_rois[0] * spatial_scale - roi_offset;
    T roi_start_h = offset_bottom_rois[1] * spatial_scale - roi_offset;
    T roi_end_w   = offset_bottom_rois[2] * spatial_scale - roi_offset;
    T roi_end_h   = offset_bottom_rois[3] * spatial_scale - roi_offset;

    T roi_width  = roi_end_w - roi_start_w;
    T roi_height = roi_end_h - roi_start_h;
    if (!continuous_coordinate) { // backward compatiblity
      // Force malformed ROIs to be 1x1
      roi_width  = max(roi_width,  (T)1.);
      roi_height = max(roi_height, (T)1.);
    }
    T bin_size_h = static_cast<T>(roi_height) / static_cast<T>(pooled_height);
    T bin_size_w = static_cast<T>(roi_width)  / static_cast<T>(pooled_width);

    const T* offset_bottom_data = bottom_data + static_cast<int64_t>((roi_batch_ind * channels + c) * height * width);

    // We use roi_bin_grid to sample the grid and mimic integral
    int roi_bin_grid_h = (sampling_ratio > 0) ? sampling_ratio : _Ceil(roi_height / pooled_height); // e.g., = 2
    int roi_bin_grid_w = (sampling_ratio > 0) ? sampling_ratio : _Ceil(roi_width  / pooled_width);

    // We do average (integral) pooling inside a bin
    const T count = roi_bin_grid_h * roi_bin_grid_w; // e.g. = 4

    T output_val = 0.;
    bool max_flag = false;
    for (int iy = 0; iy < roi_bin_grid_h; iy++) { // e.g., iy = 0, 1
      const T y = roi_start_h + ph * bin_size_h + static_cast<T>(iy + .5f) * bin_size_h / static_cast<T>(roi_bin_grid_h); // e.g., 0.5, 1.5
      for (int ix = 0; ix < roi_bin_grid_w; ix++) {
        const T x = roi_start_w + pw * bin_size_w + static_cast<T>(ix + .5f) * bin_size_w / static_cast<T>(roi_bin_grid_w);

        T val = bilinear_interpolate(offset_bottom_data, height, width, y, x, is_mode_avg, index);

        if (is_mode_avg) {
          output_val += val;
        } else {
          if (not max_flag) {
            output_val = val;
            max_flag = true;
          } else {
            output_val = max(output_val, val);
          }
        }
      }
    }
    if (is_mode_avg) {
      output_val /= count;
    }

    top_data[index] = output_val;
  }
}
