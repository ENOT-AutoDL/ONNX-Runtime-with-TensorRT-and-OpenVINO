#include "tensorrt_roi_align.h"

#include <assert.h>
#include <stdio.h>

#include <chrono>

#include "tensorrt_serialize.h"

extern void RoIAlignForwardCUDAKernelLauncher_float( const float* bottom_data
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
                                                   , cudaStream_t stream);

namespace {
  static const char* PLUGIN_VERSION{"1"};
  static const char* PLUGIN_NAME{"RoiAlign"};
}

nvinfer1::PluginFieldCollection RoiAlignDynamicCreator::mFC{};
std::vector<nvinfer1::PluginField> RoiAlignDynamicCreator::mPluginAttributes;

RoiAlignDynamic::RoiAlignDynamic( const std::string& name
                                , int mode
                                , int outputHeight
                                , int outputWidth
                                , int samplingRatio
                                , float spatialScale)
    : mLayerName(name)
    , mMode(mode)
    , mOutputHeight(outputHeight)
    , mOutputWidth(outputWidth)
    , mSamplingRatio(samplingRatio)
    , mSpatialScale(spatialScale) {}

RoiAlignDynamic::RoiAlignDynamic(const std::string name, const void* data, size_t length)
    : mLayerName(name) {
  deserialize_value(&data, &length, &mMode);
  deserialize_value(&data, &length, &mOutputHeight);
  deserialize_value(&data, &length, &mOutputWidth);
  deserialize_value(&data, &length, &mSamplingRatio);
  deserialize_value(&data, &length, &mSpatialScale);
}

nvinfer1::IPluginV2DynamicExt* RoiAlignDynamic::clone() const noexcept {
  RoiAlignDynamic* plugin = new RoiAlignDynamic( mLayerName
                                               , mMode
                                               , mOutputHeight
                                               , mOutputWidth
                                               , mSamplingRatio
                                               , mSpatialScale);
  plugin->setPluginNamespace(getPluginNamespace());
  return plugin;
}

nvinfer1::DimsExprs RoiAlignDynamic::getOutputDimensions( int outputIndex
                                                        , const nvinfer1::DimsExprs* inputs
                                                        , int nbInputs
                                                        , nvinfer1::IExprBuilder& exprBuilder) noexcept {
  // FROM ONNX SPEC: (num_rois, C, output_height, output_width)
  // inputs[0]: X, shape: (N, C, H, W)
  // inputs[1]: rois, shape (num_rois, 4)
  nvinfer1::DimsExprs outputDimensions;
  outputDimensions.nbDims = 4;
  outputDimensions.d[0] = inputs[1].d[0];
  outputDimensions.d[1] = inputs[0].d[1];
  outputDimensions.d[2] = exprBuilder.constant(mOutputHeight);
  outputDimensions.d[3] = exprBuilder.constant(mOutputWidth);
  return outputDimensions;
}

bool RoiAlignDynamic::supportsFormatCombination( int pos
                                               , const nvinfer1::PluginTensorDesc* inOut
                                               , int nbInputs
                                               , int nbOutputs) noexcept {
  if (pos == 0 or pos == 1 or pos == 3) { // X, rois and output
    return inOut[pos].type == nvinfer1::DataType::kFLOAT;
  } else if (pos == 2) { // batch_indicies
    return inOut[pos].type == nvinfer1::DataType::kINT32;
  } else {
    return false;
  }
}

void RoiAlignDynamic::configurePlugin( const nvinfer1::DynamicPluginTensorDesc* inputs
                                     , int nbInputs
                                     , const nvinfer1::DynamicPluginTensorDesc* outputs
                                     , int nbOutputs) noexcept {}

size_t RoiAlignDynamic::getWorkspaceSize( const nvinfer1::PluginTensorDesc* inputs
                                        , int nbInputs
                                        , const nvinfer1::PluginTensorDesc* outputs
                                        , int nbOutputs) const noexcept {
  return 0;
}

int RoiAlignDynamic::enqueue( const nvinfer1::PluginTensorDesc* inputDesc
                            , const nvinfer1::PluginTensorDesc* outputDesc
                            , const void* const* inputs
                            , void* const* outputs
                            , void* workSpace
                            , cudaStream_t stream) noexcept {
  int channels = inputDesc[0].dims.d[1];
  int height   = inputDesc[0].dims.d[2];
  int width    = inputDesc[0].dims.d[3];

  const auto output_dims = outputDesc[0].dims;
  int output_size = output_dims.d[0] * output_dims.d[1] * output_dims.d[2] * output_dims.d[3];

  const void* bottom_data    = inputs[0];
  const void* bottom_rois    = inputs[1];
  const void* batch_indicies = inputs[2];

  void* top_data = outputs[0];

  switch(outputDesc[0].type) {
    case nvinfer1::DataType::kFLOAT:
      RoIAlignForwardCUDAKernelLauncher_float( static_cast<const float*>(bottom_data) // bottom_data
                                             , mSpatialScale // spatial_scale
                                             , output_size // output_size
                                             , channels // channels
                                             , height // height
                                             , width // width
                                             , mOutputHeight // pooled_height
                                             , mOutputWidth // pooled_width
                                             , mSamplingRatio // sampling_ratio
                                             , static_cast<const float*>(bottom_rois) // bottom_rois
                                             , 4 // roi_cols
                                             , static_cast<float*>(top_data)
                                             , mMode // is_mode_avg
                                             , static_cast<const int*>(batch_indicies) // batch_indices_ptr
                                             , stream); // stream
      break;
    default:
      break;
  }

  return 0;
}

