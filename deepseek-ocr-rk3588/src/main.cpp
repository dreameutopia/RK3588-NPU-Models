#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <chrono>
#include <opencv2/opencv.hpp>
#include "image_enc.h"
#include "rkllm.h"

using namespace std;
LLMHandle llmHandle = nullptr;

std::chrono::high_resolution_clock::time_point g_first_token_time;
std::chrono::high_resolution_clock::time_point g_start_time;
int g_token_count = 0;
bool g_first_token_received = false;

void exit_handler(int signal)
{
    if (llmHandle != nullptr)
    {
        cout << "Program exiting..." << endl;
        LLMHandle _tmp = llmHandle;
        llmHandle = nullptr;
        rkllm_destroy(_tmp);
    }
    exit(signal);
}

int callback(RKLLMResult *result, void *userdata, LLMCallState state)
{
    if (state == RKLLM_RUN_FINISH)
    {
        auto end_time = std::chrono::high_resolution_clock::now();
        auto total_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - g_start_time);
        
        printf("\n");
        printf("\n========== Performance Statistics ==========\n");
        if (g_first_token_received) {
            auto first_token_time = std::chrono::duration_cast<std::chrono::milliseconds>(g_first_token_time - g_start_time);
            printf("First Token Time:    %8.2f ms\n", first_token_time.count() * 1.0);
        }
        printf("Total Inference Time: %8.2f ms\n", total_time.count() * 1.0);
        printf("Total Tokens:        %d\n", g_token_count);
        if (g_token_count > 0 && total_time.count() > 0) {
            float tokens_per_sec = g_token_count * 1000.0 / total_time.count();
            printf("Token Rate:          %.2f tokens/s\n", tokens_per_sec);
        }
        printf("============================================\n");
        
        g_token_count = 0;
        g_first_token_received = false;
    }
    else if (state == RKLLM_RUN_ERROR)
    {
        printf("\\run error\n");
    }
    else if (state == RKLLM_RUN_NORMAL)
    {
        if (!g_first_token_received) {
            g_first_token_time = std::chrono::high_resolution_clock::now();
            g_first_token_received = true;
        }
        g_token_count++;
        printf("%s", result->text);
    }
    return 0;
}

cv::Mat expand2square(const cv::Mat& img, const cv::Scalar& background_color) {
    int width = img.cols;
    int height = img.rows;

    if (width == height) {
        return img.clone();
    }

    int size = std::max(width, height);
    cv::Mat result(size, size, img.type(), background_color);

    int x_offset = (size - width) / 2;
    int y_offset = (size - height) / 2;

    cv::Rect roi(x_offset, y_offset, width, height);
    img.copyTo(result(roi));

    return result;
}

