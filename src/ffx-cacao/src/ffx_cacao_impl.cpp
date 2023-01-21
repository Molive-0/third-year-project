// Modifications Copyright � 2021. Advanced Micro Devices, Inc. All Rights Reserved.

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2016, Intel Corporation
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of
// the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// File changes (yyyy-mm-dd)
// 2016-09-07: filip.strugar@intel.com: first commit
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "ffx_cacao_impl.h"
#include "ffx_cacao_defines.h"

#include <assert.h>
#include <math.h>   // cos, sin
#include <string.h> // memcpy
#include <stdio.h>  // snprintf

// Define symbol to enable DirectX debug markers created using Cauldron
#define FFX_CACAO_ENABLE_VULKAN

#define FFX_CACAO_ASSERT(exp) assert(exp)
#define FFX_CACAO_ARRAY_SIZE(xs) (sizeof(xs)/sizeof(xs[0]))
#define FFX_CACAO_COS(x) cosf(x)
#define FFX_CACAO_SIN(x) sinf(x)
#define FFX_CACAO_MIN(x, y) (((x) < (y)) ? (x) : (y))
#define FFX_CACAO_MAX(x, y) (((x) > (y)) ? (x) : (y))
#define FFX_CACAO_CLAMP(value, lower, upper) FFX_CACAO_MIN(FFX_CACAO_MAX(value, lower), upper)
#define FFX_CACAO_OFFSET_OF(T, member) (size_t)(&(((T*)0)->member))

#ifdef FFX_CACAO_ENABLE_VULKAN
// 16 bit versions
#include "PrecompiledShadersSPIRV/CACAOClearLoadCounter_16.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledDepthsHalf_16.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeDepthsHalf_16.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledDepthsAndMips_16.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeDepthsAndMips_16.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledNormals_16.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeNormals_16.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledNormalsFromInputNormals_16.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeNormalsFromInputNormals_16.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledDepths_16.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeDepths_16.h"

#include "PrecompiledShadersSPIRV/CACAOGenerateQ0_16.h"
#include "PrecompiledShadersSPIRV/CACAOGenerateQ1_16.h"
#include "PrecompiledShadersSPIRV/CACAOGenerateQ2_16.h"
#include "PrecompiledShadersSPIRV/CACAOGenerateQ3_16.h"
#include "PrecompiledShadersSPIRV/CACAOGenerateQ3Base_16.h"

#include "PrecompiledShadersSPIRV/CACAOGenerateImportanceMap_16.h"
#include "PrecompiledShadersSPIRV/CACAOPostprocessImportanceMapA_16.h"
#include "PrecompiledShadersSPIRV/CACAOPostprocessImportanceMapB_16.h"

#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur1_16.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur2_16.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur3_16.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur4_16.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur5_16.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur6_16.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur7_16.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur8_16.h"

#include "PrecompiledShadersSPIRV/CACAOApply_16.h"
#include "PrecompiledShadersSPIRV/CACAONonSmartApply_16.h"
#include "PrecompiledShadersSPIRV/CACAONonSmartHalfApply_16.h"

#include "PrecompiledShadersSPIRV/CACAOUpscaleBilateral5x5Smart_16.h"
#include "PrecompiledShadersSPIRV/CACAOUpscaleBilateral5x5NonSmart_16.h"
#include "PrecompiledShadersSPIRV/CACAOUpscaleBilateral5x5Half_16.h"

// 32 bit versions
#include "PrecompiledShadersSPIRV/CACAOClearLoadCounter_32.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledDepthsHalf_32.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeDepthsHalf_32.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledDepthsAndMips_32.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeDepthsAndMips_32.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledNormals_32.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeNormals_32.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledNormalsFromInputNormals_32.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeNormalsFromInputNormals_32.h"

#include "PrecompiledShadersSPIRV/CACAOPrepareDownsampledDepths_32.h"
#include "PrecompiledShadersSPIRV/CACAOPrepareNativeDepths_32.h"

#include "PrecompiledShadersSPIRV/CACAOGenerateQ0_32.h"
#include "PrecompiledShadersSPIRV/CACAOGenerateQ1_32.h"
#include "PrecompiledShadersSPIRV/CACAOGenerateQ2_32.h"
#include "PrecompiledShadersSPIRV/CACAOGenerateQ3_32.h"
#include "PrecompiledShadersSPIRV/CACAOGenerateQ3Base_32.h"

#include "PrecompiledShadersSPIRV/CACAOGenerateImportanceMap_32.h"
#include "PrecompiledShadersSPIRV/CACAOPostprocessImportanceMapA_32.h"
#include "PrecompiledShadersSPIRV/CACAOPostprocessImportanceMapB_32.h"

#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur1_32.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur2_32.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur3_32.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur4_32.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur5_32.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur6_32.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur7_32.h"
#include "PrecompiledShadersSPIRV/CACAOEdgeSensitiveBlur8_32.h"

#include "PrecompiledShadersSPIRV/CACAOApply_32.h"
#include "PrecompiledShadersSPIRV/CACAONonSmartApply_32.h"
#include "PrecompiledShadersSPIRV/CACAONonSmartHalfApply_32.h"

#include "PrecompiledShadersSPIRV/CACAOUpscaleBilateral5x5Smart_32.h"
#include "PrecompiledShadersSPIRV/CACAOUpscaleBilateral5x5NonSmart_32.h"
#include "PrecompiledShadersSPIRV/CACAOUpscaleBilateral5x5Half_32.h"
#endif

#define MAX_BLUR_PASSES 8

#define USER_MARKER(name) CAULDRON_DX12::UserMarker __marker(commandList, name)
#else
#define USER_MARKER(name)
#endif

inline static uint32_t dispatchSize(uint32_t tileSize, uint32_t totalSize)
{
	return (totalSize + tileSize - 1) / tileSize;
}

#ifdef FFX_CACAO_ENABLE_PROFILING
// TIMESTAMP(name)
#define TIMESTAMPS \
	TIMESTAMP(BEGIN) \
	TIMESTAMP(PREPARE) \
	TIMESTAMP(BASE_SSAO_PASS) \
	TIMESTAMP(IMPORTANCE_MAP) \
	TIMESTAMP(GENERATE_SSAO) \
	TIMESTAMP(EDGE_SENSITIVE_BLUR) \
	TIMESTAMP(BILATERAL_UPSAMPLE) \
	TIMESTAMP(APPLY)

typedef enum TimestampID {
#define TIMESTAMP(name) TIMESTAMP_##name,
	TIMESTAMPS
#undef TIMESTAMP
	NUM_TIMESTAMPS
} TimestampID;

static const char *TIMESTAMP_NAMES[NUM_TIMESTAMPS] = {
#define TIMESTAMP(name) "FFX_CACAO_" #name,
	TIMESTAMPS
#undef TIMESTAMP
};

#define NUM_TIMESTAMP_BUFFERS 5
#endif

// TIMESTAMP_FORMAT(name, vulkan_format, d3d12_format)
#define TEXTURE_FORMATS \
	TEXTURE_FORMAT(R16_SFLOAT,          VK_FORMAT_R16_SFLOAT,          DXGI_FORMAT_R16_FLOAT) \
	TEXTURE_FORMAT(R16G16B16A16_SFLOAT, VK_FORMAT_R16G16B16A16_SFLOAT, DXGI_FORMAT_R16G16B16A16_FLOAT) \
	TEXTURE_FORMAT(R8G8B8A8_SNORM,      VK_FORMAT_R8G8B8A8_SNORM,      DXGI_FORMAT_R8G8B8A8_SNORM) \
	TEXTURE_FORMAT(R8G8_UNORM,          VK_FORMAT_R8G8_UNORM,          DXGI_FORMAT_R8G8_UNORM) \
	TEXTURE_FORMAT(R8_UNORM,            VK_FORMAT_R8_UNORM,            DXGI_FORMAT_R8_UNORM)

typedef enum TextureFormatID {
#define TEXTURE_FORMAT(name, _vulkan_format, _d3d12_format) TEXTURE_FORMAT_##name,
	TEXTURE_FORMATS
#undef TEXTURE_FORMAT
} TextureFormatID;

#ifdef FFX_CACAO_ENABLE_VULKAN
static const VkFormat TEXTURE_FORMAT_LOOKUP_VK[] = {
#define TEXTURE_FORMAT(_name, vulkan_format, _d3d12_format) vulkan_format,
	TEXTURE_FORMATS
#undef TEXTURE_FORMAT
};
#endif

// TEXTURE(name, width, height, texture_format, array_size, num_mips)
#define TEXTURES \
	TEXTURE(DEINTERLEAVED_DEPTHS,    deinterleavedDepthBufferWidth, deinterleavedDepthBufferHeight, TEXTURE_FORMAT_R16_SFLOAT,          4, 4) \
	TEXTURE(DEINTERLEAVED_NORMALS,   ssaoBufferWidth,               ssaoBufferHeight,               TEXTURE_FORMAT_R8G8B8A8_SNORM,      4, 1) \
	TEXTURE(SSAO_BUFFER_PING,        ssaoBufferWidth,               ssaoBufferHeight,               TEXTURE_FORMAT_R8G8_UNORM,          4, 1) \
	TEXTURE(SSAO_BUFFER_PONG,        ssaoBufferWidth,               ssaoBufferHeight,               TEXTURE_FORMAT_R8G8_UNORM,          4, 1) \
	TEXTURE(IMPORTANCE_MAP,          importanceMapWidth,            importanceMapHeight,            TEXTURE_FORMAT_R8_UNORM,            1, 1) \
	TEXTURE(IMPORTANCE_MAP_PONG,     importanceMapWidth,            importanceMapHeight,            TEXTURE_FORMAT_R8_UNORM,            1, 1) \
	TEXTURE(DOWNSAMPLED_SSAO_BUFFER, downsampledSsaoBufferWidth,    downsampledSsaoBufferHeight,    TEXTURE_FORMAT_R8_UNORM,            1, 1)

typedef enum TextureID {
#define TEXTURE(name, _width, _height, _format, _array_size, _num_mips) TEXTURE_##name,
	TEXTURES
#undef TEXTURE
	NUM_TEXTURES
} TextureID;

typedef struct TextureMetaData {
	size_t widthOffset;
	size_t heightOffset;
	TextureFormatID format;
	uint32_t arraySize;
	uint32_t numMips;
	const char *name;
} TextureMetaData;

static const TextureMetaData TEXTURE_META_DATA[NUM_TEXTURES] = {
#define TEXTURE(name, width, height, format, array_size, num_mips) { FFX_CACAO_OFFSET_OF(FFX_CACAO_BufferSizeInfo, width), FFX_CACAO_OFFSET_OF(FFX_CACAO_BufferSizeInfo, height), format, array_size, num_mips, "FFX_CACAO_" #name },
	TEXTURES
#undef TEXTURE
};

// DESCRIPTOR_SET_LAYOUT(name, num_inputs, num_outputs)
#define DESCRIPTOR_SET_LAYOUTS \
	DESCRIPTOR_SET_LAYOUT(CLEAR_LOAD_COUNTER,                 0, 1) \
	DESCRIPTOR_SET_LAYOUT(PREPARE_DEPTHS,                     1, 1) \
	DESCRIPTOR_SET_LAYOUT(PREPARE_DEPTHS_MIPS,                1, 4) \
	DESCRIPTOR_SET_LAYOUT(PREPARE_POINTS,                     1, 1) \
	DESCRIPTOR_SET_LAYOUT(PREPARE_POINTS_MIPS,                1, 4) \
	DESCRIPTOR_SET_LAYOUT(PREPARE_NORMALS,                    1, 1) \
	DESCRIPTOR_SET_LAYOUT(PREPARE_NORMALS_FROM_INPUT_NORMALS, 1, 1) \
	DESCRIPTOR_SET_LAYOUT(GENERATE,                           2, 1) \
	DESCRIPTOR_SET_LAYOUT(GENERATE_ADAPTIVE,                  5, 1) \
	DESCRIPTOR_SET_LAYOUT(GENERATE_IMPORTANCE_MAP,            1, 1) \
	DESCRIPTOR_SET_LAYOUT(POSTPROCESS_IMPORTANCE_MAP_A,       1, 1) \
	DESCRIPTOR_SET_LAYOUT(POSTPROCESS_IMPORTANCE_MAP_B,       1, 2) \
	DESCRIPTOR_SET_LAYOUT(EDGE_SENSITIVE_BLUR,                1, 1) \
	DESCRIPTOR_SET_LAYOUT(APPLY,                              1, 1) \
	DESCRIPTOR_SET_LAYOUT(BILATERAL_UPSAMPLE,                 4, 1)

typedef enum DescriptorSetLayoutID {
#define DESCRIPTOR_SET_LAYOUT(name, _num_inputs, _num_outputs) DSL_##name,
	DESCRIPTOR_SET_LAYOUTS
#undef DESCRIPTOR_SET_LAYOUT
	NUM_DESCRIPTOR_SET_LAYOUTS
} DescriptorSetLayoutID;

typedef struct DescriptorSetLayoutMetaData {
	uint32_t    numInputs;
	uint32_t    numOutputs;
	const char *name;
} DescriptorSetLayoutMetaData;

static const DescriptorSetLayoutMetaData DESCRIPTOR_SET_LAYOUT_META_DATA[NUM_DESCRIPTOR_SET_LAYOUTS] = {
#define DESCRIPTOR_SET_LAYOUT(name, num_inputs, num_outputs) { num_inputs, num_outputs, "FFX_CACAO_DSL_" #name },
	DESCRIPTOR_SET_LAYOUTS
#undef DESCRIPTOR_SET_LAYOUT
};

