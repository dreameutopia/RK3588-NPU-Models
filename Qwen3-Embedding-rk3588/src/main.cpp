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
#include <cmath>
#include "rkllm.h"

using namespace std;
LLMHandle llmHandle = nullptr;

std::chrono::high_resolution_clock::time_point g_start_time;

std::mutex g_mutex;
std::condition_variable g_cv;
bool g_output_complete = false;
std::vector<float> g_last_embedding;
int g_embedding_dim = 0;

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

float compute_norm(const float* vec, int dim) {
    float sum = 0.0f;
    for (int i = 0; i < dim; i++) {
        sum += vec[i] * vec[i];
    }
    return std::sqrt(sum);
}

void normalize_vector(float* vec, int dim) {
    float norm = compute_norm(vec, dim);
    if (norm > 0) {
        for (int i = 0; i < dim; i++) {
            vec[i] /= norm;
        }
    }
}

float compute_cosine_similarity(const float* a, const float* b, int dim) {
    float dot = 0.0f;
    for (int i = 0; i < dim; i++) {
        dot += a[i] * b[i];
    }
    return dot;
}

int callback(RKLLMResult *result, void *userdata, LLMCallState state)
{
    if (state == RKLLM_RUN_FINISH)
    {
        if (result->last_hidden_layer.hidden_states != nullptr && 
            result->last_hidden_layer.embd_size > 0 && 
            result->last_hidden_layer.num_tokens > 0) {
            
            int embd_size = result->last_hidden_layer.embd_size;
            int num_tokens = result->last_hidden_layer.num_tokens;
            const float* hidden_states = result->last_hidden_layer.hidden_states;
            
            int last_token_idx = num_tokens - 1;
            const float* last_token_hidden = hidden_states + (last_token_idx * embd_size);
            
            std::unique_lock<std::mutex> lock(g_mutex);
            g_embedding_dim = embd_size;
            g_last_embedding.resize(embd_size);
            std::copy(last_token_hidden, last_token_hidden + embd_size, g_last_embedding.begin());
            
            normalize_vector(g_last_embedding.data(), embd_size);
        }
        
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
        if (result->last_hidden_layer.hidden_states != nullptr && 
            result->last_hidden_layer.embd_size > 0 && 
            result->last_hidden_layer.num_tokens > 0) {
            
            int embd_size = result->last_hidden_layer.embd_size;
            int num_tokens = result->last_hidden_layer.num_tokens;
            const float* hidden_states = result->last_hidden_layer.hidden_states;
            
            int last_token_idx = num_tokens - 1;
            const float* last_token_hidden = hidden_states + (last_token_idx * embd_size);
            
            std::unique_lock<std::mutex> lock(g_mutex);
            g_embedding_dim = embd_size;
            g_last_embedding.resize(embd_size);
            std::copy(last_token_hidden, last_token_hidden + embd_size, g_last_embedding.begin());
            
            normalize_vector(g_last_embedding.data(), embd_size);
            
            g_output_complete = true;
            g_cv.notify_one();
        }
    }
    return 0;
}

std::vector<float> run_embedding_inference(LLMHandle handle, const std::string& text) {
    RKLLMInput rkllm_input;
    memset(&rkllm_input, 0, sizeof(RKLLMInput));
    rkllm_input.input_type = RKLLM_INPUT_PROMPT;
    rkllm_input.role = "user";
    rkllm_input.prompt_input = (char*)text.c_str();
    
    RKLLMInferParam rkllm_infer_params;
    memset(&rkllm_infer_params, 0, sizeof(RKLLMInferParam));
    rkllm_infer_params.mode = RKLLM_INFER_GET_LAST_HIDDEN_LAYER;
    rkllm_infer_params.keep_history = 0;
    
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_last_embedding.clear();
        g_embedding_dim = 0;
        g_output_complete = false;
    }
    
    int ret = rkllm_run(handle, &rkllm_input, &rkllm_infer_params, NULL);
    if (ret != 0) {
        printf("rkllm_run failed with ret=%d\n", ret);
        return std::vector<float>();
    }
    
    {
        std::unique_lock<std::mutex> lock(g_mutex);
        g_cv.wait(lock, []{ return g_output_complete; });
    }
    
    std::vector<float> embedding;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        embedding = g_last_embedding;
    }
    return embedding;
}

