#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <mutex>
#include <condition_variable>
#include <iostream>
#include <fstream>
#include <chrono>
#include <vector>
#include <algorithm>
#include <cmath>
#include "rkllm.h"

using namespace std;
LLMHandle llmHandle = nullptr;

std::chrono::high_resolution_clock::time_point g_start_time;

std::mutex g_mutex;
std::condition_variable g_cv;
bool g_output_complete = false;
float g_last_score = 0.5f;

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

float compute_score_from_logits(const float* logits, int vocab_size) {
    int true_token_id = 9454;
    int false_token_id = 9455;
    
    if (logits == nullptr || vocab_size <= 0) {
        return 0.5f;
    }
    
    if (true_token_id >= vocab_size || false_token_id >= vocab_size) {
        return 0.5f;
    }
    
    float true_logit = logits[true_token_id];
    float false_logit = logits[false_token_id];
    
    float max_logit = std::max(true_logit, false_logit);
    float true_exp = std::exp(true_logit - max_logit);
    float false_exp = std::exp(false_logit - max_logit);
    float sum = true_exp + false_exp;
    
    if (sum == 0) {
        return 0.5f;
    }
    
    float true_prob = true_exp / sum;
    
    return true_prob;
}

int callback(RKLLMResult *result, void *userdata, LLMCallState state)
{
    if (state == RKLLM_RUN_FINISH)
    {
        std::unique_lock<std::mutex> lock(g_mutex);
        g_output_complete = true;
        g_cv.notify_one();
    }
    else if (state == RKLLM_RUN_ERROR)
    {
        printf("\\run error\n");
        std::unique_lock<std::mutex> lock(g_mutex);
        g_output_complete = true;
        g_cv.notify_one();
    }
    else if (state == RKLLM_RUN_NORMAL)
    {
        if (result->logits.logits != nullptr && result->logits.vocab_size > 0) {
            int vocab_size = result->logits.vocab_size;
            int num_tokens = result->logits.num_tokens;
            const float* logits = result->logits.logits;
            
            int last_token_idx = num_tokens - 1;
            const float* last_token_logits = logits + (last_token_idx * vocab_size);
            
            float score = compute_score_from_logits(last_token_logits, vocab_size);
            
            std::unique_lock<std::mutex> lock(g_mutex);
            g_last_score = score;
        }
    }
    return 0;
}

std::string format_rerank_prompt(const std::string& query, const std::string& document) {
    return "<Instruct>: Given a query, determine whether the document is relevant to the query.\n"
           "<Query>: " + query + "\n"
           "<Document>: " + document + "\n"
           "<Answer>: ";
}

float run_rerank_inference(LLMHandle handle, const std::string& query, const std::string& document) {
    std::string prompt = format_rerank_prompt(query, document);
    
    RKLLMInput rkllm_input;
    memset(&rkllm_input, 0, sizeof(RKLLMInput));
    rkllm_input.input_type = RKLLM_INPUT_PROMPT;
    rkllm_input.role = "user";
    rkllm_input.prompt_input = (char*)prompt.c_str();
    
    RKLLMInferParam rkllm_infer_params;
    memset(&rkllm_infer_params, 0, sizeof(RKLLMInferParam));
    rkllm_infer_params.mode = RKLLM_INFER_GET_LOGITS;
    rkllm_infer_params.keep_history = 0;
    
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_last_score = 0.5f;
        g_output_complete = false;
    }
    
    rkllm_run(handle, &rkllm_input, &rkllm_infer_params, NULL);
    
    {
        std::unique_lock<std::mutex> lock(g_mutex);
        g_cv.wait(lock, []{ return g_output_complete; });
    }
    
    float score;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        score = g_last_score;
    }
    return score;
}

