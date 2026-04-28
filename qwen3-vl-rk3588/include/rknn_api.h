/****************************************************************************
*
*    RKNN API Header (Simplified for Qwen3-VL Demo)
*
*****************************************************************************/

#ifndef _RKNN_API_H
#define _RKNN_API_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#define RKNN_SUCC                               0
#define RKNN_ERR_FAIL                           -1

#define RKNN_MAX_DIMS                           16
#define RKNN_MAX_NAME_LEN                       256

#ifdef __arm__
typedef uint32_t rknn_context;
#else
typedef uint64_t rknn_context;
#endif

typedef enum _rknn_query_cmd {
    RKNN_QUERY_IN_OUT_NUM = 0,
    RKNN_QUERY_INPUT_ATTR = 1,
    RKNN_QUERY_OUTPUT_ATTR = 2,
    RKNN_QUERY_PERF_DETAIL = 3,
    RKNN_QUERY_PERF_RUN = 4,
    RKNN_QUERY_SDK_VERSION = 5,
    RKNN_QUERY_MEM_SIZE = 6,
    RKNN_QUERY_CUSTOM_STRING = 7,
    RKNN_QUERY_CMD_MAX
} rknn_query_cmd;

typedef enum _rknn_tensor_type {
    RKNN_TENSOR_FLOAT32 = 0,
    RKNN_TENSOR_FLOAT16,
    RKNN_TENSOR_INT8,
    RKNN_TENSOR_UINT8,
    RKNN_TENSOR_INT16,
    RKNN_TENSOR_UINT16,
    RKNN_TENSOR_INT32,
    RKNN_TENSOR_UINT32,
    RKNN_TENSOR_INT64,
    RKNN_TENSOR_BOOL,
    RKNN_TENSOR_INT4,
    RKNN_TENSOR_BFLOAT16,
    RKNN_TENSOR_TYPE_MAX
} rknn_tensor_type;

inline static const char* get_type_string(rknn_tensor_type type)
{
    switch(type) {
    case RKNN_TENSOR_FLOAT32: return "FP32";
    case RKNN_TENSOR_FLOAT16: return "FP16";
    case RKNN_TENSOR_INT8: return "INT8";
    case RKNN_TENSOR_UINT8: return "UINT8";
    case RKNN_TENSOR_INT16: return "INT16";
    case RKNN_TENSOR_UINT16: return "UINT16";
    case RKNN_TENSOR_INT32: return "INT32";
    case RKNN_TENSOR_UINT32: return "UINT32";
    case RKNN_TENSOR_INT64: return "INT64";
    case RKNN_TENSOR_BOOL: return "BOOL";
    case RKNN_TENSOR_INT4: return "INT4";
    case RKNN_TENSOR_BFLOAT16: return "BF16";
    default: return "UNKNOW";
    }
}

typedef enum _rknn_tensor_qnt_type {
    RKNN_TENSOR_QNT_NONE = 0,
    RKNN_TENSOR_QNT_DFP,
    RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC,
    RKNN_TENSOR_QNT_MAX
} rknn_tensor_qnt_type;

inline static const char* get_qnt_type_string(rknn_tensor_qnt_type type)
{
    switch(type) {
    case RKNN_TENSOR_QNT_NONE: return "NONE";
    case RKNN_TENSOR_QNT_DFP: return "DFP";
    case RKNN_TENSOR_QNT_AFFINE_ASYMMETRIC: return "AFFINE";
    default: return "UNKNOW";
    }
}

typedef enum _rknn_tensor_format {
    RKNN_TENSOR_NCHW = 0,
    RKNN_TENSOR_NHWC,
    RKNN_TENSOR_NC1HWC2,
    RKNN_TENSOR_UNDEFINED,
    RKNN_TENSOR_FORMAT_MAX
} rknn_tensor_format;

inline static const char* get_format_string(rknn_tensor_format fmt)
{
    switch(fmt) {
    case RKNN_TENSOR_NCHW: return "NCHW";
    case RKNN_TENSOR_NHWC: return "NHWC";
    case RKNN_TENSOR_NC1HWC2: return "NC1HWC2";
    case RKNN_TENSOR_UNDEFINED: return "UNDEFINED";
    default: return "UNKNOW";
    }
}

typedef enum _rknn_core_mask {
    RKNN_NPU_CORE_AUTO = 0,
    RKNN_NPU_CORE_0 = 1,
    RKNN_NPU_CORE_1 = 2,
    RKNN_NPU_CORE_2 = 4,
    RKNN_NPU_CORE_0_1 = RKNN_NPU_CORE_0 | RKNN_NPU_CORE_1,
    RKNN_NPU_CORE_0_1_2 = RKNN_NPU_CORE_0_1 | RKNN_NPU_CORE_2,
    RKNN_NPU_CORE_ALL = 0xffff,
    RKNN_NPU_CORE_UNDEFINED,
} rknn_core_mask;

typedef struct _rknn_input_output_num {
    uint32_t n_input;
    uint32_t n_output;
} rknn_input_output_num;

typedef struct _rknn_tensor_attr {
    uint32_t index;
    uint32_t n_dims;
    uint32_t dims[RKNN_MAX_DIMS];
    char name[RKNN_MAX_NAME_LEN];
    uint32_t n_elems;
    uint32_t size;
    rknn_tensor_format fmt;
    rknn_tensor_type type;
    rknn_tensor_qnt_type qnt_type;
    int32_t zp;
    float scale;
    uint32_t w_stride;
    uint8_t size_with_stride;
    uint8_t reserved[2];
} rknn_tensor_attr;

typedef struct _rknn_input {
    uint32_t index;
    void* buf;
    uint32_t size;
    uint8_t pass_through;
    rknn_tensor_type type;
    rknn_tensor_format fmt;
} rknn_input;

typedef struct _rknn_output {
    uint8_t want_float;
    uint8_t is_prealloc;
    uint32_t index;
    void* buf;
    uint32_t size;
} rknn_output;

int rknn_init(rknn_context* context, void* model, uint32_t size, uint32_t flag, void* extend);
int rknn_destroy(rknn_context context);
int rknn_query(rknn_context context, rknn_query_cmd cmd, void* info, uint32_t size);
int rknn_inputs_set(rknn_context context, uint32_t n_inputs, rknn_input inputs[]);
int rknn_run(rknn_context context, void* extend);
int rknn_outputs_get(rknn_context context, uint32_t n_outputs, rknn_output outputs[], void* extend);
int rknn_outputs_release(rknn_context context, uint32_t n_outputs, rknn_output outputs[]);
int rknn_set_core_mask(rknn_context context, rknn_core_mask core_mask);

#ifdef __cplusplus
}
#endif

#endif