// DESCRIPTOR_SET(name, layout_name, pass)
#define DESCRIPTOR_SETS \
	DESCRIPTOR_SET(CLEAR_LOAD_COUNTER,                 CLEAR_LOAD_COUNTER,                 0) \
	DESCRIPTOR_SET(PREPARE_DEPTHS,                     PREPARE_DEPTHS,                     0) \
	DESCRIPTOR_SET(PREPARE_DEPTHS_MIPS,                PREPARE_DEPTHS_MIPS,                0) \
	DESCRIPTOR_SET(PREPARE_POINTS,                     PREPARE_POINTS,                     0) \
	DESCRIPTOR_SET(PREPARE_POINTS_MIPS,                PREPARE_POINTS_MIPS,                0) \
	DESCRIPTOR_SET(PREPARE_NORMALS,                    PREPARE_NORMALS,                    0) \
	DESCRIPTOR_SET(PREPARE_NORMALS_FROM_INPUT_NORMALS, PREPARE_NORMALS_FROM_INPUT_NORMALS, 0) \
	DESCRIPTOR_SET(GENERATE_ADAPTIVE_BASE_0,           GENERATE,                           0) \
	DESCRIPTOR_SET(GENERATE_ADAPTIVE_BASE_1,           GENERATE,                           1) \
	DESCRIPTOR_SET(GENERATE_ADAPTIVE_BASE_2,           GENERATE,                           2) \
	DESCRIPTOR_SET(GENERATE_ADAPTIVE_BASE_3,           GENERATE,                           3) \
	DESCRIPTOR_SET(GENERATE_0,                         GENERATE,                           0) \
	DESCRIPTOR_SET(GENERATE_1,                         GENERATE,                           1) \
	DESCRIPTOR_SET(GENERATE_2,                         GENERATE,                           2) \
	DESCRIPTOR_SET(GENERATE_3,                         GENERATE,                           3) \
	DESCRIPTOR_SET(GENERATE_ADAPTIVE_0,                GENERATE_ADAPTIVE,                  0) \
	DESCRIPTOR_SET(GENERATE_ADAPTIVE_1,                GENERATE_ADAPTIVE,                  1) \
	DESCRIPTOR_SET(GENERATE_ADAPTIVE_2,                GENERATE_ADAPTIVE,                  2) \
	DESCRIPTOR_SET(GENERATE_ADAPTIVE_3,                GENERATE_ADAPTIVE,                  3) \
	DESCRIPTOR_SET(GENERATE_IMPORTANCE_MAP,            GENERATE_IMPORTANCE_MAP,            0) \
	DESCRIPTOR_SET(POSTPROCESS_IMPORTANCE_MAP_A,       POSTPROCESS_IMPORTANCE_MAP_A,       0) \
	DESCRIPTOR_SET(POSTPROCESS_IMPORTANCE_MAP_B,       POSTPROCESS_IMPORTANCE_MAP_B,       0) \
	DESCRIPTOR_SET(EDGE_SENSITIVE_BLUR_0,              EDGE_SENSITIVE_BLUR,                0) \
	DESCRIPTOR_SET(EDGE_SENSITIVE_BLUR_1,              EDGE_SENSITIVE_BLUR,                1) \
	DESCRIPTOR_SET(EDGE_SENSITIVE_BLUR_2,              EDGE_SENSITIVE_BLUR,                2) \
	DESCRIPTOR_SET(EDGE_SENSITIVE_BLUR_3,              EDGE_SENSITIVE_BLUR,                3) \
	DESCRIPTOR_SET(APPLY_PING,                         APPLY,                              0) \
	DESCRIPTOR_SET(APPLY_PONG,                         APPLY,                              0) \
	DESCRIPTOR_SET(BILATERAL_UPSAMPLE_PING,            BILATERAL_UPSAMPLE,                 0) \
	DESCRIPTOR_SET(BILATERAL_UPSAMPLE_PONG,            BILATERAL_UPSAMPLE,                 0)

typedef enum DescriptorSetID {
#define DESCRIPTOR_SET(name, _layout_name, _pass) DS_##name,
	DESCRIPTOR_SETS
#undef DESCRIPTOR_SET
	NUM_DESCRIPTOR_SETS
} DescriptorSetID;

typedef struct DescriptorSetMetaData {
	DescriptorSetLayoutID descriptorSetLayoutID;
	uint32_t pass;
	const char *name;
} DescriptorSetMetaData;

static const DescriptorSetMetaData DESCRIPTOR_SET_META_DATA[NUM_DESCRIPTOR_SETS] = {
#define DESCRIPTOR_SET(name, layout_name, pass) { DSL_##layout_name, pass, "FFX_CACAO_DS_" #name },
	DESCRIPTOR_SETS
#undef DESCRIPTOR_SET
};

// VIEW_TYPE(name, vulkan_view_type, d3d12_view_type_srv)
#define VIEW_TYPES \
	VIEW_TYPE(2D,       VK_IMAGE_VIEW_TYPE_2D,       D3D12_SRV_DIMENSION_TEXTURE2D,      D3D12_UAV_DIMENSION_TEXTURE2D) \
	VIEW_TYPE(2D_ARRAY, VK_IMAGE_VIEW_TYPE_2D_ARRAY, D3D12_SRV_DIMENSION_TEXTURE2DARRAY, D3D12_UAV_DIMENSION_TEXTURE2DARRAY)

typedef enum ViewTypeID {
#define VIEW_TYPE(name, _vulkan_view_type, _d3d12_view_type_srv, _d3d12_view_type_uav) VIEW_TYPE_##name,
	VIEW_TYPES
#undef VIEW_TYPE
} ViewTypeID;

#ifdef FFX_CACAO_ENABLE_VULKAN
static const VkImageViewType VIEW_TYPE_LOOKUP_VK[] = {
#define VIEW_TYPE(_name, vulkan_view_type, _d3d12_view_type_srv, _d3d12_view_type_uav) vulkan_view_type,
	VIEW_TYPES
#undef VIEW_TYPE
};
#endif

// SHADER_RESOURCE_VIEW(name, texture, view_dimension, most_detailed_mip, mip_levels, first_array_slice, array_size)
#define SHADER_RESOURCE_VIEWS \
	SHADER_RESOURCE_VIEW(DEINTERLEAVED_DEPTHS,    DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 0, 4, 0, 4) \
	SHADER_RESOURCE_VIEW(DEINTERLEAVED_DEPTHS_0,  DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 0, 4, 0, 1) \
	SHADER_RESOURCE_VIEW(DEINTERLEAVED_DEPTHS_1,  DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 0, 4, 1, 1) \
	SHADER_RESOURCE_VIEW(DEINTERLEAVED_DEPTHS_2,  DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 0, 4, 2, 1) \
	SHADER_RESOURCE_VIEW(DEINTERLEAVED_DEPTHS_3,  DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 0, 4, 3, 1) \
	SHADER_RESOURCE_VIEW(DEINTERLEAVED_NORMALS,   DEINTERLEAVED_NORMALS, VIEW_TYPE_2D_ARRAY, 0, 1, 0, 4) \
	SHADER_RESOURCE_VIEW(IMPORTANCE_MAP,          IMPORTANCE_MAP,        VIEW_TYPE_2D,       0, 1, 0, 1) \
	SHADER_RESOURCE_VIEW(IMPORTANCE_MAP_PONG,     IMPORTANCE_MAP_PONG,   VIEW_TYPE_2D,       0, 1, 0, 1) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PING,        SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 1, 0, 4) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PING_0,      SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 1, 0, 1) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PING_1,      SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 1, 1, 1) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PING_2,      SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 1, 2, 1) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PING_3,      SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 1, 3, 1) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PONG,        SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 1, 0, 4) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PONG_0,      SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 1, 0, 1) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PONG_1,      SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 1, 1, 1) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PONG_2,      SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 1, 2, 1) \
	SHADER_RESOURCE_VIEW(SSAO_BUFFER_PONG_3,      SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 1, 3, 1)

typedef enum ShaderResourceViewID {
#define SHADER_RESOURCE_VIEW(name, _texture, _view_dimension, _most_detailed_mip, _mip_levels, _first_array_slice, _array_size) SRV_##name,
	SHADER_RESOURCE_VIEWS
#undef SHADER_RESOURCE_VIEW
	NUM_SHADER_RESOURCE_VIEWS
} ShaderResourceViewID;

typedef struct ShaderResourceViewMetaData {
	TextureID       texture;
	ViewTypeID      viewType;
	uint32_t        mostDetailedMip;
	uint32_t        mipLevels;
	uint32_t        firstArraySlice;
	uint32_t        arraySize;
} ShaderResourceViewMetaData;

static const ShaderResourceViewMetaData SRV_META_DATA[NUM_SHADER_RESOURCE_VIEWS] = {
#define SHADER_RESOURCE_VIEW(_name, texture, view_dimension, most_detailed_mip, mip_levels, first_array_slice, array_size) { TEXTURE_##texture, view_dimension, most_detailed_mip, mip_levels, first_array_slice, array_size },
	SHADER_RESOURCE_VIEWS
#undef SHADER_RESOURCE_VIEW
};

// UNORDERED_ACCESS_VIEW(name, texture, view_dimension, mip_slice, first_array_slice, array_size)
#define UNORDERED_ACCESS_VIEWS \
	UNORDERED_ACCESS_VIEW(DEINTERLEAVED_DEPTHS_MIP_0, DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 0, 0, 4) \
	UNORDERED_ACCESS_VIEW(DEINTERLEAVED_DEPTHS_MIP_1, DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 1, 0, 4) \
	UNORDERED_ACCESS_VIEW(DEINTERLEAVED_DEPTHS_MIP_2, DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 2, 0, 4) \
	UNORDERED_ACCESS_VIEW(DEINTERLEAVED_DEPTHS_MIP_3, DEINTERLEAVED_DEPTHS,  VIEW_TYPE_2D_ARRAY, 3, 0, 4) \
	UNORDERED_ACCESS_VIEW(DEINTERLEAVED_NORMALS,      DEINTERLEAVED_NORMALS, VIEW_TYPE_2D_ARRAY, 0, 0, 4) \
	UNORDERED_ACCESS_VIEW(IMPORTANCE_MAP,             IMPORTANCE_MAP,        VIEW_TYPE_2D,       0, 0, 1) \
	UNORDERED_ACCESS_VIEW(IMPORTANCE_MAP_PONG,        IMPORTANCE_MAP_PONG,   VIEW_TYPE_2D,       0, 0, 1) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PING,           SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 0, 4) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PING_0,         SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 0, 1) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PING_1,         SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 1, 1) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PING_2,         SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 2, 1) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PING_3,         SSAO_BUFFER_PING,      VIEW_TYPE_2D_ARRAY, 0, 3, 1) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PONG,           SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 0, 4) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PONG_0,         SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 0, 1) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PONG_1,         SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 1, 1) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PONG_2,         SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 2, 1) \
	UNORDERED_ACCESS_VIEW(SSAO_BUFFER_PONG_3,         SSAO_BUFFER_PONG,      VIEW_TYPE_2D_ARRAY, 0, 3, 1)

typedef enum UnorderedAccessViewID {
#define UNORDERED_ACCESS_VIEW(name, _texture, _view_dimension, _mip_slice, _first_array_slice, _array_size) UAV_##name,
	UNORDERED_ACCESS_VIEWS
#undef UNORDERED_ACCESS_VIEW
	NUM_UNORDERED_ACCESS_VIEWS
} UnorderedAccessViewID;

typedef struct UnorderedAccessViewMetaData {
	TextureID   textureID;
	ViewTypeID  viewType;
	uint32_t    mostDetailedMip;
	uint32_t    firstArraySlice;
	uint32_t    arraySize;
} UnorderedAccessViewMetaData;

static const UnorderedAccessViewMetaData UAV_META_DATA[NUM_UNORDERED_ACCESS_VIEWS] = {
#define UNORDERED_ACCESS_VIEW(_name, texture, view_dimension, mip_slice, first_array_slice, array_size) { TEXTURE_##texture, view_dimension, mip_slice, first_array_slice, array_size },
	UNORDERED_ACCESS_VIEWS
#undef UNORDERED_ACCESS_VIEW
};

// INPUT_DESCRIPTOR(descriptor_set_name, srv_name, binding_num)
#define INPUT_DESCRIPTOR_BINDINGS \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_0,     DEINTERLEAVED_DEPTHS_0, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_0,     DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_1,     DEINTERLEAVED_DEPTHS_1, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_1,     DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_2,     DEINTERLEAVED_DEPTHS_2, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_2,     DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_3,     DEINTERLEAVED_DEPTHS_3, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_3,     DEINTERLEAVED_NORMALS,  1) \
	\
	INPUT_DESCRIPTOR_BINDING(GENERATE_0,  DEINTERLEAVED_DEPTHS_0, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_0,  DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_1,  DEINTERLEAVED_DEPTHS_1, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_1,  DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_2,  DEINTERLEAVED_DEPTHS_2, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_2,  DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_3,  DEINTERLEAVED_DEPTHS_3, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_3,  DEINTERLEAVED_NORMALS,  1) \
	\
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_0,  DEINTERLEAVED_DEPTHS_0, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_0,  DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_0,  IMPORTANCE_MAP,         3) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_0,  SSAO_BUFFER_PONG_0,     4) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_1,  DEINTERLEAVED_DEPTHS_1, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_1,  DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_1,  IMPORTANCE_MAP,         3) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_1,  SSAO_BUFFER_PONG_1,     4) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_2,  DEINTERLEAVED_DEPTHS_2, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_2,  DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_2,  IMPORTANCE_MAP,         3) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_2,  SSAO_BUFFER_PONG_2,     4) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_3,  DEINTERLEAVED_DEPTHS_3, 0) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_3,  DEINTERLEAVED_NORMALS,  1) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_3,  IMPORTANCE_MAP,         3) \
	INPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_3,  SSAO_BUFFER_PONG_3,     4) \
	\
	INPUT_DESCRIPTOR_BINDING(GENERATE_IMPORTANCE_MAP,      SSAO_BUFFER_PONG,       0) \
	INPUT_DESCRIPTOR_BINDING(POSTPROCESS_IMPORTANCE_MAP_A, IMPORTANCE_MAP,         0) \
	INPUT_DESCRIPTOR_BINDING(POSTPROCESS_IMPORTANCE_MAP_B, IMPORTANCE_MAP_PONG,    0) \
	\
	INPUT_DESCRIPTOR_BINDING(EDGE_SENSITIVE_BLUR_0, SSAO_BUFFER_PING_0, 0) \
	INPUT_DESCRIPTOR_BINDING(EDGE_SENSITIVE_BLUR_1, SSAO_BUFFER_PING_1, 0) \
	INPUT_DESCRIPTOR_BINDING(EDGE_SENSITIVE_BLUR_2, SSAO_BUFFER_PING_2, 0) \
	INPUT_DESCRIPTOR_BINDING(EDGE_SENSITIVE_BLUR_3, SSAO_BUFFER_PING_3, 0) \
	\
	INPUT_DESCRIPTOR_BINDING(BILATERAL_UPSAMPLE_PING, SSAO_BUFFER_PING,     0) \
	INPUT_DESCRIPTOR_BINDING(BILATERAL_UPSAMPLE_PING, DEINTERLEAVED_DEPTHS, 2) \
	INPUT_DESCRIPTOR_BINDING(BILATERAL_UPSAMPLE_PONG, SSAO_BUFFER_PONG,     0) \
	INPUT_DESCRIPTOR_BINDING(BILATERAL_UPSAMPLE_PONG, DEINTERLEAVED_DEPTHS, 2) \
	\
	INPUT_DESCRIPTOR_BINDING(APPLY_PING, SSAO_BUFFER_PING, 0) \
	INPUT_DESCRIPTOR_BINDING(APPLY_PONG, SSAO_BUFFER_PONG, 0)

