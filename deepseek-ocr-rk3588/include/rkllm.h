#ifndef _RKLLM_H_
#define _RKLLM_H_
#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

#define CPU0 (1 << 0)
#define CPU1 (1 << 1)
#define CPU2 (1 << 2)
#define CPU3 (1 << 3)
#define CPU4 (1 << 4)
#define CPU5 (1 << 5)
#define CPU6 (1 << 6)
#define CPU7 (1 << 7)

typedef void* LLMHandle;

typedef enum {
    RKLLM_RUN_NORMAL  = 0,
    RKLLM_RUN_WAITING = 1,
    RKLLM_RUN_FINISH  = 2,
    RKLLM_RUN_ERROR   = 3,
} LLMCallState;

typedef enum {
    RKLLM_INPUT_PROMPT      = 0,
    RKLLM_INPUT_TOKEN       = 1,
    RKLLM_INPUT_EMBED       = 2,
    RKLLM_INPUT_MULTIMODAL  = 3,
} RKLLMInputType;

typedef enum {
    RKLLM_INFER_GENERATE                    = 0,
    RKLLM_INFER_GET_LAST_HIDDEN_LAYER       = 1,
    RKLLM_INFER_GET_LOGITS                  = 2,
} RKLLMInferMode;

typedef struct {
    int32_t      base_domain_id;
    int8_t       embed_flash;
    int8_t       enabled_cpus_num;
    uint32_t     enabled_cpus_mask;
    uint8_t      n_batch;
    int8_t       use_cross_attn;
    uint8_t      reserved[104];
} RKLLMExtendParam;

typedef struct {
    const char* model_path;
    int32_t max_context_len;
    int32_t max_new_tokens;
    int32_t top_k;
    int32_t n_keep;
    float top_p;
    float temperature;
    float repeat_penalty;
    float frequency_penalty;
    float presence_penalty;
    int32_t mirostat;
    float mirostat_tau;
    float mirostat_eta;
    bool skip_special_token;
    bool is_async;
    const char* img_start;
    const char* img_end;
    const char* img_content;
    RKLLMExtendParam extend_param;
} RKLLMParam;

typedef struct {
    const char* lora_adapter_path;
    const char* lora_adapter_name;
    float scale;
} RKLLMLoraAdapter;

typedef struct {
    float* embed;
    size_t n_tokens;
} RKLLMEmbedInput;

typedef struct {
    int32_t* input_ids;
    size_t n_tokens;
} RKLLMTokenInput;

typedef struct {
    char* prompt;
    float* image_embed;
    size_t n_image_tokens;
    size_t n_image;
    size_t image_width;
    size_t image_height;
} RKLLMMultiModalInput;

typedef struct {
    const char* role;
    bool enable_thinking;
    RKLLMInputType input_type;
    union {
        const char* prompt_input;
        RKLLMEmbedInput embed_input;
        RKLLMTokenInput token_input;
        RKLLMMultiModalInput multimodal_input;
    };
} RKLLMInput;

typedef struct {
    const char* lora_adapter_name;
} RKLLMLoraParam;

typedef struct {
    int save_prompt_cache;
    const char* prompt_cache_path;
} RKLLMPromptCacheParam;

typedef struct {
    float* encoder_k_cache;
    float* encoder_v_cache;
    float* encoder_mask;
    int32_t* encoder_pos;
    int num_tokens;
} RKLLMCrossAttnParam;

typedef struct {
    RKLLMInferMode mode;
    RKLLMLoraParam* lora_params;
    RKLLMPromptCacheParam* prompt_cache_params;
    int keep_history;
} RKLLMInferParam;

typedef struct {
    const float* hidden_states;
    int embd_size;
    int num_tokens;
} RKLLMResultLastHiddenLayer;

typedef struct {
    const float* logits;
    int vocab_size;
    int num_tokens;
} RKLLMResultLogits;

typedef struct {
    float prefill_time_ms;
    int prefill_tokens;
    float generate_time_ms;
    int generate_tokens;
    float memory_usage_mb;
} RKLLMPerfStat;

typedef struct {
    const char* text;
    int32_t token_id;
    RKLLMResultLastHiddenLayer last_hidden_layer;
    RKLLMResultLogits logits;
    RKLLMPerfStat perf;
} RKLLMResult;

typedef int(*LLMResultCallback)(RKLLMResult* result, void* userdata, LLMCallState state);

RKLLMParam rkllm_createDefaultParam();
int rkllm_init(LLMHandle* handle, RKLLMParam* param, LLMResultCallback callback);
int rkllm_load_lora(LLMHandle handle, RKLLMLoraAdapter* lora_adapter);
int rkllm_load_prompt_cache(LLMHandle handle, const char* prompt_cache_path);
int rkllm_release_prompt_cache(LLMHandle handle);
int rkllm_destroy(LLMHandle handle);
int rkllm_run(LLMHandle handle, RKLLMInput* rkllm_input, RKLLMInferParam* rkllm_infer_params, void* userdata);
int rkllm_run_async(LLMHandle handle, RKLLMInput* rkllm_input, RKLLMInferParam* rkllm_infer_params, void* userdata);
int rkllm_abort(LLMHandle handle);
int rkllm_is_running(LLMHandle handle);
int rkllm_clear_kv_cache(LLMHandle handle, int keep_system_prompt, int* start_pos, int* end_pos);
int rkllm_get_kv_cache_size(LLMHandle handle, int* cache_sizes);
int rkllm_set_chat_template(LLMHandle handle, const char* system_prompt, const char* prompt_prefix, const char* prompt_postfix);
int rkllm_set_function_tools(LLMHandle handle, const char* system_prompt, const char* tools, const char* tool_response_str);
int rkllm_set_cross_attn_params(LLMHandle handle, RKLLMCrossAttnParam* cross_attn_params);

#ifdef __cplusplus
}
#endif

#endif
