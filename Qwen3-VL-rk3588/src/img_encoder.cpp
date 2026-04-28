#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <chrono>
#include <opencv2/opencv.hpp>
#include "image_enc.h"

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
    if (argc < 4) {
        std::cerr << "Usage:\n"
                << "  " << argv[0]
                << " <model_path> <image_path> <core_num>\n\n"
                << "Arguments:\n"
                << "  model_path       Path to the RKNN model file\n"
                << "  image_path       Path to the input image\n"
                << "  core_num         Number of NPU cores (1/2/3)\n";
        return -1;
    }

    const char * model_path = argv[1];
    const char * image_path = argv[2];
    const int core_num = atoi(argv[3]);

    int ret;
    rknn_app_context_t rknn_app_ctx;
    memset(&rknn_app_ctx, 0, sizeof(rknn_app_context_t));

    auto t_start = std::chrono::high_resolution_clock::now();

    ret = init_imgenc(model_path, &rknn_app_ctx, core_num);
    if (ret != 0) {
        printf("init_imgenc fail! ret=%d model_path=%s\n", ret, model_path);
        return -1;
    }

    auto t_load_end = std::chrono::high_resolution_clock::now();
    auto load_time = std::chrono::duration_cast<std::chrono::microseconds>(t_load_end - t_start);
    printf("%s: Model loaded in %8.2f ms\n", __func__, load_time.count() / 1000.0);

    cv::Mat img = cv::imread(image_path);
    cv::cvtColor(img, img, cv::COLOR_BGR2RGB);

    cv::Scalar background_color(127.5, 127.5, 127.5);
    cv::Mat square_img = expand2square(img, background_color);

    cv::Mat resized_img;
    cv::Size new_size(rknn_app_ctx.model_width, rknn_app_ctx.model_height);
    cv::resize(square_img, resized_img, new_size, 0, 0, cv::INTER_LINEAR);

    float img_vec[rknn_app_ctx.model_image_token * rknn_app_ctx.model_embed_size];
    
    auto t_enc_start = std::chrono::high_resolution_clock::now();
    ret = run_imgenc(&rknn_app_ctx, resized_img.data, img_vec);
    if (ret != 0) {
        printf("run_imgenc fail! ret=%d\n", ret);
    }
    auto t_enc_end = std::chrono::high_resolution_clock::now();
    auto enc_time = std::chrono::duration_cast<std::chrono::microseconds>(t_enc_end - t_enc_start);
    printf("%s: Image encoding cost %8.2f ms\n", __func__, enc_time.count() / 1000.0);
    
    std::ofstream file("./img_vec.bin", std::ios::binary);
    file.write(reinterpret_cast<char*>(img_vec), sizeof(img_vec));
    file.close();
    printf("Image features saved to img_vec.bin\n");

    ret = release_imgenc(&rknn_app_ctx);
    if (ret != 0) {
        printf("release_imgenc fail! ret=%d\n", ret);
    }

    return 0;
}