// need this to define NUM_INPUT_DESCRIPTOR_BINDINGS
typedef enum InputDescriptorBindingID {
#define INPUT_DESCRIPTOR_BINDING(descriptor_set_name, srv_name, _binding_num) INPUT_DESCRIPTOR_BINDING_##descriptor_set_name##_##srv_name,
	INPUT_DESCRIPTOR_BINDINGS
#undef INPUT_DESCRIPTOR_BINDING
	NUM_INPUT_DESCRIPTOR_BINDINGS
} InputDescriptorBindingID;

typedef struct InputDescriptorBindingMetaData {
	DescriptorSetID      descriptorID;
	ShaderResourceViewID srvID;
	uint32_t             bindingNumber;
} InputDescriptorBindingMetaData;

static const InputDescriptorBindingMetaData INPUT_DESCRIPTOR_BINDING_META_DATA[NUM_INPUT_DESCRIPTOR_BINDINGS] = {
#define INPUT_DESCRIPTOR_BINDING(descriptor_set_name, srv_name, binding_num) { DS_##descriptor_set_name, SRV_##srv_name, binding_num },
	INPUT_DESCRIPTOR_BINDINGS
#undef INPUT_DESCRIPTOR_BINDING
};

// OUTPUT_DESCRIPTOR(descriptor_set_name, uav_name, binding_num)
#define OUTPUT_DESCRIPTOR_BINDINGS \
	OUTPUT_DESCRIPTOR_BINDING(PREPARE_DEPTHS,                     DEINTERLEAVED_DEPTHS_MIP_0, 0) \
	OUTPUT_DESCRIPTOR_BINDING(PREPARE_DEPTHS_MIPS,                DEINTERLEAVED_DEPTHS_MIP_0, 0) \
	OUTPUT_DESCRIPTOR_BINDING(PREPARE_DEPTHS_MIPS,                DEINTERLEAVED_DEPTHS_MIP_1, 1) \
	OUTPUT_DESCRIPTOR_BINDING(PREPARE_DEPTHS_MIPS,                DEINTERLEAVED_DEPTHS_MIP_2, 2) \
	OUTPUT_DESCRIPTOR_BINDING(PREPARE_DEPTHS_MIPS,                DEINTERLEAVED_DEPTHS_MIP_3, 3) \
	OUTPUT_DESCRIPTOR_BINDING(PREPARE_NORMALS,                    DEINTERLEAVED_NORMALS,      0) \
	OUTPUT_DESCRIPTOR_BINDING(PREPARE_NORMALS_FROM_INPUT_NORMALS, DEINTERLEAVED_NORMALS,      0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_0,           SSAO_BUFFER_PONG_0,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_1,           SSAO_BUFFER_PONG_1,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_2,           SSAO_BUFFER_PONG_2,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_BASE_3,           SSAO_BUFFER_PONG_3,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_0,                         SSAO_BUFFER_PING_0,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_1,                         SSAO_BUFFER_PING_1,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_2,                         SSAO_BUFFER_PING_2,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_3,                         SSAO_BUFFER_PING_3,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_0,                SSAO_BUFFER_PING_0,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_1,                SSAO_BUFFER_PING_1,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_2,                SSAO_BUFFER_PING_2,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_ADAPTIVE_3,                SSAO_BUFFER_PING_3,         0) \
	OUTPUT_DESCRIPTOR_BINDING(GENERATE_IMPORTANCE_MAP,            IMPORTANCE_MAP,             0) \
	OUTPUT_DESCRIPTOR_BINDING(POSTPROCESS_IMPORTANCE_MAP_A,       IMPORTANCE_MAP_PONG,        0) \
	OUTPUT_DESCRIPTOR_BINDING(POSTPROCESS_IMPORTANCE_MAP_B,       IMPORTANCE_MAP,             0) \
	OUTPUT_DESCRIPTOR_BINDING(EDGE_SENSITIVE_BLUR_0,              SSAO_BUFFER_PONG_0,         0) \
	OUTPUT_DESCRIPTOR_BINDING(EDGE_SENSITIVE_BLUR_1,              SSAO_BUFFER_PONG_1,         0) \
	OUTPUT_DESCRIPTOR_BINDING(EDGE_SENSITIVE_BLUR_2,              SSAO_BUFFER_PONG_2,         0) \
	OUTPUT_DESCRIPTOR_BINDING(EDGE_SENSITIVE_BLUR_3,              SSAO_BUFFER_PONG_3,         0)

typedef enum OutputDescriptorBindingID {
#define OUTPUT_DESCRIPTOR_BINDING(descriptor_set_name, uav_name, _binding_num) OUTPUT_DESCRIPTOR_BINDING_##descriptor_set_name##_##uav_name,
	OUTPUT_DESCRIPTOR_BINDINGS
#undef OUTPUT_DESCRIPTOR_BINDING
	NUM_OUTPUT_DESCRIPTOR_BINDINGS
} OutputDescriptorBindingID;

typedef struct OutputDescriptorBindingMetaData {
	DescriptorSetID      descriptorID;
	UnorderedAccessViewID uavID;
	uint32_t              bindingNumber;
} OutputDescriptorBindingMetaData;

static const OutputDescriptorBindingMetaData OUTPUT_DESCRIPTOR_BINDING_META_DATA[NUM_OUTPUT_DESCRIPTOR_BINDINGS] = {
#define OUTPUT_DESCRIPTOR_BINDING(descriptor_set_name, uav_name, binding_num) { DS_##descriptor_set_name, UAV_##uav_name, binding_num },
	OUTPUT_DESCRIPTOR_BINDINGS
#undef OUTPUT_DESCRIPTOR_BINDING
};

// define all the data for compute shaders
// COMPUTE_SHADER(enum_name, pascal_case_name, descriptor_set)
#define COMPUTE_SHADERS \
	COMPUTE_SHADER(CLEAR_LOAD_COUNTER,                             ClearLoadCounter,                          CLEAR_LOAD_COUNTER) \
	\
	COMPUTE_SHADER(PREPARE_DOWNSAMPLED_DEPTHS,                     PrepareDownsampledDepths,                  PREPARE_DEPTHS) \
	COMPUTE_SHADER(PREPARE_NATIVE_DEPTHS,                          PrepareNativeDepths,                       PREPARE_DEPTHS) \
	COMPUTE_SHADER(PREPARE_DOWNSAMPLED_DEPTHS_AND_MIPS,            PrepareDownsampledDepthsAndMips,           PREPARE_DEPTHS_MIPS) \
	COMPUTE_SHADER(PREPARE_NATIVE_DEPTHS_AND_MIPS,                 PrepareNativeDepthsAndMips,                PREPARE_DEPTHS_MIPS) \
	COMPUTE_SHADER(PREPARE_DOWNSAMPLED_NORMALS,                    PrepareDownsampledNormals,                 PREPARE_NORMALS) \
	COMPUTE_SHADER(PREPARE_NATIVE_NORMALS,                         PrepareNativeNormals,                      PREPARE_NORMALS) \
	COMPUTE_SHADER(PREPARE_DOWNSAMPLED_NORMALS_FROM_INPUT_NORMALS, PrepareDownsampledNormalsFromInputNormals, PREPARE_NORMALS_FROM_INPUT_NORMALS) \
	COMPUTE_SHADER(PREPARE_NATIVE_NORMALS_FROM_INPUT_NORMALS,      PrepareNativeNormalsFromInputNormals,      PREPARE_NORMALS_FROM_INPUT_NORMALS) \
	COMPUTE_SHADER(PREPARE_DOWNSAMPLED_DEPTHS_HALF,                PrepareDownsampledDepthsHalf,              PREPARE_DEPTHS) \
	COMPUTE_SHADER(PREPARE_NATIVE_DEPTHS_HALF,                     PrepareNativeDepthsHalf,                   PREPARE_DEPTHS) \
	\
	COMPUTE_SHADER(GENERATE_Q0,                                    GenerateQ0,                                GENERATE) \
	COMPUTE_SHADER(GENERATE_Q1,                                    GenerateQ1,                                GENERATE) \
	COMPUTE_SHADER(GENERATE_Q2,                                    GenerateQ2,                                GENERATE) \
	COMPUTE_SHADER(GENERATE_Q3,                                    GenerateQ3,                                GENERATE_ADAPTIVE) \
	COMPUTE_SHADER(GENERATE_Q3_BASE,                               GenerateQ3Base,                            GENERATE) \
	\
	COMPUTE_SHADER(GENERATE_IMPORTANCE_MAP,                        GenerateImportanceMap,                     GENERATE_IMPORTANCE_MAP) \
	COMPUTE_SHADER(POSTPROCESS_IMPORTANCE_MAP_A,                   PostprocessImportanceMapA,                 POSTPROCESS_IMPORTANCE_MAP_A) \
	COMPUTE_SHADER(POSTPROCESS_IMPORTANCE_MAP_B,                   PostprocessImportanceMapB,                 POSTPROCESS_IMPORTANCE_MAP_B) \
	\
	COMPUTE_SHADER(EDGE_SENSITIVE_BLUR_1,                          EdgeSensitiveBlur1,                        EDGE_SENSITIVE_BLUR) \
	COMPUTE_SHADER(EDGE_SENSITIVE_BLUR_2,                          EdgeSensitiveBlur2,                        EDGE_SENSITIVE_BLUR) \
	COMPUTE_SHADER(EDGE_SENSITIVE_BLUR_3,                          EdgeSensitiveBlur3,                        EDGE_SENSITIVE_BLUR) \
	COMPUTE_SHADER(EDGE_SENSITIVE_BLUR_4,                          EdgeSensitiveBlur4,                        EDGE_SENSITIVE_BLUR) \
	COMPUTE_SHADER(EDGE_SENSITIVE_BLUR_5,                          EdgeSensitiveBlur5,                        EDGE_SENSITIVE_BLUR) \
	COMPUTE_SHADER(EDGE_SENSITIVE_BLUR_6,                          EdgeSensitiveBlur6,                        EDGE_SENSITIVE_BLUR) \
	COMPUTE_SHADER(EDGE_SENSITIVE_BLUR_7,                          EdgeSensitiveBlur7,                        EDGE_SENSITIVE_BLUR) \
	COMPUTE_SHADER(EDGE_SENSITIVE_BLUR_8,                          EdgeSensitiveBlur8,                        EDGE_SENSITIVE_BLUR) \
	\
	COMPUTE_SHADER(APPLY,                                          Apply,                                     APPLY) \
	COMPUTE_SHADER(NON_SMART_APPLY,                                NonSmartApply,                             APPLY) \
	COMPUTE_SHADER(NON_SMART_HALF_APPLY,                           NonSmartHalfApply,                         APPLY) \
	\
	COMPUTE_SHADER(UPSCALE_BILATERAL_5X5_SMART,                    UpscaleBilateral5x5Smart,                  BILATERAL_UPSAMPLE) \
	COMPUTE_SHADER(UPSCALE_BILATERAL_5X5_NON_SMART,                UpscaleBilateral5x5NonSmart,               BILATERAL_UPSAMPLE) \
	COMPUTE_SHADER(UPSCALE_BILATERAL_5X5_HALF,                     UpscaleBilateral5x5Half,                   BILATERAL_UPSAMPLE)

typedef enum ComputeShaderID {
#define COMPUTE_SHADER(name, _pascal_name, _descriptor_set) CS_##name,
	COMPUTE_SHADERS
#undef COMPUTE_SHADER
	NUM_COMPUTE_SHADERS
} ComputeShaderID;

typedef struct ComputeShaderMetaData {
	const char            *name;
	DescriptorSetLayoutID  descriptorSetLayoutID;
	const char            *objectName;
	const char            *rootSignatureName;
} ComputeShaderMetaData;

typedef struct ComputeShaderSPIRV {
	const uint32_t *spirv;
	size_t          len;
} ComputeShaderSPIRV;

typedef struct ComputeShaderDXIL {
	const void *dxil;
	size_t      len;
} ComputeShaderDXIL;

#ifdef FFX_CACAO_ENABLE_VULKAN
static const ComputeShaderSPIRV COMPUTE_SHADER_SPIRV_32[] = {
#define COMPUTE_SHADER(name, pascal_name, descriptor_set_layout) { (uint32_t*)CS##pascal_name##SPIRV32, FFX_CACAO_ARRAY_SIZE(CS##pascal_name##SPIRV32) },
	COMPUTE_SHADERS
#undef COMPUTE_SHADER
};

