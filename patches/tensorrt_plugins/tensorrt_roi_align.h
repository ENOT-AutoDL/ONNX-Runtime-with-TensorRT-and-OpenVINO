#pragma once

#include <cublas_v2.h>

#include <memory>
#include <string>
#include <vector>

#include "NvInferPlugin.h"

class RoiAlignDynamic : public nvinfer1::IPluginV2DynamicExt {
 public:
  RoiAlignDynamic( const std::string& name
                 , int mode
                 , int outputHeight
                 , int outputWidth
                 , int samplingRatio
                 , float spatialScale);

  RoiAlignDynamic(const std::string name, const void* data, size_t length);

  RoiAlignDynamic() = delete;

  nvinfer1::IPluginV2DynamicExt* clone() const noexcept override;

  nvinfer1::DimsExprs getOutputDimensions( int outputIndex
                                         , const nvinfer1::DimsExprs* inputs
                                         , int nbInputs
                                         , nvinfer1::IExprBuilder &exprBuilder) noexcept override;

  bool supportsFormatCombination( int pos
                                , const nvinfer1::PluginTensorDesc* inOut
                                , int nbInputs
                                , int nbOutputs) noexcept override;

  void configurePlugin( const nvinfer1::DynamicPluginTensorDesc* in
                      , int nbInputs
                      , const nvinfer1::DynamicPluginTensorDesc *out
                      , int nbOutputs) noexcept override;

  size_t getWorkspaceSize( const nvinfer1::PluginTensorDesc* inputs
                         , int nbInputs
                         , const nvinfer1::PluginTensorDesc* outputs
                         , int nbOutputs) const noexcept override;

  int enqueue( const nvinfer1::PluginTensorDesc* inputDesc
             , const nvinfer1::PluginTensorDesc* outputDesc
             , const void* const* inputs
             , void* const* outputs
             , void* workspace
             , cudaStream_t stream) noexcept override;

  nvinfer1::DataType getOutputDataType( int index
                                      , const nvinfer1::DataType* inputTypes
                                      , int nbInputs) const noexcept override;

  const char* getPluginType() const noexcept override;
  const char* getPluginVersion() const noexcept override;
  int getNbOutputs() const noexcept override;
  int initialize() noexcept override;
  void terminate() noexcept override;
  size_t getSerializationSize() const noexcept override;
  void serialize(void* buffer) const noexcept override;
  void destroy() noexcept override;
  void setPluginNamespace(const char* pluginNamespace) noexcept override;
  const char* getPluginNamespace() const noexcept override;

 private:
  const std::string mLayerName;
  std::string mNamespace;

  int mMode;
  int mOutputHeight;
  int mOutputWidth;
  int mSamplingRatio;
  float mSpatialScale;
};

class RoiAlignDynamicCreator: public nvinfer1::IPluginCreator {
 public:
  RoiAlignDynamicCreator();

  const char* getPluginName() const noexcept override;

  const char* getPluginVersion() const noexcept override;

  const nvinfer1::PluginFieldCollection* getFieldNames() noexcept override;

  nvinfer1::IPluginV2* createPlugin( const char* name
                                   , const nvinfer1::PluginFieldCollection* fc) noexcept override;

  nvinfer1::IPluginV2* deserializePlugin( const char* name
                                        , const void* serialData
                                        , size_t serialLength) noexcept override;

  void setPluginNamespace(const char* pluginNamespace) noexcept override;

  const char* getPluginNamespace() const noexcept override;

 private:
  static nvinfer1::PluginFieldCollection mFC;
  static std::vector<nvinfer1::PluginField> mPluginAttributes;
  std::string mNamespace;
};