int main(int argc, char** argv)
{
    if (argc < 7) {
        std::cerr << "Usage: " << argv[0]
                << " image_path encoder_model_path llm_model_path max_new_tokens max_context_len rknn_core_num "
                << "[img_start] [img_end] [img_content]\n\n"
                << "Arguments:\n"
                << "  image_path        Path to input image\n"
                << "  encoder_model     Path to vision RKNN model\n"
                << "  llm_model         Path to RKLLM model\n"
                << "  max_new_tokens    Maximum new tokens to generate\n"
                << "  max_context_len   Maximum context length\n"
                << "  rknn_core_num     NPU core number for RKNN (3 for RK3588)\n"
                << "  img_start         Image start token (default: empty for DeepSeekOCR)\n"
                << "  img_end           Image end token (default: empty for DeepSeekOCR)\n"
                << "  img_content       Image content token (default: <|▁pad|> for DeepSeekOCR)\n";
        return -1;
    }

    const char * image_path = argv[1];
    const char * encoder_model_path = argv[2];

    RKLLMParam param = rkllm_createDefaultParam();
    param.model_path = argv[3];
    param.top_k = 1;
    param.top_p = 0.9;
    param.temperature = 0.0;
    param.repeat_penalty = 1.0;
    param.frequency_penalty = 0.0;
    param.presence_penalty = 0.0;
    param.max_new_tokens = std::atoi(argv[4]);
    param.max_context_len = std::atoi(argv[5]);
    param.skip_special_token = false;
    param.extend_param.base_domain_id = 1;

    param.img_start   = "";
    param.img_end     = "";
    param.img_content = "<｜▁pad▁｜>";

    if (argc == 7) {
        std::cerr << "[Info] Using DeepSeekOCR default img_start/img_end/img_content: "
                << "(empty)" << " , "
                << "(empty)" << " , "
                << param.img_content
                << "\n";
    }

    if (argc > 7) param.img_start   = argv[7];
    if (argc > 8) param.img_end     = argv[8];
    if (argc > 9) param.img_content = argv[9];

    int ret;
    auto t_start = std::chrono::high_resolution_clock::now();

    ret = rkllm_init(&llmHandle, &param, callback);
    if (ret == 0){
        printf("rkllm init success\n");
    } else {
        printf("rkllm init failed\n");
        exit_handler(-1);
    }
    auto t_load_end = std::chrono::high_resolution_clock::now();
    auto load_time = std::chrono::duration_cast<std::chrono::microseconds>(t_load_end - t_start);
    printf("%s: LLM Model loaded in %8.2f ms\n", __func__, load_time.count() / 1000.0);

    rknn_app_context_t rknn_app_ctx;
    memset(&rknn_app_ctx, 0, sizeof(rknn_app_context_t));

    t_start = std::chrono::high_resolution_clock::now();

    const int core_num = atoi(argv[6]);
    ret = init_imgenc(encoder_model_path, &rknn_app_ctx, core_num);
    if (ret != 0) {
        printf("init_imgenc fail! ret=%d model_path=%s\n", ret, encoder_model_path);
        return -1;
    }
    t_load_end = std::chrono::high_resolution_clock::now();
    load_time = std::chrono::duration_cast<std::chrono::microseconds>(t_load_end - t_start);
    printf("%s: ImgEnc Model loaded in %8.2f ms\n", __func__, load_time.count() / 1000.0);

    cv::Mat img = cv::imread(image_path);
    if (img.empty()) {
        printf("Failed to read image: %s\n", image_path);
        return -1;
    }
    printf("Original image size: %d x %d\n", img.cols, img.rows);
    
    cv::cvtColor(img, img, cv::COLOR_BGR2RGB);

    cv::Scalar background_color(127.5, 127.5, 127.5);
    cv::Mat square_img = expand2square(img, background_color);

    size_t image_width = rknn_app_ctx.model_width;
    size_t image_height = rknn_app_ctx.model_height;
    cv::Mat resized_img;
    cv::Size new_size(image_width, image_height);
    cv::resize(square_img, resized_img, new_size, 0, 0, cv::INTER_LINEAR);
    printf("Resized image size: %zu x %zu\n", image_width, image_height);

    size_t n_image_tokens = rknn_app_ctx.model_image_token;
    size_t image_embed_len = rknn_app_ctx.model_embed_size;
    size_t n_embed_output = rknn_app_ctx.io_num.n_output;
    int rkllm_image_embed_len = n_image_tokens * image_embed_len * n_embed_output;
    float img_vec[rkllm_image_embed_len];
    memset(img_vec, 0, rkllm_image_embed_len * sizeof(float));
    
    t_start = std::chrono::high_resolution_clock::now();
    ret = run_imgenc(&rknn_app_ctx, resized_img.data, img_vec);
    if (ret != 0) {
        printf("run_imgenc fail! ret=%d\n", ret);
    }
    t_load_end = std::chrono::high_resolution_clock::now();
    load_time = std::chrono::duration_cast<std::chrono::microseconds>(t_load_end - t_start);
    printf("%s: ImgEnc Model inference took %8.2f ms\n", __func__, load_time.count() / 1000.0);
    
    RKLLMInput rkllm_input;
    memset(&rkllm_input, 0, sizeof(RKLLMInput));

    RKLLMInferParam rkllm_infer_params;
    memset(&rkllm_infer_params, 0, sizeof(RKLLMInferParam));

    rkllm_infer_params.mode = RKLLM_INFER_GENERATE;
    rkllm_infer_params.keep_history = 0;

    vector<string> pre_input;
    pre_input.push_back("<image>\nFree OCR.");
    pre_input.push_back("<image>\n<|grounding|>Convert the document to markdown.");
    cout << "\n********************** 可输入以下问题对应序号获取回答 / 或自定义输入 ********************\n"
         << endl;
    for (int i = 0; i < (int)pre_input.size(); i++)
    {
        cout << "[" << i << "] " << pre_input[i] << endl;
    }
    cout << "\n*************************************************************************\n"
         << endl;

    while(true) {
        std::string input_str;
        printf("\n");
        printf("user: ");
        std::getline(std::cin, input_str);
        if (input_str == "exit")
        {
            break;
        }
        if (input_str == "clear")
        {
            ret = rkllm_clear_kv_cache(llmHandle, 1, nullptr, nullptr);
            if (ret != 0)
            {
                printf("clear kv cache failed!\n");
            }
            continue;
        }
        for (int i = 0; i < (int)pre_input.size(); i++)
        {
            if (input_str == to_string(i))
            {
                input_str = pre_input[i];
                cout << input_str << endl;
            }
        }
        if (input_str.find("<image>") == std::string::npos) 
        {
            rkllm_input.input_type = RKLLM_INPUT_PROMPT;
            rkllm_input.role = "user";
            rkllm_input.prompt_input = (char*)input_str.c_str();
        } else {
            rkllm_input.input_type = RKLLM_INPUT_MULTIMODAL;
            rkllm_input.role = "user";
            rkllm_input.multimodal_input.prompt = (char*)input_str.c_str();
            rkllm_input.multimodal_input.image_embed = img_vec;
            rkllm_input.multimodal_input.n_image_tokens = n_image_tokens;
            rkllm_input.multimodal_input.n_image = 1;
            rkllm_input.multimodal_input.image_height = image_height;
            rkllm_input.multimodal_input.image_width = image_width;
        }
        
        g_start_time = std::chrono::high_resolution_clock::now();
        g_token_count = 0;
        g_first_token_received = false;
        
        printf("robot: ");
        rkllm_run(llmHandle, &rkllm_input, &rkllm_infer_params, NULL);
    }

    ret = release_imgenc(&rknn_app_ctx);
    if (ret != 0) {
        printf("release_imgenc fail! ret=%d\n", ret);
    }
    rkllm_destroy(llmHandle);

    return 0;
}