void save_embedding_to_file(const std::vector<float>& embedding, const std::string& filename) {
    std::ofstream outFile(filename, std::ios::binary);
    if (outFile.is_open()) {
        outFile.write(reinterpret_cast<const char*>(embedding.data()), 
                      embedding.size() * sizeof(float));
        outFile.close();
    }
}

void print_embedding_info(const std::vector<float>& embedding, float inference_time_ms) {
    if (embedding.empty()) {
        printf("Error: Failed to generate embedding\n");
        return;
    }
    
    float norm = compute_norm(embedding.data(), embedding.size());
    
    printf("Embedding generated: dim=%zu, norm=%.4f (Inference Time: %.2f ms)\n", 
           embedding.size(), norm, inference_time_ms);
}

int main(int argc, char** argv)
{
    if (argc < 5) {
        std::cerr << "Usage: " << argv[0]
                << " llm_model_path max_context_len rknn_core_num mode [text] [text2]\n\n"
                << "Arguments:\n"
                << "  llm_model         Path to RKLLM model\n"
                << "  max_context_len   Maximum context length\n"
                << "  rknn_core_num     NPU core number for RKNN (3 for RK3588)\n"
                << "  mode              Running mode: interactive / single / batch / similarity / eval\n"
                << "  text              Text to embed (required for single mode)\n"
                << "  text2             Second text for similarity mode\n";
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
    param.extend_param.base_domain_id = 0;
    param.extend_param.embed_flash = 0;

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
    printf("%s: Embedding Model loaded in %8.2f ms\n", __func__, load_time.count() / 1000.0);

    signal(SIGINT, exit_handler);
    signal(SIGTERM, exit_handler);

    if (mode == "single" && argc >= 6) {
        std::string text = argv[5];
        
        printf("Running embedding inference for: %s\n", text.c_str());
        
        g_start_time = std::chrono::high_resolution_clock::now();
        std::vector<float> embedding = run_embedding_inference(llmHandle, text);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto infer_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - g_start_time);
        
        printf("\n========== Embedding Result ==========\n");
        printf("Text: %s\n", text.c_str());
        printf("Dimension: %zu\n", embedding.size());
        if (!embedding.empty()) {
            printf("Norm: %.4f\n", compute_norm(embedding.data(), embedding.size()));
            printf("First 10 values: ");
            for (size_t i = 0; i < std::min((size_t)10, embedding.size()); i++) {
                printf("%.4f ", embedding[i]);
            }
            printf("\n");
        }
        printf("Inference Time: %8.2f ms\n", infer_time.count() * 1.0);
        printf("======================================\n");
        
    } else if (mode == "similarity" && argc >= 7) {
        std::string text1 = argv[5];
        std::string text2 = argv[6];
        
        g_start_time = std::chrono::high_resolution_clock::now();
        std::vector<float> embedding1 = run_embedding_inference(llmHandle, text1);
        std::vector<float> embedding2 = run_embedding_inference(llmHandle, text2);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto infer_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - g_start_time);
        
        float similarity = 0.0f;
        if (!embedding1.empty() && !embedding2.empty() && embedding1.size() == embedding2.size()) {
            similarity = compute_cosine_similarity(embedding1.data(), embedding2.data(), embedding1.size());
        }
        
        printf("\n========== Similarity Result ==========\n");
        printf("Text 1: %s\n", text1.c_str());
        printf("Text 2: %s\n", text2.c_str());
        printf("Cosine Similarity: %.4f\n", similarity);
        printf("Total Inference Time: %8.2f ms\n", infer_time.count() * 1.0);
        printf("=======================================\n");
        
    } else if (mode == "batch" && argc >= 6) {
        std::string texts_file = argv[5];
        
        std::ifstream file(texts_file);
        if (!file.is_open()) {
            printf("Failed to open texts file: %s\n", texts_file.c_str());
            rkllm_destroy(llmHandle);
            return -1;
        }
        
        std::vector<std::pair<std::string, std::vector<float>>> results;
        std::vector<float> inference_times;
        std::string text;
        int text_id = 0;
        
        auto batch_start_time = std::chrono::steady_clock::now();
        
        printf("\n");
        printf("╔══════════════════════════════════════════════════════════════════════════════╗\n");
        printf("║                     Qwen3-Embedding Batch Processing Demo                    ║\n");
        printf("╚══════════════════════════════════════════════════════════════════════════════╝\n");
        printf("\n");
        printf("▶ Loading texts from: %s\n\n", texts_file.c_str());
        
        std::vector<std::pair<int, std::string>> original_texts;
        while (std::getline(file, text)) {
            if (text.empty()) continue;
            original_texts.push_back({text_id, text});
            text_id++;
        }
        file.close();
        
        int total_texts = original_texts.size();
        printf("▶ Processing %d texts...\n\n", total_texts);
        
        text_id = 0;
        for (const auto& text_pair : original_texts) {
            const std::string& txt = text_pair.second;
            
            auto text_start = std::chrono::steady_clock::now();
            std::vector<float> embedding = run_embedding_inference(llmHandle, txt);
            auto text_end = std::chrono::steady_clock::now();
            
            auto text_time_ms = std::chrono::duration_cast<std::chrono::milliseconds>(text_end - text_start);
            inference_times.push_back((float)text_time_ms.count());
            
            results.push_back({txt, embedding});
            printf("  ✓ Text[%2d] Dim: %zu | Time: %6.2f ms\n", text_id++, embedding.size(), (float)text_time_ms.count());
        }
        
        auto batch_end_time = std::chrono::steady_clock::now();
        auto total_time_ms = std::chrono::duration_cast<std::chrono::milliseconds>(batch_end_time - batch_start_time);
        
        float avg_time = 0;
        for (float t : inference_times) avg_time += t;
        avg_time /= inference_times.size();
        
        float texts_per_sec = (total_texts * 1000.0f) / (float)total_time_ms.count();
        
        printf("\n");
        printf("─────────────────────────────────────────── Performance Stats ───────────────────────────────────────────\n");
        printf("  ⏱  Total time:     %8.2f ms\n", (float)total_time_ms.count());
        printf("  ⏱  Average time:   %8.2f ms/text\n", avg_time);
        printf("  ⚡ Throughput:     %8.2f texts/sec\n", texts_per_sec);
        printf("───────────────────────────────────────────────────────────────────────────────────────────────────\n");
        
        printf("\n");
        printf("╔══════════════════════════════════════════════════════════════════════════════╗\n");
        printf("║                           📊 Embedding Results Summary                       ║\n");
        printf("╚══════════════════════════════════════════════════════════════════════════════╝\n");
        printf("\n");
        
        for (size_t i = 0; i < results.size(); i++) {
            const std::string& txt = results[i].first;
            const std::vector<float>& emb = results[i].second;
            
            printf("  [%zu] Dim: %zu | Norm: %.4f\n", i + 1, emb.size(), 
                   emb.empty() ? 0.0f : compute_norm(emb.data(), emb.size()));
            printf("      └─ %.60s%s\n", txt.c_str(), txt.length() > 60 ? "..." : "");
        }
        printf("═══════════════════════════════════════════════════════════════════════════════════════════════════\n");
        
    } else if (mode == "eval") {
        std::vector<std::vector<std::string>> test_groups = {
            {
                "苹果是一种常见的水果",
                "我喜欢吃新鲜的苹果",
                "这个苹果很甜很好吃"
            },
            {
                "汽车是现代交通工具",
                "这辆车速度很快",
                "我每天开车上班"
            },
            {
                "战争带来痛苦和破坏",
                "和平是人类共同的愿望",
                "冲突解决需要对话"
            },
            {
                "学习使人进步",
                "教育是国家的根本",
                "知识改变命运"
            },
            {
                "今天天气晴朗",
                "下雨了，记得带伞",
                "天气预报说明天有雨"
            }
        };
        
        std::vector<std::string> group_names = {
            "水果/苹果",
            "汽车/交通",
            "战争/和平",
            "学习/教育",
            "天气/自然"
        };
        
        std::vector<std::string> group_relations = {
            "组1与组2: 无相关 (水果 vs 交通)",
            "组2与组3: 语义冲突 (交通 vs 战争)",
            "组3与组4: 语义相似 (战争/和平 vs 学习/教育 - 都是社会话题)",
            "组4与组5: 无相关 (教育 vs 天气)"
        };
        
        printf("\n");
        printf("╔══════════════════════════════════════════════════════════════════════════════╗\n");
        printf("║               Qwen3-Embedding 可用性评估测试 (Evaluation Test)               ║\n");
        printf("╚══════════════════════════════════════════════════════════════════════════════╝\n");
        printf("\n");
        
        printf("▶ 测试设计说明:\n");
        printf("  - 共15个测试文本，分为5组，每组3个语义相似的文本\n");
        printf("  - 组间关系包含: 无相关、语义冲突、语义相似\n\n");
        
        printf("▶ 组间关系定义:\n");
        for (const auto& rel : group_relations) {
            printf("  • %s\n", rel.c_str());
        }
        printf("\n");
        
        printf("▶ 测试文本内容:\n");
        for (size_t g = 0; g < test_groups.size(); g++) {
            printf("  组%zu [%s]:\n", g + 1, group_names[g].c_str());
            for (size_t t = 0; t < test_groups[g].size(); t++) {
                printf("    [%zu-%zu] %s\n", g + 1, t + 1, test_groups[g][t].c_str());
            }
        }
        printf("\n");
        
        auto eval_start_time = std::chrono::steady_clock::now();
        
        std::vector<std::pair<std::string, std::vector<float>>> all_embeddings;
        std::vector<float> inference_times;
        std::vector<std::string> all_texts;
        
        printf("▶ 开始生成嵌入向量...\n\n");
        
        for (size_t g = 0; g < test_groups.size(); g++) {
            for (size_t t = 0; t < test_groups[g].size(); t++) {
                const std::string& text = test_groups[g][t];
                
                auto text_start = std::chrono::steady_clock::now();
                std::vector<float> embedding = run_embedding_inference(llmHandle, text);
                auto text_end = std::chrono::steady_clock::now();
                
                auto text_time_ms = std::chrono::duration_cast<std::chrono::milliseconds>(text_end - text_start);
                inference_times.push_back((float)text_time_ms.count());
                
                all_embeddings.push_back({text, embedding});
                all_texts.push_back(text);
                
                printf("  ✓ 组%zu-%zu: %6.2f ms | Dim: %zu\n", 
                       g + 1, t + 1, (float)text_time_ms.count(), embedding.size());
            }
        }
        
        auto eval_end_time = std::chrono::steady_clock::now();
        auto total_eval_time = std::chrono::duration_cast<std::chrono::milliseconds>(eval_end_time - eval_start_time);
        
        float avg_infer_time = 0;
        for (float t : inference_times) avg_infer_time += t;
        avg_infer_time /= inference_times.size();
        
        printf("\n");
        printf("─────────────────────────────────────────── 推理性能统计 ───────────────────────────────────────────\n");
        printf("  ⏱  总推理时间:     %8.2f ms\n", (float)total_eval_time.count());
        printf("  ⏱  平均推理时间:   %8.2f ms/text\n", avg_infer_time);
        printf("  ⚡ 吞吐量:         %8.2f texts/sec\n", (15.0f * 1000.0f) / (float)total_eval_time.count());
        printf("───────────────────────────────────────────────────────────────────────────────────────────────────\n");
        
        printf("\n");
        printf("▶ 计算相似度矩阵...\n\n");
        
        std::vector<std::vector<float>> similarity_matrix(15, std::vector<float>(15, 0.0f));
        for (size_t i = 0; i < all_embeddings.size(); i++) {
            for (size_t j = 0; j < all_embeddings.size(); j++) {
                if (i == j) {
                    similarity_matrix[i][j] = 1.0f;
                } else if (!all_embeddings[i].second.empty() && !all_embeddings[j].second.empty() &&
                           all_embeddings[i].second.size() == all_embeddings[j].second.size()) {
                    similarity_matrix[i][j] = compute_cosine_similarity(
                        all_embeddings[i].second.data(), 
                        all_embeddings[j].second.data(), 
                        all_embeddings[i].second.size());
                }
            }
        }
        
        printf("─────────────────────────────────────────── 组内相似度分析 ───────────────────────────────────────────\n\n");
        
        std::vector<float> intra_group_avg_similarities;
        for (size_t g = 0; g < test_groups.size(); g++) {
            size_t base_idx = g * 3;
            float group_sum = 0;
            int count = 0;
            
            printf("  组%zu [%s] 组内相似度:\n", g + 1, group_names[g].c_str());
            for (size_t i = 0; i < 3; i++) {
                for (size_t j = i + 1; j < 3; j++) {
                    float sim = similarity_matrix[base_idx + i][base_idx + j];
                    group_sum += sim;
                    count++;
                    printf("    文本%zu-%zu vs 文本%zu-%zu: %.4f\n", 
                           g + 1, i + 1, g + 1, j + 1, sim);
                }
            }
            float avg = group_sum / count;
            intra_group_avg_similarities.push_back(avg);
            printf("    ★ 组内平均相似度: %.4f\n\n", avg);
        }
        
        float overall_intra_avg = 0;
        for (float s : intra_group_avg_similarities) overall_intra_avg += s;
        overall_intra_avg /= intra_group_avg_similarities.size();
        
        printf("─────────────────────────────────────────── 组间相似度分析 ───────────────────────────────────────────\n\n");
        
        auto compute_inter_group_avg = [&](size_t g1, size_t g2) -> float {
            float sum = 0;
            int count = 0;
            for (size_t i = 0; i < 3; i++) {
                for (size_t j = 0; j < 3; j++) {
                    sum += similarity_matrix[g1 * 3 + i][g2 * 3 + j];
                    count++;
                }
            }
            return sum / count;
        };
        
        printf("  组间相似度矩阵 (组间平均相似度):\n\n");
        printf("         ");
        for (size_t g = 0; g < 5; g++) {
            printf("  组%zu   ", g + 1);
        }
        printf("\n");
        
        for (size_t g1 = 0; g1 < 5; g1++) {
            printf("  组%zu    ", g1 + 1);
            for (size_t g2 = 0; g2 < 5; g2++) {
                if (g1 == g2) {
                    printf("  1.000 ");
                } else {
                    float avg_sim = compute_inter_group_avg(g1, g2);
                    printf("  %.3f ", avg_sim);
                }
            }
            printf("\n");
        }
        
        printf("\n");
        printf("  组间关系验证:\n");
        
        auto g1_2 = compute_inter_group_avg(0, 1);
        printf("    • 组1(水果) vs 组2(交通) - 预期: 无相关 | 实际相似度: %.4f | %s\n", 
               g1_2, g1_2 < 0.5 ? "✓ 符合预期" : "✗ 不符合预期");
        
        auto g2_3 = compute_inter_group_avg(1, 2);
        printf("    • 组2(交通) vs 组3(战争) - 预期: 无相关 | 实际相似度: %.4f | %s\n", 
               g2_3, g2_3 < 0.5 ? "✓ 符合预期" : "✗ 不符合预期");
        
        auto g3_4 = compute_inter_group_avg(2, 3);
        printf("    • 组3(战争) vs 组4(教育) - 预期: 相似(社会话题) | 实际相似度: %.4f | %s\n", 
               g3_4, g3_4 >= 0.3 ? "✓ 符合预期" : "✗ 不符合预期");
        
        auto g4_5 = compute_inter_group_avg(3, 4);
        printf("    • 组4(教育) vs 组5(天气) - 预期: 无相关 | 实际相似度: %.4f | %s\n", 
               g4_5, g4_5 < 0.5 ? "✓ 符合预期" : "✗ 不符合预期");
        
        printf("\n");
        printf("─────────────────────────────────────────── 评估结果总结 ───────────────────────────────────────────\n\n");
        
        printf("  📊 组内相似度 (语义相似文本应具有较高相似度):\n");
        printf("     平均值: %.4f | 期望值: > 0.7 | %s\n", 
               overall_intra_avg, overall_intra_avg > 0.7 ? "✓ 通过" : "✗ 未通过");
        
        printf("\n  📊 组间区分度 (不同语义组应具有较低相似度):\n");
        float inter_avg = (g1_2 + g2_3 + g4_5) / 3.0f;
        printf("     无相关组平均相似度: %.4f | 期望值: < 0.5 | %s\n", 
               inter_avg, inter_avg < 0.5 ? "✓ 通过" : "✗ 未通过");
        
        printf("\n  📊 语义相似组检测:\n");
        printf("     组3(战争) vs 组4(教育) 相似度: %.4f | 期望值: > 0.3 | %s\n", 
               g3_4, g3_4 > 0.3 ? "✓ 通过" : "✗ 未通过");
        
        printf("\n  📊 整体评估:\n");
        int passed = 0;
        if (overall_intra_avg > 0.7) passed++;
        if (inter_avg < 0.5) passed++;
        if (g3_4 > 0.3) passed++;
        
        if (passed == 3) {
            printf("     ★★★ 模型可用性测试: 全部通过 (3/3) ★★★\n");
        } else if (passed >= 2) {
            printf("     ★★☆ 模型可用性测试: 基本通过 (%d/3) ★★☆\n", passed);
        } else {
            printf("     ★☆☆ 模型可用性测试: 需要优化 (%d/3) ★☆☆\n", passed);
        }
        
        printf("\n═══════════════════════════════════════════════════════════════════════════════════════════════════\n");
        
    } else {
        cout << "\n********************** Qwen3-Embedding Interactive Mode ********************\n"
             << "Commands:\n"
             << "  embed <text>                      - Generate embedding vector for text\n"
             << "  similarity <text1> | <text2>      - Compute cosine similarity between texts\n"
             << "  batch <file>                      - Batch embed texts from file\n"
             << "  save <text> <filename>            - Generate and save embedding to file\n"
             << "  exit                              - Exit program\n"
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
            
            if (input_str.find("embed ") == 0) {
                std::string text = input_str.substr(6);
                
                g_start_time = std::chrono::high_resolution_clock::now();
                std::vector<float> embedding = run_embedding_inference(llmHandle, text);
                
                auto end_time = std::chrono::high_resolution_clock::now();
                auto infer_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - g_start_time);
                
                printf("robot: ");
                print_embedding_info(embedding, infer_time.count() * 1.0);
                
            } else if (input_str.find("similarity ") == 0) {
                std::string rest = input_str.substr(11);
                size_t sep = rest.find(" | ");
                if (sep == std::string::npos) {
                    printf("Usage: similarity <text1> | <text2>\n");
                    continue;
                }
                std::string text1 = rest.substr(0, sep);
                std::string text2 = rest.substr(sep + 3);
                
                g_start_time = std::chrono::high_resolution_clock::now();
                std::vector<float> embedding1 = run_embedding_inference(llmHandle, text1);
                std::vector<float> embedding2 = run_embedding_inference(llmHandle, text2);
                
                auto end_time = std::chrono::high_resolution_clock::now();
                auto infer_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - g_start_time);
                
                float similarity = 0.0f;
                if (!embedding1.empty() && !embedding2.empty() && embedding1.size() == embedding2.size()) {
                    similarity = compute_cosine_similarity(embedding1.data(), embedding2.data(), embedding1.size());
                }
                
                printf("robot: Cosine Similarity: %.4f (Inference Time: %.2f ms)\n", similarity, infer_time.count() * 1.0);
                
            } else if (input_str.find("batch ") == 0) {
                std::string texts_file = input_str.substr(6);
                
                std::ifstream file(texts_file);
                if (!file.is_open()) {
                    printf("Failed to open file: %s\n", texts_file.c_str());
                    continue;
                }
                
                std::vector<std::pair<std::string, std::vector<float>>> results;
                std::string text;
                int text_id = 0;
                
                printf("Processing texts...\n");
                
                while (std::getline(file, text)) {
                    if (text.empty()) continue;
                    
                    std::vector<float> embedding = run_embedding_inference(llmHandle, text);
                    results.push_back({text, embedding});
                    printf("  [%d] Dim: %zu\n", text_id++, embedding.size());
                }
                file.close();
                
                printf("robot: Batch embedding completed. Processed %zu texts.\n", results.size());
                
            } else if (input_str.find("save ") == 0) {
                std::string rest = input_str.substr(5);
                size_t sep = rest.find(" ");
                if (sep == std::string::npos) {
                    printf("Usage: save <text> <filename>\n");
                    continue;
                }
                std::string text = rest.substr(0, sep);
                std::string filename = rest.substr(sep + 1);
                
                g_start_time = std::chrono::high_resolution_clock::now();
                std::vector<float> embedding = run_embedding_inference(llmHandle, text);
                
                auto end_time = std::chrono::high_resolution_clock::now();
                auto infer_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - g_start_time);
                
                if (!embedding.empty()) {
                    save_embedding_to_file(embedding, filename);
                    printf("robot: Embedding saved to %s (dim=%zu, time=%.2f ms)\n", 
                           filename.c_str(), embedding.size(), infer_time.count() * 1.0);
                } else {
                    printf("robot: Failed to generate embedding\n");
                }
                
            } else {
                printf("Unknown command. Use:\n");
                printf("  embed <text>                      - Generate embedding\n");
                printf("  similarity <text1> | <text2>      - Compute similarity\n");
                printf("  batch <file>                      - Batch embed texts\n");
                printf("  save <text> <filename>            - Save embedding to file\n");
            }
        }
    }

    rkllm_destroy(llmHandle);

    return 0;
}