nvinfer1::DataType RoiAlignDynamic::getOutputDataType( int index
                                                     , const nvinfer1::DataType* inputTypes
                                                     , int nbInputs) const noexcept {
  return inputTypes[0];
}

const char* RoiAlignDynamic::getPluginType() const noexcept {
  return PLUGIN_NAME;
}

const char* RoiAlignDynamic::getPluginVersion() const noexcept {
  return PLUGIN_VERSION;
}

int RoiAlignDynamic::getNbOutputs() const noexcept { return 1; }

int RoiAlignDynamic::initialize() noexcept { return 0; }

void RoiAlignDynamic::terminate() noexcept {}

size_t RoiAlignDynamic::getSerializationSize() const noexcept {
  return   sizeof(mMode)
         + sizeof(mOutputHeight)
         + sizeof(mOutputWidth)
         + sizeof(mSamplingRatio)
         + sizeof(mSpatialScale);
}

void RoiAlignDynamic::serialize(void* buffer) const noexcept {
  serialize_value(&buffer, mMode);
  serialize_value(&buffer, mOutputHeight);
  serialize_value(&buffer, mOutputWidth);
  serialize_value(&buffer, mSamplingRatio);
  serialize_value(&buffer, mSpatialScale);
}

void RoiAlignDynamic::destroy() noexcept {
  delete this;
}

void RoiAlignDynamic::setPluginNamespace(const char* libNamespace) noexcept {
  mNamespace = libNamespace;
}

const char* RoiAlignDynamic::getPluginNamespace() const noexcept {
  return mNamespace.c_str();
}


RoiAlignDynamicCreator::RoiAlignDynamicCreator() {
  mPluginAttributes.clear();
  mPluginAttributes.emplace_back(nvinfer1::PluginField("mode", nullptr, nvinfer1::PluginFieldType::kCHAR));
  mPluginAttributes.emplace_back(nvinfer1::PluginField("output_height", nullptr, nvinfer1::PluginFieldType::kINT32));
  mPluginAttributes.emplace_back(nvinfer1::PluginField("output_width", nullptr, nvinfer1::PluginFieldType::kINT32));
  mPluginAttributes.emplace_back(nvinfer1::PluginField("sampling_ratio", nullptr, nvinfer1::PluginFieldType::kINT32));
  mPluginAttributes.emplace_back(nvinfer1::PluginField("spatial_scale", nullptr, nvinfer1::PluginFieldType::kFLOAT32));
  mFC.nbFields = mPluginAttributes.size();
  mFC.fields = mPluginAttributes.data();
}

const char* RoiAlignDynamicCreator::getPluginName() const noexcept {
  return PLUGIN_NAME;
}

const char* RoiAlignDynamicCreator::getPluginVersion() const noexcept {
  return PLUGIN_VERSION;
}

const nvinfer1::PluginFieldCollection* RoiAlignDynamicCreator::getFieldNames() noexcept {
  return &mFC;
}

nvinfer1::IPluginV2* RoiAlignDynamicCreator::createPlugin( const char* name
                                                         , const nvinfer1::PluginFieldCollection* fc) noexcept {
  int mode = -1;
  int outputHeight = 1;
  int outputWidth = 1;
  int samplingRatio = 0;
  float spatialScale = 1.f;

  for (int i = 0; i < fc->nbFields; i++) {
    if (fc->fields[i].data == nullptr) {
      continue;
    }
    std::string field_name(fc->fields[i].name);

    if (field_name.compare("mode") == 0) {
      int data_size = fc->fields[i].length;
      const char* data_start = static_cast<const char*>(fc->fields[i].data);
      std::string modeStr(data_start, data_size);
      if (modeStr == "avg") {
        mode = 1;
      } else if (modeStr == "max") {
        mode = 0;
      } else {
        std::cout << "Unknown pool mode \"" << modeStr << "\"." << std::endl;
      }
      assert(mode >= 0);
    }

    if (field_name.compare("output_height") == 0) {
      outputHeight = static_cast<const int*>(fc->fields[i].data)[0];
    }

    if (field_name.compare("output_width") == 0) {
      outputWidth = static_cast<const int*>(fc->fields[i].data)[0];
    }

    if (field_name.compare("sampling_ratio") == 0) {
      samplingRatio = static_cast<const int*>(fc->fields[i].data)[0];
    }

    if (field_name.compare("spatial_scale") == 0) {
      spatialScale = static_cast<const float*>(fc->fields[i].data)[0];
    }
  }

  RoiAlignDynamic* plugin = new RoiAlignDynamic( name
                                               , mode
                                               , outputHeight
                                               , outputWidth
                                               , samplingRatio
                                               , spatialScale);
  plugin->setPluginNamespace(getPluginNamespace());
  return plugin;
}

nvinfer1::IPluginV2* RoiAlignDynamicCreator::deserializePlugin( const char* name
                                                              , const void* serialData
                                                              , size_t serialLength) noexcept {
  auto plugin = new RoiAlignDynamic(name, serialData, serialLength);
  plugin->setPluginNamespace(getPluginNamespace());
  return plugin;
}

void RoiAlignDynamicCreator::setPluginNamespace(const char* libNamespace) noexcept {
  mNamespace = libNamespace;
}

const char* RoiAlignDynamicCreator::getPluginNamespace() const noexcept {
  return mNamespace.c_str();
}