static const ComputeShaderSPIRV COMPUTE_SHADER_SPIRV_16[] = {
#define COMPUTE_SHADER(name, pascal_name, descriptor_set_layout) { (uint32_t*)CS##pascal_name##SPIRV16, FFX_CACAO_ARRAY_SIZE(CS##pascal_name##SPIRV16) },
	COMPUTE_SHADERS
#undef COMPUTE_SHADER
};
#endif

static const ComputeShaderMetaData COMPUTE_SHADER_META_DATA[] = {
#define COMPUTE_SHADER(name, pascal_name, descriptor_set_layout) { "FFX_CACAO_"#pascal_name, DSL_##descriptor_set_layout, "FFX_CACAO_CS_"#name, "FFX_CACAO_RS_"#name },
	COMPUTE_SHADERS
#undef COMPUTE_SHADER
};

#ifdef FFX_CACAO_ENABLE_VULKAN
// =================================================================================================
// CACAO vulkan implementation
// =================================================================================================



#define MAX_DESCRIPTOR_BINDINGS 32



#define NUM_BACK_BUFFERS 3
#define NUM_SAMPLERS 5
typedef struct FFX_CACAO_VkContext {
	FFX_CACAO_Settings   settings;
	FFX_CACAO_Bool       useDownsampledSsao;
	FFX_CACAO_BufferSizeInfo     bufferSizeInfo;

#ifdef FFX_CACAO_ENABLE_PROFILING
	VkQueryPool timestampQueryPool;
	uint32_t collectBuffer;
	struct {
		TimestampID timestamps[NUM_TIMESTAMPS];
		uint64_t    timings[NUM_TIMESTAMPS];
		uint32_t    numTimestamps;
	} timestampQueries[NUM_BACK_BUFFERS];
#endif

	VkPhysicalDevice                 physicalDevice;
	VkDevice                         device;
	PFN_vkCmdDebugMarkerBeginEXT     vkCmdDebugMarkerBegin;
	PFN_vkCmdDebugMarkerEndEXT       vkCmdDebugMarkerEnd;
	PFN_vkSetDebugUtilsObjectNameEXT vkSetDebugUtilsObjectName;


	VkDescriptorSetLayout descriptorSetLayouts[NUM_DESCRIPTOR_SET_LAYOUTS];
	VkPipelineLayout      pipelineLayouts[NUM_DESCRIPTOR_SET_LAYOUTS];

	VkShaderModule        computeShaders[NUM_COMPUTE_SHADERS];
	VkPipeline            computePipelines[NUM_COMPUTE_SHADERS];

	VkDescriptorSet       descriptorSets[NUM_BACK_BUFFERS][NUM_DESCRIPTOR_SETS];
	VkDescriptorPool      descriptorPool;

	VkSampler      samplers[NUM_SAMPLERS];

	VkImage        textures[NUM_TEXTURES];
	VkDeviceMemory textureMemory[NUM_TEXTURES];
	VkImageView    shaderResourceViews[NUM_SHADER_RESOURCE_VIEWS];
	VkImageView    unorderedAccessViews[NUM_UNORDERED_ACCESS_VIEWS];

	VkImage        loadCounter;
	VkDeviceMemory loadCounterMemory;
	VkImageView    loadCounterView;

	VkImage        output;

	uint32_t       currentConstantBuffer;
	VkBuffer       constantBuffer[NUM_BACK_BUFFERS][4];
	VkDeviceMemory constantBufferMemory[NUM_BACK_BUFFERS][4];
} FFX_CACAO_VkContext;

static inline FFX_CACAO_VkContext* getAlignedVkContextPointer(FFX_CACAO_VkContext* ptr)
{
	uintptr_t tmp = (uintptr_t)ptr;
	tmp = (tmp + alignof(FFX_CACAO_VkContext) - 1) & (~(alignof(FFX_CACAO_VkContext) - 1));
	return (FFX_CACAO_VkContext*)tmp;
}
#endif

// =================================================================================
// Interface
// =================================================================================

#ifdef __cplusplus
extern "C"
{
#endif

#ifdef FFX_CACAO_ENABLE_VULKAN
inline static void setObjectName(VkDevice device, FFX_CACAO_VkContext* context, VkObjectType type, uint64_t handle, const char* name)
{
	if (!context->vkSetDebugUtilsObjectName)
	{
		return;
	}

	VkDebugUtilsObjectNameInfoEXT info = {};
	info.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT;
	info.pNext = NULL;
	info.objectType = type;
	info.objectHandle = handle;
	info.pObjectName = name;

	VkResult result = context->vkSetDebugUtilsObjectName(device, &info);
	FFX_CACAO_ASSERT(result == VK_SUCCESS);
}

inline static uint32_t getBestMemoryHeapIndex(VkPhysicalDevice physicalDevice,  VkMemoryRequirements memoryRequirements, VkMemoryPropertyFlags desiredProperties)
{
	VkPhysicalDeviceMemoryProperties memoryProperties;
	vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memoryProperties);

	uint32_t chosenMemoryTypeIndex = VK_MAX_MEMORY_TYPES;
	for (uint32_t i = 0; i < memoryProperties.memoryTypeCount; ++i)
	{
		uint32_t typeBit = 1 << i;
		// can we allocate to memory of this type
		if (memoryRequirements.memoryTypeBits & typeBit)
		{
			VkMemoryType currentMemoryType = memoryProperties.memoryTypes[i];
			// do we want to allocate to memory of this type
			if ((currentMemoryType.propertyFlags & desiredProperties) == desiredProperties)
			{
				chosenMemoryTypeIndex = i;
				break;
			}
		}
	}
	return chosenMemoryTypeIndex;
}

size_t FFX_CACAO_VkGetContextSize()
{
	return sizeof(FFX_CACAO_VkContext) + alignof(FFX_CACAO_VkContext) - 1;
}