int main(int argc, char** argv)
{
    if (argc < 5) {
        std::cerr << "Usage: " << argv[0]
                << " llm_model_path max_context_len rknn_core_num mode [query] [document]\n\n"
                << "Arguments:\n"
                << "  llm_model         Path to RKLLM model\n"
                << "  max_context_len   Maximum context length\n"
                << "  rknn_core_num     NPU core number for RKNN (3 for RK3588)\n"
                << "  mode              Running mode: interactive / single / batch\n"
                << "  query             Query text (required for single mode)\n"
                << "  document          Document text (required for single mode)\n";
        return -1;
    }

    const char* llm_model_path = argv[1];
    int max_context_len = std::atoi(argv[2]);
    int core_num = std::atoi(argv[3]);
    std::string mode = argv[4];

    RKLLMParam param = rkllm_createDefaultParam();
    param.model_path = llm_model_path;
    param.max_context_len = max_context_len;
    param.max_new_tokens = 1;
    param.top_k = 1;
    param.top_p = 1.0;
    param.temperature = 1.0;
    param.skip_special_token = true;
    param.extend_param.base_domain_id = 1;

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
    printf("%s: Rerank Model loaded in %8.2f ms\n", __func__, load_time.count() / 1000.0);

    signal(SIGINT, exit_handler);
    signal(SIGTERM, exit_handler);

    if (mode == "single" && argc >= 7) {
        std::string query = argv[5];
        std::string document = argv[6];
        
        g_start_time = std::chrono::high_resolution_clock::now();
        float score = run_rerank_inference(llmHandle, query, document);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto infer_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - g_start_time);
        
        printf("\n========== Rerank Result ==========\n");
        printf("Query: %s\n", query.c_str());
        printf("Document: %s\n", document.c_str());
        printf("Relevance Score: %.4f\n", score);
        printf("Inference Time: %8.2f ms\n", infer_time.count() * 1.0);
        printf("===================================\n");
        
    } else if (mode == "batch" && argc >= 7) {
        std::string query = argv[5];
        std::string documents_file = argv[6];
        
        std::ifstream file(documents_file);
        if (!file.is_open()) {
            printf("Failed to open documents file: %s\n", documents_file.c_str());
            rkllm_destroy(llmHandle);
            return -1;
        }
        
        std::vector<std::pair<std::string, float>> results;
        std::vector<float> inference_times;
        std::string document;
        int doc_id = 0;
        
        auto batch_start_time = std::chrono::steady_clock::now();
        
        printf("\n");
        printf("╔══════════════════════════════════════════════════════════════════════════════╗\n");
        printf("║                     Qwen3-Rerank Batch Reranking Demo                         ║\n");
        printf("╚══════════════════════════════════════════════════════════════════════════════╝\n");
        printf("\n");
        printf("📌 Query: %s\n", query.c_str());
        printf("\n");
        printf("──────────────────────────────────────── Original Documents ────────────────────────────────────────\n");
        
        std::vector<std::pair<int, std::string>> original_docs;
        while (std::getline(file, document)) {
            if (document.empty()) continue;
            original_docs.push_back({doc_id, document});
            printf("[%2d] %s\n", doc_id, document.c_str());
            doc_id++;
        }
        file.close();
        
        int total_docs = original_docs.size();
        printf("───────────────────────────────────────────────────────────────────────────────────────────────────\n");
        printf("▶ Processing %d documents...\n\n", total_docs);
        
        doc_id = 0;
        for (const auto& doc_pair : original_docs) {
            const std::string& doc = doc_pair.second;
            
            auto doc_start = std::chrono::steady_clock::now();
            float score = run_rerank_inference(llmHandle, query, doc);
            auto doc_end = std::chrono::steady_clock::now();
            
            auto doc_time_ms = std::chrono::duration_cast<std::chrono::milliseconds>(doc_end - doc_start);
            inference_times.push_back((float)doc_time_ms.count());
            
            results.push_back({doc, score});
            printf("  ✓ Doc[%2d] Score: %.4f | Time: %6.2f ms\n", doc_id++, score, (float)doc_time_ms.count());
        }
        
        auto batch_end_time = std::chrono::steady_clock::now();
        auto total_time_ms = std::chrono::duration_cast<std::chrono::milliseconds>(batch_end_time - batch_start_time);
        
        float avg_time = 0;
        for (float t : inference_times) avg_time += t;
        avg_time /= inference_times.size();
        
        float docs_per_sec = (total_docs * 1000.0f) / (float)total_time_ms.count();
        
        printf("\n");
        printf("─────────────────────────────────────────── Performance Stats ───────────────────────────────────────────\n");
        printf("  ⏱  Total time:     %8.2f ms\n", (float)total_time_ms.count());
        printf("  ⏱  Average time:   %8.2f ms/doc\n", avg_time);
        printf("  ⚡ Throughput:     %8.2f docs/sec\n", docs_per_sec);
        printf("───────────────────────────────────────────────────────────────────────────────────────────────────\n");
        
        std::sort(results.begin(), results.end(), 
                  [](const std::pair<std::string, float>& a, const std::pair<std::string, float>& b) {
                      return a.second > b.second;
                  });
        
        printf("\n");
        printf("╔══════════════════════════════════════════════════════════════════════════════╗\n");
        printf("║                           🎯 Ranked Results (by relevance)                 ║\n");
        printf("╚══════════════════════════════════════════════════════════════════════════════╝\n");
        printf("\n");
        
        for (size_t i = 0; i < results.size(); i++) {
            const std::string& doc = results[i].first;
            float score = results[i].second;
            
            int bar_width = 40;
            int filled = (int)(score * bar_width);
            std::string bar;
            for (int j = 0; j < bar_width; j++) {
                if (j < filled) bar += "█";
                else bar += "░";
            }
            
            printf("  %zu. [%s] %.4f\n", i + 1, bar.c_str(), score);
            printf("     └─ %s\n\n", doc.c_str());
        }
        printf("═══════════════════════════════════════════════════════════════════════════════════════════════════\n");
        
    } else {
        cout << "\n********************** Qwen3-Rerank Interactive Mode ********************\n"
             << "Commands:\n"
             << "  rerank <query> | <document>  - Compute relevance score\n"
             << "  batch <query> | <file>       - Batch rerank documents from file\n"
             << "  exit                         - Exit program\n"
             << "*************************************************************************\n"
             << endl;

        while(true) {
            std::string input_str;
            printf("\n");
            printf("user: ");
            std::getline(std::cin, input_str);
            
            if (input_str == "exit") {
                break;
            }
            
            if (input_str.find("rerank ") == 0) {
                std::string rest = input_str.substr(7);
                size_t sep = rest.find(" | ");
                if (sep == std::string::npos) {
                    printf("Usage: rerank <query> | <document>\n");
                    continue;
                }
                std::string query = rest.substr(0, sep);
                std::string document = rest.substr(sep + 3);
                
                g_start_time = std::chrono::high_resolution_clock::now();
                float score = run_rerank_inference(llmHandle, query, document);
                
                auto end_time = std::chrono::high_resolution_clock::now();
                auto infer_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - g_start_time);
                
                printf("robot: Relevance Score: %.4f (Inference Time: %.2f ms)\n", score, infer_time.count() * 1.0);
                
            } else if (input_str.find("batch ") == 0) {
                std::string rest = input_str.substr(6);
                size_t sep = rest.find(" | ");
                if (sep == std::string::npos) {
                    printf("Usage: batch <query> | <file>\n");
                    continue;
                }
                std::string query = rest.substr(0, sep);
                std::string documents_file = rest.substr(sep + 3);
                
                std::ifstream file(documents_file);
                if (!file.is_open()) {
                    printf("Failed to open file: %s\n", documents_file.c_str());
                    continue;
                }
                
                std::vector<std::pair<std::string, float>> results;
                std::string document;
                int doc_id = 0;
                
                printf("Processing documents...\n");
                
                while (std::getline(file, document)) {
                    if (document.empty()) continue;
                    
                    float score = run_rerank_inference(llmHandle, query, document);
                    results.push_back({document, score});
                    printf("  [%d] Score: %.4f\n", doc_id++, score);
                }
                file.close();
                
                std::sort(results.begin(), results.end(), 
                          [](const std::pair<std::string, float>& a, const std::pair<std::string, float>& b) {
                              return a.second > b.second;
                          });
                
                printf("robot: Ranked Results:\n");
                for (size_t i = 0; i < results.size(); i++) {
                    printf("  [Rank %zu] Score: %.4f | %s\n", i + 1, results[i].second, results[i].first.c_str());
                }
                
            } else {
                printf("Unknown command. Use 'rerank <query> | <document>' or 'batch <query> | <file>'\n");
            }
        }
    }

    rkllm_destroy(llmHandle);

    return 0;
}
