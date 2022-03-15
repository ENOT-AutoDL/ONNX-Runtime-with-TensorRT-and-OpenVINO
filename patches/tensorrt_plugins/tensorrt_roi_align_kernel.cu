#include "common_cuda_helper.h"
#include "roi_align_cuda_kernel.cuh"

template <typename scalar_t>
void RoIAlignForwardCUDAKernelLauncher( const scalar_t* bottom_data
                                      , const scalar_t spatial_scale
                                      , const int output_size
                                      , const int channels
                                      , const int height
                                      , const int width
                                      , const int pooled_height
                                      , const int pooled_width
                                      , const int sampling_ratio
                                      , const scalar_t* bottom_rois
                                      , const int roi_cols
                                      , scalar_t* top_data
                                      , const int is_mode_avg
                                      , const int* batch_indices_ptr
                                      , cudaStream_t stream) {
  RoIAlignForward<scalar_t>
      <<<GET_BLOCKS(output_size), THREADS_PER_BLOCK, 0, stream>>>( output_size // nthreads
                                                                 , bottom_data // bottom_data
                                                                 , spatial_scale // spatial_scale
                                                                 , channels // channels
                                                                 , height // height
                                                                 , width // width
                                                                 , pooled_height // pooled_height
                                                                 , pooled_width // pooled_width
                                                                 , sampling_ratio // sampling_ratio
                                                                 , bottom_rois // bottom_rois
                                                                 , roi_cols // roi_cols
                                                                 , top_data // top_data
                                                                 , is_mode_avg // is_mode_avg
                                                                 , batch_indices_ptr); // batch_indices_ptr
}

void RoIAlignForwardCUDAKernelLauncher_float( const float* bottom_data
                                            , const float spatial_scale
                                            , const int output_size
                                            , const int channels
                                            , const int height
                                            , const int width
                                            , const int pooled_height
                                            , const int pooled_width
                                            , const int sampling_ratio
                                            , const float* bottom_rois
                                            , const int roi_cols
                                            , float* top_data
                                            , const int is_mode_avg
                                            , const int* batch_indices_ptr
                                            , cudaStream_t stream) {
  RoIAlignForwardCUDAKernelLauncher<float>( bottom_data // bottom_data
                                          , spatial_scale // spatial_scale
                                          , output_size // output_size
                                          , channels // channels
                                          , height // height
                                          , width // width
                                          , pooled_height // pooled_height
                                          , pooled_width // pooled_width
                                          , sampling_ratio // sampling_ratio
                                          , bottom_rois // bottom_rois
                                          , roi_cols // roi_cols
                                          , top_data // top_data
                                          , is_mode_avg // is_mode_avg
                                          , batch_indices_ptr // batch_indices_ptr
                                          , stream); // streaam
}