FFX_CACAO_Status FFX_CACAO_VkInitContext(FFX_CACAO_VkContext* context, const FFX_CACAO_VkCreateInfo* info)
{
	if (context == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	if (info == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	context = getAlignedVkContextPointer(context);
	memset(context, 0, sizeof(*context));

	VkDevice device = info->device;
	VkPhysicalDevice physicalDevice = info->physicalDevice;
	VkResult result;
	FFX_CACAO_Bool use16Bit = info->flags & FFX_CACAO_VK_CREATE_USE_16_BIT ? FFX_CACAO_TRUE : FFX_CACAO_FALSE;
	FFX_CACAO_Status errorStatus = FFX_CACAO_STATUS_FAILED;

	context->device = device;
	context->physicalDevice = physicalDevice;

	if (info->flags & FFX_CACAO_VK_CREATE_USE_DEBUG_MARKERS)
	{
		context->vkCmdDebugMarkerBegin = (PFN_vkCmdDebugMarkerBeginEXT)vkGetDeviceProcAddr(device, "vkCmdDebugMarkerBeginEXT");
		context->vkCmdDebugMarkerEnd = (PFN_vkCmdDebugMarkerEndEXT)vkGetDeviceProcAddr(device, "vkCmdDebugMarkerEndEXT");
	}
	if (info->flags & FFX_CACAO_VK_CREATE_USE_DEBUG_MARKERS)
	{
		context->vkSetDebugUtilsObjectName = (PFN_vkSetDebugUtilsObjectNameEXT)vkGetDeviceProcAddr(device, "vkSetDebugUtilsObjectNameEXT");
	}

	uint32_t numSamplersInited = 0;
	uint32_t numDescriptorSetLayoutsInited = 0;
	uint32_t numPipelineLayoutsInited = 0;
	uint32_t numShaderModulesInited = 0;
	uint32_t numPipelinesInited = 0;
	uint32_t numConstantBackBuffersInited = 0;

	VkSampler samplers[NUM_SAMPLERS];
	{
		VkSamplerCreateInfo samplerCreateInfo = {};
		samplerCreateInfo.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
		samplerCreateInfo.pNext = NULL;
		samplerCreateInfo.flags = 0;
		samplerCreateInfo.magFilter = VK_FILTER_LINEAR;
		samplerCreateInfo.minFilter = VK_FILTER_LINEAR;
		samplerCreateInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_NEAREST;
		samplerCreateInfo.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
		samplerCreateInfo.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
		samplerCreateInfo.addressModeW = VK_SAMPLER_ADDRESS_MODE_REPEAT;
		samplerCreateInfo.mipLodBias = 0.0f;
		samplerCreateInfo.anisotropyEnable = VK_FALSE;
		samplerCreateInfo.compareEnable = VK_FALSE;
		samplerCreateInfo.minLod = -1000.0f;
		samplerCreateInfo.maxLod = 1000.0f;
		samplerCreateInfo.unnormalizedCoordinates = VK_FALSE;

		result = vkCreateSampler(device, &samplerCreateInfo, NULL, &samplers[numSamplersInited]);
		if (result != VK_SUCCESS)
		{
			goto error_init_samplers;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_SAMPLER, (uint64_t)samplers[numSamplersInited], "FFX_CACAO_POINT_CLAMP_SAMPLER");
		++numSamplersInited;

		samplerCreateInfo.addressModeU = VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
		samplerCreateInfo.addressModeV = VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
		samplerCreateInfo.addressModeW = VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;

		result = vkCreateSampler(device, &samplerCreateInfo, NULL, &samplers[numSamplersInited]);
		if (result != VK_SUCCESS)
		{
			goto error_init_samplers;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_SAMPLER, (uint64_t)samplers[numSamplersInited], "FFX_CACAO_POINT_MIRROR_SAMPLER");
		++numSamplersInited;

		samplerCreateInfo.magFilter = VK_FILTER_LINEAR;
		samplerCreateInfo.minFilter = VK_FILTER_LINEAR;
		samplerCreateInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
		samplerCreateInfo.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
		samplerCreateInfo.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
		samplerCreateInfo.addressModeW = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;

		result = vkCreateSampler(device, &samplerCreateInfo, NULL, &samplers[numSamplersInited]);
		if (result != VK_SUCCESS)
		{
			goto error_init_samplers;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_SAMPLER, (uint64_t)samplers[numSamplersInited], "FFX_CACAO_LINEAR_CLAMP_SAMPLER");
		++numSamplersInited;

		samplerCreateInfo.magFilter = VK_FILTER_NEAREST;
		samplerCreateInfo.minFilter = VK_FILTER_NEAREST;
		samplerCreateInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_NEAREST;

		result = vkCreateSampler(device, &samplerCreateInfo, NULL, &samplers[numSamplersInited]);
		if (result != VK_SUCCESS)
		{
			goto error_init_samplers;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_SAMPLER, (uint64_t)samplers[numSamplersInited], "FFX_CACAO_VIEWSPACE_DEPTH_TAP_SAMPLER");
		++numSamplersInited;

		samplerCreateInfo.magFilter = VK_FILTER_NEAREST;
		samplerCreateInfo.minFilter = VK_FILTER_NEAREST;
		samplerCreateInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_NEAREST;
		samplerCreateInfo.addressModeU = VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
		samplerCreateInfo.addressModeV = VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
		samplerCreateInfo.addressModeW = VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;

		result = vkCreateSampler(device, &samplerCreateInfo, NULL, &samplers[numSamplersInited]);
		if (result != VK_SUCCESS)
		{
			goto error_init_samplers;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_SAMPLER, (uint64_t)samplers[numSamplersInited], "FFX_CACAO_REAL_POINT_CLAMP_SAMPLER");
		++numSamplersInited;

		for (uint32_t i = 0; i < FFX_CACAO_ARRAY_SIZE(samplers); ++i)
		{
			context->samplers[i] = samplers[i];
		}
	}

	// create descriptor set layouts
	for ( ; numDescriptorSetLayoutsInited < NUM_DESCRIPTOR_SET_LAYOUTS; ++numDescriptorSetLayoutsInited)
	{
		VkDescriptorSetLayout descriptorSetLayout;
		DescriptorSetLayoutMetaData dslMetaData = DESCRIPTOR_SET_LAYOUT_META_DATA[numDescriptorSetLayoutsInited];

		VkDescriptorSetLayoutBinding bindings[MAX_DESCRIPTOR_BINDINGS] = {};
		uint32_t numBindings = 0;
		for (uint32_t samplerBinding = 0; samplerBinding < FFX_CACAO_ARRAY_SIZE(samplers); ++samplerBinding)
		{
			VkDescriptorSetLayoutBinding binding = {};
			binding.binding = samplerBinding;
			binding.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLER;
			binding.descriptorCount = 1;
			binding.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
			binding.pImmutableSamplers = &samplers[samplerBinding];
			bindings[numBindings++] = binding;
		}

		// constant buffer binding
		{
			VkDescriptorSetLayoutBinding binding = {};
			binding.binding = 10;
			binding.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
			binding.descriptorCount = 1;
			binding.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
			binding.pImmutableSamplers = NULL;
			bindings[numBindings++] = binding;
		}

		for (uint32_t inputBinding = 0; inputBinding < dslMetaData.numInputs; ++inputBinding)
		{
			VkDescriptorSetLayoutBinding binding = {};
			binding.binding = 20 + inputBinding;
			binding.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
			binding.descriptorCount = 1;
			binding.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
			binding.pImmutableSamplers = NULL;
			bindings[numBindings++] = binding;
		}

		for (uint32_t outputBinding = 0; outputBinding < dslMetaData.numOutputs; ++outputBinding)
		{
			VkDescriptorSetLayoutBinding binding = {};
			binding.binding = 30 + outputBinding; // g_PrepareDepthsOut register(u0)
			binding.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
			binding.descriptorCount = 1;
			binding.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
			binding.pImmutableSamplers = NULL;
			bindings[numBindings++] = binding;
		}

		VkDescriptorSetLayoutCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.bindingCount = numBindings;
		info.pBindings = bindings;

		result = vkCreateDescriptorSetLayout(device, &info, NULL, &descriptorSetLayout);
		if (result != VK_SUCCESS)
		{
			goto error_init_descriptor_set_layouts;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT, (uint64_t)descriptorSetLayout, dslMetaData.name);

		context->descriptorSetLayouts[numDescriptorSetLayoutsInited] = descriptorSetLayout;
	}

	// create pipeline layouts
	for ( ; numPipelineLayoutsInited < NUM_DESCRIPTOR_SET_LAYOUTS; ++numPipelineLayoutsInited)
	{
		VkPipelineLayout pipelineLayout;

		DescriptorSetLayoutMetaData dslMetaData = DESCRIPTOR_SET_LAYOUT_META_DATA[numPipelineLayoutsInited];

		VkPipelineLayoutCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.setLayoutCount = 1;
		info.pSetLayouts = &context->descriptorSetLayouts[numPipelineLayoutsInited];
		info.pushConstantRangeCount = 0;
		info.pPushConstantRanges = NULL;

		result = vkCreatePipelineLayout(device, &info, NULL, &pipelineLayout);
		if (result != VK_SUCCESS)
		{
			goto error_init_pipeline_layouts;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_PIPELINE_LAYOUT, (uint64_t)pipelineLayout, dslMetaData.name);

		context->pipelineLayouts[numPipelineLayoutsInited] = pipelineLayout;
	}

	for ( ; numShaderModulesInited < NUM_COMPUTE_SHADERS; ++numShaderModulesInited)
	{
		VkShaderModule shaderModule;
		ComputeShaderMetaData csMetaData = COMPUTE_SHADER_META_DATA[numShaderModulesInited];

		VkShaderModuleCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
		info.pNext = 0;
		info.flags = 0;
		ComputeShaderSPIRV spirv = use16Bit ? COMPUTE_SHADER_SPIRV_16[numShaderModulesInited] : COMPUTE_SHADER_SPIRV_32[numShaderModulesInited];
		info.codeSize = spirv.len;
		info.pCode = spirv.spirv;

		result = vkCreateShaderModule(device, &info, NULL, &shaderModule);
		if (result != VK_SUCCESS)
		{
			goto error_init_shader_modules;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_SHADER_MODULE, (uint64_t)shaderModule, csMetaData.objectName);

		context->computeShaders[numShaderModulesInited] = shaderModule;
	}

	for ( ; numPipelinesInited < NUM_COMPUTE_SHADERS; ++numPipelinesInited)
	{
		VkPipeline pipeline;
		ComputeShaderMetaData csMetaData = COMPUTE_SHADER_META_DATA[numPipelinesInited];

		VkPipelineShaderStageCreateInfo stageInfo = {};
		stageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		stageInfo.pNext = NULL;
		stageInfo.flags = 0;
		stageInfo.stage = VK_SHADER_STAGE_COMPUTE_BIT;
		stageInfo.module = context->computeShaders[numPipelinesInited];
		stageInfo.pName = csMetaData.name;
		stageInfo.pSpecializationInfo = NULL;

		VkComputePipelineCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.stage = stageInfo;
		info.layout = context->pipelineLayouts[csMetaData.descriptorSetLayoutID];
		info.basePipelineHandle = VK_NULL_HANDLE;
		info.basePipelineIndex = 0;

		result = vkCreateComputePipelines(device, VK_NULL_HANDLE, 1, &info, NULL, &pipeline);
		if (result != VK_SUCCESS)
		{
			goto error_init_pipelines;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_PIPELINE, (uint64_t)pipeline, csMetaData.objectName);

		context->computePipelines[numPipelinesInited] = pipeline;
	}

	// create descriptor pool
	{
		VkDescriptorPool descriptorPool;

		VkDescriptorPoolSize poolSizes[4] = {};
		poolSizes[0].type = VK_DESCRIPTOR_TYPE_SAMPLER;
		poolSizes[0].descriptorCount = NUM_BACK_BUFFERS * NUM_DESCRIPTOR_SETS * 5;
		poolSizes[1].type = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		poolSizes[1].descriptorCount = NUM_BACK_BUFFERS * NUM_DESCRIPTOR_SETS * 7;
		poolSizes[2].type = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		poolSizes[2].descriptorCount = NUM_BACK_BUFFERS * NUM_DESCRIPTOR_SETS * 4;
		poolSizes[3].type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
		poolSizes[3].descriptorCount = NUM_BACK_BUFFERS * NUM_DESCRIPTOR_SETS * 1;

		VkDescriptorPoolCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.maxSets = NUM_BACK_BUFFERS * NUM_DESCRIPTOR_SETS;
		info.poolSizeCount = FFX_CACAO_ARRAY_SIZE(poolSizes);
		info.pPoolSizes = poolSizes;

		result = vkCreateDescriptorPool(device, &info, NULL, &descriptorPool);
		if (result != VK_SUCCESS)
		{
			goto error_init_descriptor_pool;
		}
		setObjectName(device, context, VK_OBJECT_TYPE_DESCRIPTOR_POOL, (uint64_t)descriptorPool, "FFX_CACAO_DESCRIPTOR_POOL");

		context->descriptorPool = descriptorPool;
	}

	// allocate descriptor sets
	{
		VkDescriptorSetLayout descriptorSetLayouts[NUM_DESCRIPTOR_SETS];
		for (uint32_t i = 0; i < NUM_DESCRIPTOR_SETS; ++i) {
			descriptorSetLayouts[i] = context->descriptorSetLayouts[DESCRIPTOR_SET_META_DATA[i].descriptorSetLayoutID];
		}

		for (uint32_t i = 0; i < NUM_BACK_BUFFERS; ++i) {
			VkDescriptorSetAllocateInfo info = {};
			info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
			info.pNext = NULL;
			info.descriptorPool = context->descriptorPool;
			info.descriptorSetCount = FFX_CACAO_ARRAY_SIZE(descriptorSetLayouts); // FFX_CACAO_ARRAY_SIZE(context->descriptorSetLayouts);
			info.pSetLayouts = descriptorSetLayouts; // context->descriptorSetLayouts;

			result = vkAllocateDescriptorSets(device, &info, context->descriptorSets[i]);
			if (result != VK_SUCCESS)
			{
				goto error_allocate_descriptor_sets;
			}
		}

		char name[1024];
		for (uint32_t j = 0; j < NUM_BACK_BUFFERS; ++j) {
			for (uint32_t i = 0; i < NUM_DESCRIPTOR_SETS; ++i) {
				DescriptorSetMetaData dsMetaData = DESCRIPTOR_SET_META_DATA[i];
				snprintf(name, FFX_CACAO_ARRAY_SIZE(name), "%s_%u", dsMetaData.name, j);
				setObjectName(device, context, VK_OBJECT_TYPE_DESCRIPTOR_SET, (uint64_t)context->descriptorSets[j][i], name);
			}
		}
	}

	// assign memory to constant buffers
	for ( ; numConstantBackBuffersInited < NUM_BACK_BUFFERS; ++numConstantBackBuffersInited)
	{
		for (uint32_t j = 0; j < 4; ++j)
		{
			VkBuffer buffer = context->constantBuffer[numConstantBackBuffersInited][j];

			VkBufferCreateInfo info = {};
			info.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			info.pNext = NULL;
			info.flags = 0;
			info.size = sizeof(FFX_CACAO_Constants);
			info.usage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
			info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
			info.queueFamilyIndexCount = 0;
			info.pQueueFamilyIndices = NULL;

			result = vkCreateBuffer(device, &info, NULL, &buffer);
			if (result != VK_SUCCESS)
			{
				goto error_init_constant_buffers;
			}
			char name[1024];
			snprintf(name, FFX_CACAO_ARRAY_SIZE(name), "FFX_CACAO_CONSTANT_BUFFER_PASS_%u_BACK_BUFFER_%u", j, numConstantBackBuffersInited);
			setObjectName(device, context, VK_OBJECT_TYPE_BUFFER, (uint64_t)buffer, name);

			VkMemoryRequirements memoryRequirements;
			vkGetBufferMemoryRequirements(device, buffer, &memoryRequirements);

			uint32_t chosenMemoryTypeIndex = getBestMemoryHeapIndex(physicalDevice, memoryRequirements, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
			if (chosenMemoryTypeIndex == VK_MAX_MEMORY_TYPES)
			{
				vkDestroyBuffer(device, buffer, NULL);
				goto error_init_constant_buffers;
			}

			VkMemoryAllocateInfo allocationInfo = {};
			allocationInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
			allocationInfo.pNext = NULL;
			allocationInfo.allocationSize = memoryRequirements.size;
			allocationInfo.memoryTypeIndex = chosenMemoryTypeIndex;

			VkDeviceMemory memory;
			result = vkAllocateMemory(device, &allocationInfo, NULL, &memory);
			if (result != VK_SUCCESS)
			{
				vkDestroyBuffer(device, buffer, NULL);
				goto error_init_constant_buffers;
			}

			result = vkBindBufferMemory(device, buffer, memory, 0);
			if (result != VK_SUCCESS)
			{
				vkDestroyBuffer(device, buffer, NULL);
				goto error_init_constant_buffers;
			}

			context->constantBufferMemory[numConstantBackBuffersInited][j] = memory;
			context->constantBuffer[numConstantBackBuffersInited][j] = buffer;
		}
	}

	// create load counter VkImage
	{
		VkImage image = VK_NULL_HANDLE;

		VkImageCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.imageType = VK_IMAGE_TYPE_1D;
		info.format = VK_FORMAT_R32_UINT;
		info.extent.width = 1;
		info.extent.height = 1;
		info.extent.depth = 1;
		info.mipLevels = 1;
		info.arrayLayers = 1;
		info.samples = VK_SAMPLE_COUNT_1_BIT;
		info.tiling = VK_IMAGE_TILING_OPTIMAL;
		info.usage = VK_IMAGE_USAGE_STORAGE_BIT | VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
		info.queueFamilyIndexCount = 0;
		info.pQueueFamilyIndices = NULL;
		info.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;

		result = vkCreateImage(device, &info, NULL, &image);
		if (result != VK_SUCCESS)
		{
			goto error_init_load_counter_image;
		}

		setObjectName(device, context, VK_OBJECT_TYPE_IMAGE, (uint64_t)image, "FFX_CACAO_LOAD_COUNTER");

		VkMemoryRequirements memoryRequirements;
		vkGetImageMemoryRequirements(device, image, &memoryRequirements);

		uint32_t chosenMemoryTypeIndex = getBestMemoryHeapIndex(physicalDevice, memoryRequirements, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
		if (chosenMemoryTypeIndex == VK_MAX_MEMORY_TYPES)
		{
			vkDestroyImage(device, image, NULL);
			goto error_init_load_counter_image;
		}

		VkMemoryAllocateInfo allocationInfo = {};
		allocationInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		allocationInfo.pNext = NULL;
		allocationInfo.allocationSize = memoryRequirements.size;
		allocationInfo.memoryTypeIndex = chosenMemoryTypeIndex;

		VkDeviceMemory memory;
		result = vkAllocateMemory(device, &allocationInfo, NULL, &memory);
		if (result != VK_SUCCESS)
		{
			vkDestroyImage(device, image, NULL);
			goto error_init_load_counter_image;
		}

		result = vkBindImageMemory(device, image, memory, 0);
		if (result != VK_SUCCESS)
		{
			vkDestroyImage(device, image, NULL);
			goto error_init_load_counter_image;
		}

		context->loadCounter = image;
		context->loadCounterMemory = memory;
	}

	// create load counter view
	{
		VkImageView imageView;

		VkImageViewCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.image = context->loadCounter;
		info.viewType = VK_IMAGE_VIEW_TYPE_1D;
		info.format = VK_FORMAT_R32_UINT;
		info.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		info.subresourceRange.baseMipLevel = 0;
		info.subresourceRange.levelCount = 1;
		info.subresourceRange.baseArrayLayer = 0;
		info.subresourceRange.layerCount = 1;

		result = vkCreateImageView(device, &info, NULL, &imageView);
		if (result != VK_SUCCESS)
		{
			goto error_init_load_counter_view;
		}

		context->loadCounterView = imageView;
	}

#ifdef FFX_CACAO_ENABLE_PROFILING
	// create timestamp query pool
	{
		VkQueryPool queryPool = VK_NULL_HANDLE;

		VkQueryPoolCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.queryType = VK_QUERY_TYPE_TIMESTAMP;
		info.queryCount = NUM_TIMESTAMPS * NUM_BACK_BUFFERS;

		result = vkCreateQueryPool(device, &info, NULL, &queryPool);
		if (result != VK_SUCCESS)
		{
			goto error_init_query_pool;
		}

		context->timestampQueryPool = queryPool;
	}
#endif

	return FFX_CACAO_STATUS_OK;

#ifdef FFX_CACAO_ENABLE_PROFILING
	vkDestroyQueryPool(device, context->timestampQueryPool, NULL);
error_init_query_pool:
#endif

	vkDestroyImageView(device, context->loadCounterView, NULL);
error_init_load_counter_view:
	vkDestroyImage(device, context->loadCounter, NULL);
	vkFreeMemory(device, context->loadCounterMemory, NULL);
error_init_load_counter_image:

error_init_constant_buffers:
	for (uint32_t i = 0; i < numConstantBackBuffersInited; ++i)
	{
		for (uint32_t j = 0; j < 4; ++j)
		{
			vkDestroyBuffer(device, context->constantBuffer[i][j], NULL);
			vkFreeMemory(device, context->constantBufferMemory[i][j], NULL);
		}
	}
	
error_allocate_descriptor_sets:
	vkDestroyDescriptorPool(device, context->descriptorPool, NULL);
error_init_descriptor_pool:

error_init_pipelines:
	for (uint32_t i = 0; i < numPipelinesInited; ++i)
	{
		vkDestroyPipeline(device, context->computePipelines[i], NULL);
	}

error_init_shader_modules:
	for (uint32_t i = 0; i < numShaderModulesInited; ++i)
	{
		vkDestroyShaderModule(device, context->computeShaders[i], NULL);
	}

error_init_pipeline_layouts:
	for (uint32_t i = 0; i < numPipelineLayoutsInited; ++i)
	{
		vkDestroyPipelineLayout(device, context->pipelineLayouts[i], NULL);
	}

error_init_descriptor_set_layouts:
	for (uint32_t i = 0; i < numDescriptorSetLayoutsInited; ++i)
	{
		vkDestroyDescriptorSetLayout(device, context->descriptorSetLayouts[i], NULL);
	}


error_init_samplers:
	for (uint32_t i = 0; i < numSamplersInited; ++i)
	{
		vkDestroySampler(device, context->samplers[i], NULL);
	}

	return errorStatus;
}

FFX_CACAO_Status FFX_CACAO_VkDestroyContext(FFX_CACAO_VkContext* context)
{
	if (context == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	context = getAlignedVkContextPointer(context);

	VkDevice device = context->device;

#ifdef FFX_CACAO_ENABLE_PROFILING
	vkDestroyQueryPool(device, context->timestampQueryPool, NULL);
#endif

	vkDestroyImageView(device, context->loadCounterView, NULL);
	vkDestroyImage(device, context->loadCounter, NULL);
	vkFreeMemory(device, context->loadCounterMemory, NULL);

	for (uint32_t i = 0; i < NUM_BACK_BUFFERS; ++i)
	{
		for (uint32_t j = 0; j < 4; ++j)
		{
			vkDestroyBuffer(device, context->constantBuffer[i][j], NULL);
			vkFreeMemory(device, context->constantBufferMemory[i][j], NULL);
		}
	}

	vkDestroyDescriptorPool(device, context->descriptorPool, NULL);

	for (uint32_t i = 0; i < NUM_COMPUTE_SHADERS; ++i)
	{
		vkDestroyPipeline(device, context->computePipelines[i], NULL);
	}

	for (uint32_t i = 0; i < NUM_COMPUTE_SHADERS; ++i)
	{
		vkDestroyShaderModule(device, context->computeShaders[i], NULL);
	}

	for (uint32_t i = 0; i < NUM_DESCRIPTOR_SET_LAYOUTS; ++i)
	{
		vkDestroyPipelineLayout(device, context->pipelineLayouts[i], NULL);
	}

	for(uint32_t i = 0; i < NUM_DESCRIPTOR_SET_LAYOUTS; ++i)
	{
		vkDestroyDescriptorSetLayout(device, context->descriptorSetLayouts[i], NULL);
	}


	for (uint32_t i = 0; i < FFX_CACAO_ARRAY_SIZE(context->samplers); ++i)
	{
		vkDestroySampler(device, context->samplers[i], NULL);
	}

	return FFX_CACAO_STATUS_OK;
}

FFX_CACAO_Status FFX_CACAO_VkInitScreenSizeDependentResources(FFX_CACAO_VkContext* context, const FFX_CACAO_VkScreenSizeInfo* info)
{
	if (context == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	if (info == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	context = getAlignedVkContextPointer(context);

	FFX_CACAO_Bool useDownsampledSsao = info->useDownsampledSsao;
	context->useDownsampledSsao = useDownsampledSsao;
	context->output = info->output;

	VkDevice device = context->device;
	VkPhysicalDevice physicalDevice = context->physicalDevice;
	VkPhysicalDeviceMemoryProperties memoryProperties;
	vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memoryProperties);
	VkResult result;

	FFX_CACAO_BufferSizeInfo *bsi = &context->bufferSizeInfo;
	FFX_CACAO_UpdateBufferSizeInfo(info->width, info->height, useDownsampledSsao, bsi);

	FFX_CACAO_Status errorStatus = FFX_CACAO_STATUS_FAILED;
	uint32_t numTextureImagesInited = 0;
	uint32_t numTextureMemoriesInited = 0;
	uint32_t numSrvsInited = 0;
	uint32_t numUavsInited = 0;

	// create images for textures
	for ( ; numTextureImagesInited < NUM_TEXTURES; ++numTextureImagesInited)
	{
		TextureMetaData metaData = TEXTURE_META_DATA[numTextureImagesInited];
		VkImage image = VK_NULL_HANDLE;

		VkImageCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.imageType = VK_IMAGE_TYPE_2D;
		info.format = TEXTURE_FORMAT_LOOKUP_VK[metaData.format];
		info.extent.width = *(uint32_t*)((uint8_t*)bsi + metaData.widthOffset);
		info.extent.height = *(uint32_t*)((uint8_t*)bsi + metaData.heightOffset);
		info.extent.depth = 1;
		info.mipLevels = metaData.numMips;
		info.arrayLayers = metaData.arraySize;
		info.samples = VK_SAMPLE_COUNT_1_BIT;
		info.tiling = VK_IMAGE_TILING_OPTIMAL;
		info.usage = VK_IMAGE_USAGE_STORAGE_BIT | VK_IMAGE_USAGE_SAMPLED_BIT;
		info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
		info.queueFamilyIndexCount = 0;
		info.pQueueFamilyIndices = NULL;
		info.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;

		result = vkCreateImage(device, &info, NULL, &image);
		if (result != VK_SUCCESS)
		{
			goto error_init_texture_images;
		}

		setObjectName(device, context, VK_OBJECT_TYPE_IMAGE, (uint64_t)image, metaData.name);

		context->textures[numTextureImagesInited] = image;
	}

	// allocate memory for textures
	for ( ; numTextureMemoriesInited < NUM_TEXTURES; ++numTextureMemoriesInited)
	{
		VkImage image = context->textures[numTextureMemoriesInited];

		VkMemoryRequirements memoryRequirements;
		vkGetImageMemoryRequirements(device, image, &memoryRequirements);

		uint32_t chosenMemoryTypeIndex = getBestMemoryHeapIndex(physicalDevice, memoryRequirements, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
		if (chosenMemoryTypeIndex == VK_MAX_MEMORY_TYPES)
		{
			goto error_init_texture_memories;
		}

		VkMemoryAllocateInfo allocationInfo = {};
		allocationInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		allocationInfo.pNext = NULL;
		allocationInfo.allocationSize = memoryRequirements.size;
		allocationInfo.memoryTypeIndex = chosenMemoryTypeIndex;

		VkDeviceMemory memory;
		result = vkAllocateMemory(device, &allocationInfo, NULL, &memory);
		if (result != VK_SUCCESS)
		{
			goto error_init_texture_memories;
		}

		result = vkBindImageMemory(device, image, memory, 0);
		if (result != VK_SUCCESS)
		{
			vkFreeMemory(device, memory, NULL);
			goto  error_init_texture_memories;
		}

		context->textureMemory[numTextureMemoriesInited] = memory;
	}

	// create srv image views
	for ( ; numSrvsInited < NUM_SHADER_RESOURCE_VIEWS; ++numSrvsInited)
	{
		VkImageView imageView;
		ShaderResourceViewMetaData srvMetaData = SRV_META_DATA[numSrvsInited];

		VkImageViewCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.image = context->textures[srvMetaData.texture];
		info.viewType = VIEW_TYPE_LOOKUP_VK[srvMetaData.viewType];
		info.format = TEXTURE_FORMAT_LOOKUP_VK[TEXTURE_META_DATA[srvMetaData.texture].format];
		info.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		info.subresourceRange.baseMipLevel = srvMetaData.mostDetailedMip;
		info.subresourceRange.levelCount = srvMetaData.mipLevels;
		info.subresourceRange.baseArrayLayer = srvMetaData.firstArraySlice;
		info.subresourceRange.layerCount = srvMetaData.arraySize;

		result = vkCreateImageView(device, &info, NULL, &imageView);
		if (result != VK_SUCCESS)
		{
			goto error_init_srvs;
		}

		context->shaderResourceViews[numSrvsInited] = imageView;
	}

	// create uav image views
	for ( ; numUavsInited < NUM_UNORDERED_ACCESS_VIEWS; ++numUavsInited)
	{
		VkImageView imageView;
		UnorderedAccessViewMetaData uavMetaData = UAV_META_DATA[numUavsInited];

		VkImageViewCreateInfo info = {};
		info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		info.pNext = NULL;
		info.flags = 0;
		info.image = context->textures[uavMetaData.textureID];
		info.viewType = VIEW_TYPE_LOOKUP_VK[uavMetaData.viewType];
		info.format = TEXTURE_FORMAT_LOOKUP_VK[TEXTURE_META_DATA[uavMetaData.textureID].format];
		info.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
		info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		info.subresourceRange.baseMipLevel = uavMetaData.mostDetailedMip;
		info.subresourceRange.levelCount = 1;
		info.subresourceRange.baseArrayLayer = uavMetaData.firstArraySlice;
		info.subresourceRange.layerCount = uavMetaData.arraySize;

		result = vkCreateImageView(device, &info, NULL, &imageView);
		if (result != VK_SUCCESS)
		{
			goto error_init_uavs;
		}

		context->unorderedAccessViews[numUavsInited] = imageView;
	}

	// update descriptor sets from table
	for (uint32_t i = 0; i < NUM_BACK_BUFFERS; ++i) {
		VkDescriptorImageInfo  imageInfos[NUM_INPUT_DESCRIPTOR_BINDINGS + NUM_OUTPUT_DESCRIPTOR_BINDINGS] = {};
		VkDescriptorImageInfo *curImageInfo = imageInfos;
		VkWriteDescriptorSet   writes[NUM_INPUT_DESCRIPTOR_BINDINGS + NUM_OUTPUT_DESCRIPTOR_BINDINGS] = {};
		VkWriteDescriptorSet  *curWrite = writes;
		
		// write input descriptor bindings
		for (uint32_t j = 0; j < NUM_INPUT_DESCRIPTOR_BINDINGS; ++j)
		{
			InputDescriptorBindingMetaData bindingMetaData = INPUT_DESCRIPTOR_BINDING_META_DATA[j];

			curImageInfo->sampler = VK_NULL_HANDLE;
			curImageInfo->imageView = context->shaderResourceViews[bindingMetaData.srvID];
			curImageInfo->imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;

			curWrite->sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
			curWrite->pNext = NULL;
			curWrite->dstSet = context->descriptorSets[i][bindingMetaData.descriptorID];
			curWrite->dstBinding = 20 + bindingMetaData.bindingNumber;
			curWrite->descriptorCount = 1;
			curWrite->descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
			curWrite->pImageInfo = curImageInfo;

			++curWrite; ++curImageInfo;
		}

		// write output descriptor bindings
		for (uint32_t j = 0; j < NUM_OUTPUT_DESCRIPTOR_BINDINGS; ++j)
		{
			OutputDescriptorBindingMetaData bindingMetaData = OUTPUT_DESCRIPTOR_BINDING_META_DATA[j];

			curImageInfo->sampler = VK_NULL_HANDLE;
			curImageInfo->imageView = context->unorderedAccessViews[bindingMetaData.uavID];
			curImageInfo->imageLayout = VK_IMAGE_LAYOUT_GENERAL;

			curWrite->sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
			curWrite->pNext = VK_NULL_HANDLE;
			curWrite->dstSet = context->descriptorSets[i][bindingMetaData.descriptorID];
			curWrite->dstBinding = 30 + bindingMetaData.bindingNumber;
			curWrite->descriptorCount = 1;
			curWrite->descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
			curWrite->pImageInfo = curImageInfo;

			++curWrite; ++curImageInfo;
		}

		vkUpdateDescriptorSets(device, FFX_CACAO_ARRAY_SIZE(writes), writes, 0, NULL);
	}

	// update descriptor sets with inputs
	for (uint32_t i = 0; i < NUM_BACK_BUFFERS; ++i) {
#define MAX_NUM_MISC_INPUT_DESCRIPTORS 32

		VkDescriptorImageInfo imageInfos[MAX_NUM_MISC_INPUT_DESCRIPTORS] = {};
		VkWriteDescriptorSet writes[MAX_NUM_MISC_INPUT_DESCRIPTORS] = {};

		for (uint32_t i = 0; i < FFX_CACAO_ARRAY_SIZE(writes); ++i)
		{
			VkDescriptorImageInfo *imageInfo = imageInfos + i;
			VkWriteDescriptorSet *write = writes + i;

			imageInfo->sampler = VK_NULL_HANDLE;

			write->sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
			write->pNext = NULL;
			write->descriptorCount = 1;
			write->pImageInfo = imageInfo;
		}

		uint32_t cur = 0;

		// register(t0) -> 20
		// register(u0) -> 30
		imageInfos[cur].imageView = info->depthView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_PREPARE_DEPTHS];
		writes[cur].dstBinding = 20;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		++cur;

		imageInfos[cur].imageView = info->depthView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_PREPARE_DEPTHS_MIPS];
		writes[cur].dstBinding = 20;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		++cur;

		imageInfos[cur].imageView = info->depthView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_PREPARE_NORMALS];
		writes[cur].dstBinding = 20;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		++cur;

		imageInfos[cur].imageView = info->depthView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_BILATERAL_UPSAMPLE_PING];
		writes[cur].dstBinding = 21;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		++cur;

		imageInfos[cur].imageView = info->depthView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_BILATERAL_UPSAMPLE_PONG];
		writes[cur].dstBinding = 21;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
		++cur;

		imageInfos[cur].imageView = info->outputView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_GENERAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_BILATERAL_UPSAMPLE_PING];
		writes[cur].dstBinding = 30;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		++cur;

		imageInfos[cur].imageView = info->outputView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_GENERAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_BILATERAL_UPSAMPLE_PONG];
		writes[cur].dstBinding = 30;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		++cur;

		imageInfos[cur].imageView = info->outputView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_GENERAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_APPLY_PING];
		writes[cur].dstBinding = 30;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		++cur;

		imageInfos[cur].imageView = info->outputView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_GENERAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_APPLY_PONG];
		writes[cur].dstBinding = 30;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		++cur;

		imageInfos[cur].imageView = context->loadCounterView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_GENERAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_POSTPROCESS_IMPORTANCE_MAP_B];
		writes[cur].dstBinding = 31;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		++cur;

		imageInfos[cur].imageView = context->loadCounterView;
		imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_GENERAL;
		writes[cur].dstSet = context->descriptorSets[i][DS_CLEAR_LOAD_COUNTER];
		writes[cur].dstBinding = 30;
		writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
		++cur;

		for (uint32_t pass = 0; pass < 4; ++pass)
		{
			imageInfos[cur].imageView = context->loadCounterView;
			imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_GENERAL;
			writes[cur].dstSet = context->descriptorSets[i][(DescriptorSetID)(DS_GENERATE_ADAPTIVE_0 + pass)];
			writes[cur].dstBinding = 22;
			writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
			++cur;
		}

		if (info->normalsView) {
			imageInfos[cur].imageView = info->normalsView;
			imageInfos[cur].imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
			writes[cur].dstSet = context->descriptorSets[i][DS_PREPARE_NORMALS_FROM_INPUT_NORMALS];
			writes[cur].dstBinding = 20;
			writes[cur].descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
			++cur;
		}

		FFX_CACAO_ASSERT(cur <= MAX_NUM_MISC_INPUT_DESCRIPTORS);
		vkUpdateDescriptorSets(device, cur, writes, 0, NULL);
	}

	// update descriptor sets with constant buffers
	for (uint32_t i = 0; i < NUM_BACK_BUFFERS; ++i) {
		VkDescriptorBufferInfo  bufferInfos[NUM_DESCRIPTOR_SETS] = {};
		VkDescriptorBufferInfo *curBufferInfo = bufferInfos;
		VkWriteDescriptorSet    writes[NUM_DESCRIPTOR_SETS] = {};
		VkWriteDescriptorSet   *curWrite = writes;

		for (uint32_t j = 0; j < NUM_DESCRIPTOR_SETS; ++j)
		{
			DescriptorSetMetaData dsMetaData = DESCRIPTOR_SET_META_DATA[j];

			curBufferInfo->buffer = context->constantBuffer[i][dsMetaData.pass];
			curBufferInfo->offset = 0;
			curBufferInfo->range = VK_WHOLE_SIZE;

			curWrite->sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
			curWrite->pNext = NULL;
			curWrite->dstSet = context->descriptorSets[i][j];
			curWrite->dstBinding = 10;
			curWrite->dstArrayElement = 0;
			curWrite->descriptorCount = 1;
			curWrite->descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
			curWrite->pBufferInfo = curBufferInfo;

			++curWrite;
			++curBufferInfo;
		}

		vkUpdateDescriptorSets(device, FFX_CACAO_ARRAY_SIZE(writes), writes, 0, NULL);
	}

	return FFX_CACAO_STATUS_OK;

error_init_uavs:
	for (uint32_t i = 0; i < numUavsInited; ++i)
	{
		vkDestroyImageView(device, context->unorderedAccessViews[i], NULL);
	}

error_init_srvs:
	for (uint32_t i = 0; i < numSrvsInited; ++i)
	{
		vkDestroyImageView(device, context->shaderResourceViews[i], NULL);
	}

error_init_texture_memories:
	for (uint32_t i = 0; i < numTextureMemoriesInited; ++i)
	{
		vkFreeMemory(device, context->textureMemory[i], NULL);
	}

error_init_texture_images:
	for (uint32_t i = 0; i < numTextureImagesInited; ++i)
	{
		vkDestroyImage(device, context->textures[i], NULL);
	}

	return errorStatus;
}

FFX_CACAO_Status FFX_CACAO_VkDestroyScreenSizeDependentResources(FFX_CACAO_VkContext* context)
{
	if (context == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	context = getAlignedVkContextPointer(context);

	VkDevice device = context->device;

	for (uint32_t i = 0; i < NUM_UNORDERED_ACCESS_VIEWS; ++i)
	{
		vkDestroyImageView(device, context->unorderedAccessViews[i], NULL);
	}

	for (uint32_t i = 0; i < NUM_SHADER_RESOURCE_VIEWS; ++i)
	{
		vkDestroyImageView(device, context->shaderResourceViews[i], NULL);
	}

	for (uint32_t i = 0; i < NUM_TEXTURES; ++i)
	{
		vkFreeMemory(device, context->textureMemory[i], NULL);
	}

	for (uint32_t i = 0; i < NUM_TEXTURES; ++i)
	{
		vkDestroyImage(device, context->textures[i], NULL);
	}

	return FFX_CACAO_STATUS_OK;
}

FFX_CACAO_Status FFX_CACAO_VkUpdateSettings(FFX_CACAO_VkContext* context, const FFX_CACAO_Settings* settings)
{
	if (context == NULL || settings == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	context = getAlignedVkContextPointer(context);

	memcpy(&context->settings, settings, sizeof(*settings));

	return FFX_CACAO_STATUS_OK;
}

static inline void computeDispatch(FFX_CACAO_VkContext* context, VkCommandBuffer cb, DescriptorSetID ds, ComputeShaderID cs, uint32_t width, uint32_t height, uint32_t depth)
{
	DescriptorSetLayoutID dsl = DESCRIPTOR_SET_META_DATA[ds].descriptorSetLayoutID;
	vkCmdBindDescriptorSets(cb, VK_PIPELINE_BIND_POINT_COMPUTE, context->pipelineLayouts[dsl], 0, 1, &context->descriptorSets[context->currentConstantBuffer][ds], 0, NULL);
	vkCmdBindPipeline(cb, VK_PIPELINE_BIND_POINT_COMPUTE, context->computePipelines[cs]);
	vkCmdDispatch(cb, width, height, depth);
}

typedef struct BarrierList
{
	uint32_t len;
	VkImageMemoryBarrier barriers[32];
} BarrierList;

static inline void pushBarrier(BarrierList* barrierList, VkImage image, VkImageLayout oldLayout, VkImageLayout newLayout, VkAccessFlags srcAccessFlags, VkAccessFlags dstAccessFlags)
{
	FFX_CACAO_ASSERT(barrierList->len < FFX_CACAO_ARRAY_SIZE(barrierList->barriers));
	VkImageMemoryBarrier barrier = {};
	barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
	barrier.pNext = NULL;
	barrier.srcAccessMask = srcAccessFlags;
	barrier.dstAccessMask = dstAccessFlags;
	barrier.oldLayout = oldLayout;
	barrier.newLayout = newLayout;
	barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
	barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
	barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	barrier.subresourceRange.baseMipLevel = 0;
	barrier.subresourceRange.levelCount = VK_REMAINING_MIP_LEVELS;
	barrier.subresourceRange.baseArrayLayer = 0;
	barrier.subresourceRange.layerCount = VK_REMAINING_ARRAY_LAYERS;
	barrier.image = image;
	barrierList->barriers[barrierList->len++] = barrier;
}

static inline void beginDebugMarker(FFX_CACAO_VkContext* context, VkCommandBuffer cb, const char* name)
{
	if (context->vkCmdDebugMarkerBegin)
	{
		VkDebugMarkerMarkerInfoEXT info = {};
		info.sType = VK_STRUCTURE_TYPE_DEBUG_MARKER_MARKER_INFO_EXT;
		info.pNext = NULL;
		info.pMarkerName = name;
		info.color[0] = 1.0f;
		info.color[1] = 0.0f;
		info.color[2] = 0.0f;
		info.color[3] = 1.0f;

		context->vkCmdDebugMarkerBegin(cb, &info);
	}
}

static inline void endDebugMarker(FFX_CACAO_VkContext* context, VkCommandBuffer cb)
{
	if (context->vkCmdDebugMarkerEnd)
	{
		context->vkCmdDebugMarkerEnd(cb);
	}
}

FFX_CACAO_Status FFX_CACAO_VkDraw(FFX_CACAO_VkContext* context, VkCommandBuffer cb, const FFX_CACAO_Matrix4x4* proj, const FFX_CACAO_Matrix4x4* normalsToView)
{
	if (context == NULL || cb == VK_NULL_HANDLE || proj == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	context = getAlignedVkContextPointer(context);

	FFX_CACAO_Settings *settings = &context->settings;
	FFX_CACAO_BufferSizeInfo *bsi = &context->bufferSizeInfo;
	VkDevice device = context->device;
	VkDescriptorSet *ds = context->descriptorSets[context->currentConstantBuffer];
	VkImage *tex = context->textures;
	VkResult result;
	BarrierList barrierList;

	uint32_t curBuffer = context->currentConstantBuffer;
	curBuffer = (curBuffer + 1) % NUM_BACK_BUFFERS;
	context->currentConstantBuffer = curBuffer;
#ifdef FFX_CACAO_ENABLE_PROFILING
	{
		uint32_t collectBuffer = context->collectBuffer = (curBuffer + 1) % NUM_BACK_BUFFERS;
		if (uint32_t numQueries = context->timestampQueries[collectBuffer].numTimestamps)
		{
			uint32_t offset = collectBuffer * NUM_TIMESTAMPS;
			vkGetQueryPoolResults(device, context->timestampQueryPool, offset, numQueries, numQueries * sizeof(uint64_t), context->timestampQueries[collectBuffer].timings, sizeof(uint64_t), VK_QUERY_RESULT_64_BIT);
		}
	}
#endif

	beginDebugMarker(context, cb, "FidelityFX CACAO");

	// update constant buffer

	for (uint32_t i = 0; i < 4; ++i)
	{
		VkDeviceMemory memory = context->constantBufferMemory[curBuffer][i];
		void *data = NULL;
		result = vkMapMemory(device, memory, 0, VK_WHOLE_SIZE, 0, &data);
		FFX_CACAO_ASSERT(result == VK_SUCCESS);
		FFX_CACAO_UpdateConstants((FFX_CACAO_Constants*)data, settings, bsi, proj, normalsToView);
		FFX_CACAO_UpdatePerPassConstants((FFX_CACAO_Constants*)data, settings, bsi, i);
		vkUnmapMemory(device, memory);
	}

#ifdef FFX_CACAO_ENABLE_PROFILING
	uint32_t queryPoolOffset = curBuffer * NUM_TIMESTAMPS;
	uint32_t numTimestamps = 0;
	vkCmdResetQueryPool(cb, context->timestampQueryPool, queryPoolOffset, NUM_TIMESTAMPS);
#define GET_TIMESTAMP(name) \
		context->timestampQueries[curBuffer].timestamps[numTimestamps] = TIMESTAMP_##name; \
		vkCmdWriteTimestamp(cb, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, context->timestampQueryPool, queryPoolOffset + numTimestamps++);
#else
#define GET_TIMESTAMP(name)
#endif
	
	GET_TIMESTAMP(BEGIN)

	barrierList.len = 0;
	pushBarrier(&barrierList, tex[TEXTURE_DEINTERLEAVED_DEPTHS], VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
	pushBarrier(&barrierList, tex[TEXTURE_DEINTERLEAVED_NORMALS], VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
	pushBarrier(&barrierList, tex[TEXTURE_SSAO_BUFFER_PING], VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
	pushBarrier(&barrierList, tex[TEXTURE_SSAO_BUFFER_PONG], VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
	pushBarrier(&barrierList, tex[TEXTURE_IMPORTANCE_MAP], VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
	pushBarrier(&barrierList, tex[TEXTURE_IMPORTANCE_MAP_PONG], VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
	pushBarrier(&barrierList, context->loadCounter, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
	vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);

	// prepare depths, normals and mips
	{
		beginDebugMarker(context, cb, "Prepare downsampled depths, normals and mips");

		// clear load counter
		computeDispatch(context, cb, DS_CLEAR_LOAD_COUNTER, CS_CLEAR_LOAD_COUNTER, 1, 1, 1);

		switch (context->settings.qualityLevel)
		{
		case FFX_CACAO_QUALITY_LOWEST: {
			uint32_t dispatchWidth = dispatchSize(FFX_CACAO_PREPARE_DEPTHS_HALF_WIDTH, bsi->deinterleavedDepthBufferWidth);
			uint32_t dispatchHeight = dispatchSize(FFX_CACAO_PREPARE_DEPTHS_HALF_HEIGHT, bsi->deinterleavedDepthBufferHeight);
			ComputeShaderID csPrepareDepthsHalf = context->useDownsampledSsao ? CS_PREPARE_DOWNSAMPLED_DEPTHS_HALF : CS_PREPARE_NATIVE_DEPTHS_HALF;
			computeDispatch(context, cb, DS_PREPARE_DEPTHS, csPrepareDepthsHalf, dispatchWidth, dispatchHeight, 1);
			break;
		}
		case FFX_CACAO_QUALITY_LOW: {
			uint32_t dispatchWidth = dispatchSize(FFX_CACAO_PREPARE_DEPTHS_WIDTH, bsi->deinterleavedDepthBufferWidth);
			uint32_t dispatchHeight = dispatchSize(FFX_CACAO_PREPARE_DEPTHS_HEIGHT, bsi->deinterleavedDepthBufferHeight);
			ComputeShaderID csPrepareDepths = context->useDownsampledSsao ? CS_PREPARE_DOWNSAMPLED_DEPTHS : CS_PREPARE_NATIVE_DEPTHS;
			computeDispatch(context, cb, DS_PREPARE_DEPTHS, csPrepareDepths, dispatchWidth, dispatchHeight, 1);
			break;
		}
		default: {
			uint32_t dispatchWidth = dispatchSize(FFX_CACAO_PREPARE_DEPTHS_AND_MIPS_WIDTH, bsi->deinterleavedDepthBufferWidth);
			uint32_t dispatchHeight = dispatchSize(FFX_CACAO_PREPARE_DEPTHS_AND_MIPS_HEIGHT, bsi->deinterleavedDepthBufferHeight);
			ComputeShaderID csPrepareDepthsAndMips = context->useDownsampledSsao ? CS_PREPARE_DOWNSAMPLED_DEPTHS_AND_MIPS : CS_PREPARE_NATIVE_DEPTHS_AND_MIPS;
			computeDispatch(context, cb, DS_PREPARE_DEPTHS_MIPS, csPrepareDepthsAndMips, dispatchWidth, dispatchHeight, 1);
			break;
		}
		}

		if (context->settings.generateNormals)
		{
			uint32_t dispatchWidth = dispatchSize(FFX_CACAO_PREPARE_NORMALS_WIDTH, bsi->ssaoBufferWidth);
			uint32_t dispatchHeight = dispatchSize(FFX_CACAO_PREPARE_NORMALS_HEIGHT, bsi->ssaoBufferHeight);
			ComputeShaderID csPrepareNormals = context->useDownsampledSsao ? CS_PREPARE_DOWNSAMPLED_NORMALS : CS_PREPARE_NATIVE_NORMALS;
			computeDispatch(context, cb, DS_PREPARE_NORMALS, csPrepareNormals, dispatchWidth, dispatchHeight, 1);
		}
		else
		{
			uint32_t dispatchWidth = dispatchSize(PREPARE_NORMALS_FROM_INPUT_NORMALS_WIDTH, bsi->ssaoBufferWidth);
			uint32_t dispatchHeight = dispatchSize(PREPARE_NORMALS_FROM_INPUT_NORMALS_HEIGHT, bsi->ssaoBufferHeight);
			ComputeShaderID csPrepareNormalsFromInputNormals = context->useDownsampledSsao ? CS_PREPARE_DOWNSAMPLED_NORMALS_FROM_INPUT_NORMALS : CS_PREPARE_NATIVE_NORMALS_FROM_INPUT_NORMALS;
			computeDispatch(context, cb, DS_PREPARE_NORMALS_FROM_INPUT_NORMALS, csPrepareNormalsFromInputNormals, dispatchWidth, dispatchHeight, 1);
		}

		endDebugMarker(context, cb);
		GET_TIMESTAMP(PREPARE)
	}

	barrierList.len = 0;
	pushBarrier(&barrierList, tex[TEXTURE_DEINTERLEAVED_DEPTHS], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
	pushBarrier(&barrierList, tex[TEXTURE_DEINTERLEAVED_NORMALS], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
	pushBarrier(&barrierList, context->loadCounter, VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_GENERAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_WRITE_BIT | VK_ACCESS_SHADER_READ_BIT);
	vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);

	// base pass for highest quality setting
	if (context->settings.qualityLevel == FFX_CACAO_QUALITY_HIGHEST)
	{
		beginDebugMarker(context, cb, "Generate High Quality Base Pass");

		// SSAO
		{
			beginDebugMarker(context, cb, "Base SSAO");

			uint32_t dispatchWidth = dispatchSize(FFX_CACAO_GENERATE_WIDTH, bsi->ssaoBufferWidth);
			uint32_t dispatchHeight = dispatchSize(FFX_CACAO_GENERATE_HEIGHT, bsi->ssaoBufferHeight);

			for (int pass = 0; pass < 4; ++pass)
			{
				computeDispatch(context, cb, (DescriptorSetID)(DS_GENERATE_ADAPTIVE_BASE_0 + pass), CS_GENERATE_Q3_BASE, dispatchWidth, dispatchHeight, 1);
			}

			endDebugMarker(context, cb);
		}

		GET_TIMESTAMP(BASE_SSAO_PASS)

		barrierList.len = 0;
		pushBarrier(&barrierList, tex[TEXTURE_SSAO_BUFFER_PONG], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
		vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);

		// generate importance map
		{
			beginDebugMarker(context, cb, "Importance Map");

			uint32_t dispatchWidth = dispatchSize(IMPORTANCE_MAP_WIDTH, bsi->importanceMapWidth);
			uint32_t dispatchHeight = dispatchSize(IMPORTANCE_MAP_HEIGHT, bsi->importanceMapHeight);

			computeDispatch(context, cb, DS_GENERATE_IMPORTANCE_MAP, CS_GENERATE_IMPORTANCE_MAP, dispatchWidth, dispatchHeight, 1);

			barrierList.len = 0;
			pushBarrier(&barrierList, tex[TEXTURE_IMPORTANCE_MAP], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
			vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);

			computeDispatch(context, cb, DS_POSTPROCESS_IMPORTANCE_MAP_A, CS_POSTPROCESS_IMPORTANCE_MAP_A, dispatchWidth, dispatchHeight, 1);

			barrierList.len = 0;
			pushBarrier(&barrierList, tex[TEXTURE_IMPORTANCE_MAP], VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_GENERAL, VK_ACCESS_SHADER_READ_BIT, VK_ACCESS_SHADER_WRITE_BIT);
			pushBarrier(&barrierList, tex[TEXTURE_IMPORTANCE_MAP_PONG], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
			vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);

			computeDispatch(context, cb, DS_POSTPROCESS_IMPORTANCE_MAP_B, CS_POSTPROCESS_IMPORTANCE_MAP_B, dispatchWidth, dispatchHeight, 1);

			endDebugMarker(context, cb);
		}

		endDebugMarker(context, cb);
		GET_TIMESTAMP(IMPORTANCE_MAP)

		barrierList.len = 0;
		pushBarrier(&barrierList, tex[TEXTURE_IMPORTANCE_MAP], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
		pushBarrier(&barrierList, context->loadCounter, VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_GENERAL, VK_ACCESS_SHADER_WRITE_BIT | VK_ACCESS_SHADER_READ_BIT, VK_ACCESS_SHADER_READ_BIT);
		vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);
	}

	// main ssao generation
	{
		beginDebugMarker(context, cb, "Generate SSAO");

		ComputeShaderID generateCS = (ComputeShaderID)(CS_GENERATE_Q0 + FFX_CACAO_MAX(0, context->settings.qualityLevel - 1));

		uint32_t dispatchWidth, dispatchHeight, dispatchDepth;

		switch (context->settings.qualityLevel)
		{
		case FFX_CACAO_QUALITY_LOWEST:
		case FFX_CACAO_QUALITY_LOW:
		case FFX_CACAO_QUALITY_MEDIUM:
			dispatchWidth = dispatchSize(FFX_CACAO_GENERATE_SPARSE_WIDTH, bsi->ssaoBufferWidth);
			dispatchWidth = (dispatchWidth + 4) / 5;
			dispatchHeight = dispatchSize(FFX_CACAO_GENERATE_SPARSE_HEIGHT, bsi->ssaoBufferHeight);
			dispatchDepth = 5;
			break;
		case FFX_CACAO_QUALITY_HIGH:
		case FFX_CACAO_QUALITY_HIGHEST:
			dispatchWidth = dispatchSize(FFX_CACAO_GENERATE_WIDTH, bsi->ssaoBufferWidth);
			dispatchHeight = dispatchSize(FFX_CACAO_GENERATE_HEIGHT, bsi->ssaoBufferHeight);
			dispatchDepth = 1;
			break;
		}

		for (int pass = 0; pass < 4; ++pass)
		{
			if (context->settings.qualityLevel == FFX_CACAO_QUALITY_LOWEST && (pass == 1 || pass == 2))
			{
				continue;
			}

			DescriptorSetID descriptorSetID = context->settings.qualityLevel == FFX_CACAO_QUALITY_HIGHEST ? DS_GENERATE_ADAPTIVE_0 : DS_GENERATE_0;
			descriptorSetID = (DescriptorSetID)(descriptorSetID + pass);

			computeDispatch(context, cb, descriptorSetID, generateCS, dispatchWidth, dispatchHeight, dispatchDepth);
		}

		endDebugMarker(context, cb);
		GET_TIMESTAMP(GENERATE_SSAO)
	}

	uint32_t blurPassCount = context->settings.blurPassCount;
	blurPassCount = FFX_CACAO_CLAMP(blurPassCount, 0, MAX_BLUR_PASSES);

	// de-interleaved blur
	if (blurPassCount)
	{
		barrierList.len = 0;
		pushBarrier(&barrierList, tex[TEXTURE_SSAO_BUFFER_PING], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
		pushBarrier(&barrierList, tex[TEXTURE_SSAO_BUFFER_PONG], VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
		vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);

		beginDebugMarker(context, cb, "Deinterleaved Blur");

		uint32_t w = 4 * FFX_CACAO_BLUR_WIDTH - 2 * blurPassCount;
		uint32_t h = 3 * FFX_CACAO_BLUR_HEIGHT - 2 * blurPassCount;
		uint32_t dispatchWidth = dispatchSize(w, bsi->ssaoBufferWidth);
		uint32_t dispatchHeight = dispatchSize(h, bsi->ssaoBufferHeight);

		for (int pass = 0; pass < 4; ++pass)
		{
			if (context->settings.qualityLevel == FFX_CACAO_QUALITY_LOWEST && (pass == 1 || pass == 2))
			{
				continue;
			}

			ComputeShaderID blurShaderID = (ComputeShaderID)(CS_EDGE_SENSITIVE_BLUR_1 + blurPassCount - 1);
			DescriptorSetID descriptorSetID = (DescriptorSetID)(DS_EDGE_SENSITIVE_BLUR_0 + pass);
			computeDispatch(context, cb, descriptorSetID, blurShaderID, dispatchWidth, dispatchHeight, 1);
		}

		endDebugMarker(context, cb);
		GET_TIMESTAMP(EDGE_SENSITIVE_BLUR)

		barrierList.len = 0;
		pushBarrier(&barrierList, tex[TEXTURE_SSAO_BUFFER_PONG], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
		pushBarrier(&barrierList, context->output, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
		vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);
	}
	else
	{
		barrierList.len = 0;
		pushBarrier(&barrierList, tex[TEXTURE_SSAO_BUFFER_PING], VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
		pushBarrier(&barrierList, context->output, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_GENERAL, 0, VK_ACCESS_SHADER_WRITE_BIT);
		vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);
	}


	if (context->useDownsampledSsao)
	{
		beginDebugMarker(context, cb, "Bilateral Upsample");

		uint32_t dispatchWidth = dispatchSize(2 * FFX_CACAO_BILATERAL_UPSCALE_WIDTH, bsi->inputOutputBufferWidth);
		uint32_t dispatchHeight = dispatchSize(2 * FFX_CACAO_BILATERAL_UPSCALE_HEIGHT, bsi->inputOutputBufferHeight);

		DescriptorSetID descriptorSetID = blurPassCount ? DS_BILATERAL_UPSAMPLE_PONG : DS_BILATERAL_UPSAMPLE_PING;
		ComputeShaderID upscaler;
		switch (context->settings.qualityLevel)
		{
		case FFX_CACAO_QUALITY_LOWEST:
			upscaler = CS_UPSCALE_BILATERAL_5X5_HALF;
			break;
		case FFX_CACAO_QUALITY_LOW:
		case FFX_CACAO_QUALITY_MEDIUM:
			upscaler = CS_UPSCALE_BILATERAL_5X5_NON_SMART;
			break;
		case FFX_CACAO_QUALITY_HIGH:
		case FFX_CACAO_QUALITY_HIGHEST:
			upscaler = CS_UPSCALE_BILATERAL_5X5_SMART;
			break;
		}

		computeDispatch(context, cb, descriptorSetID, upscaler, dispatchWidth, dispatchHeight, 1);

		endDebugMarker(context, cb);
		GET_TIMESTAMP(BILATERAL_UPSAMPLE)
	}
	else
	{
		beginDebugMarker(context, cb, "Reinterleave");

		uint32_t dispatchWidth = dispatchSize(FFX_CACAO_APPLY_WIDTH, bsi->inputOutputBufferWidth);
		uint32_t dispatchHeight = dispatchSize(FFX_CACAO_APPLY_HEIGHT, bsi->inputOutputBufferHeight);

		DescriptorSetID descriptorSetID = blurPassCount ? DS_APPLY_PONG : DS_APPLY_PING;

		switch (context->settings.qualityLevel)
		{
		case FFX_CACAO_QUALITY_LOWEST:
			computeDispatch(context, cb, descriptorSetID, CS_NON_SMART_HALF_APPLY, dispatchWidth, dispatchHeight, 1);
			break;
		case FFX_CACAO_QUALITY_LOW:
			computeDispatch(context, cb, descriptorSetID, CS_NON_SMART_APPLY, dispatchWidth, dispatchHeight, 1);
			break;
		default:
			computeDispatch(context, cb, descriptorSetID, CS_APPLY, dispatchWidth, dispatchHeight, 1);
			break;
		}

		endDebugMarker(context, cb);
		GET_TIMESTAMP(APPLY)
	}
	
	endDebugMarker(context, cb);

	barrierList.len = 0;
	pushBarrier(&barrierList, context->output, VK_IMAGE_LAYOUT_GENERAL, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
	vkCmdPipelineBarrier(cb, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL, 0, NULL, barrierList.len, barrierList.barriers);

#ifdef FFX_CACAO_ENABLE_PROFILING
	context->timestampQueries[curBuffer].numTimestamps = numTimestamps;
#endif

	return FFX_CACAO_STATUS_OK;
}

#ifdef FFX_CACAO_ENABLE_PROFILING
FFX_CACAO_Status FFX_CACAO_VkGetDetailedTimings(FFX_CACAO_VkContext* context, FFX_CACAO_DetailedTiming* timings)
{
	if (context == NULL || timings == NULL)
	{
		return FFX_CACAO_STATUS_INVALID_POINTER;
	}
	context = getAlignedVkContextPointer(context);

	uint32_t bufferIndex = context->collectBuffer;
	uint32_t numTimestamps = context->timestampQueries[bufferIndex].numTimestamps;
	uint64_t prevTime = context->timestampQueries[bufferIndex].timings[0];
	for (uint32_t i = 1; i < numTimestamps; ++i)
	{
		TimestampID timestampID = context->timestampQueries[bufferIndex].timestamps[i];
		timings->timestamps[i].label = TIMESTAMP_NAMES[timestampID];
		uint64_t time = context->timestampQueries[bufferIndex].timings[i];
		timings->timestamps[i].ticks = time - prevTime;
		prevTime = time;
	}
	timings->timestamps[0].label = "FFX_CACAO_TOTAL";
	timings->timestamps[0].ticks = prevTime - context->timestampQueries[bufferIndex].timings[0];
	timings->numTimestamps = numTimestamps;
	
	return FFX_CACAO_STATUS_OK;
}
#endif
#endif

#ifdef __cplusplus
}
#endif
