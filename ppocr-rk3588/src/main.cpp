#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <iostream>
#include <string>

#include "opencv2/opencv.hpp"
#include "rknn_api.h"
#include "ppocr_system.h"

static void print_usage(const char* prog_name)
{
    printf("Usage: %s [options]\n", prog_name);
    printf("Options:\n");
    printf("  -d, --det_model <path>   Path to detection model (default: model/ppocrv4_det_serverial.rknn)\n");
    printf("  -r, --rec_model <path>   Path to recognition model (default: model/ppocrv4_rec_serverial.rknn)\n");
    printf("  -i, --image <path>       Path to input image\n");
    printf("  -o, --output <path>      Path to output image with boxes drawn (optional)\n");
    printf("  -t, --threshold <float>  Detection threshold (default: 0.3)\n");
    printf("  -b, --box_threshold <float> Box threshold (default: 0.5)\n");
    printf("  -h, --help               Show this help message\n");
}

int main(int argc, char* argv[])
{
    char* det_model_path = (char*)"model/ppocrv4_det_serverial.rknn";
    char* rec_model_path = (char*)"model/ppocrv4_rec_serverial.rknn";
    char* image_path = NULL;
    char* output_path = NULL;
    float det_threshold = 0.3f;
    float box_threshold = 0.5f;

    static struct option long_options[] = {
        {"det_model", required_argument, 0, 'd'},
        {"rec_model", required_argument, 0, 'r'},
        {"image", required_argument, 0, 'i'},
        {"output", required_argument, 0, 'o'},
        {"threshold", required_argument, 0, 't'},
        {"box_threshold", required_argument, 0, 'b'},
        {"help", no_argument, 0, 'h'},
        {0, 0, 0, 0}
    };

    int opt;
    int option_index = 0;
    while ((opt = getopt_long(argc, argv, "d:r:i:o:t:b:h", long_options, &option_index)) != -1) {
        switch (opt) {
            case 'd':
                det_model_path = optarg;
                break;
            case 'r':
                rec_model_path = optarg;
                break;
            case 'i':
                image_path = optarg;
                break;
            case 'o':
                output_path = optarg;
                break;
            case 't':
                det_threshold = atof(optarg);
                break;
            case 'b':
                box_threshold = atof(optarg);
                break;
            case 'h':
            default:
                print_usage(argv[0]);
                return 0;
        }
    }

    if (image_path == NULL) {
        printf("Error: Input image path is required!\n");
        print_usage(argv[0]);
        return -1;
    }

    printf("PPOCR System for RK3588\n");
    printf("Detection model: %s\n", det_model_path);
    printf("Recognition model: %s\n", rec_model_path);
    printf("Input image: %s\n", image_path);
    printf("Detection threshold: %.2f\n", det_threshold);
    printf("Box threshold: %.2f\n", box_threshold);

    cv::Mat image = cv::imread(image_path);
    if (image.empty()) {
        printf("Error: Failed to load image %s\n", image_path);
        return -1;
    }
    printf("Image size: %d x %d\n", image.cols, image.rows);

    ppocr_system_app_context sys_ctx;
    memset(&sys_ctx, 0, sizeof(ppocr_system_app_context));

    printf("\n[1/3] Loading detection model...\n");
    int ret = init_ppocr_model(det_model_path, &sys_ctx.det_context);
    if (ret != 0) {
        printf("Failed to init detection model! ret=%d\n", ret);
        return -1;
    }

    printf("\n[2/3] Loading recognition model...\n");
    ret = init_ppocr_model(rec_model_path, &sys_ctx.rec_context);
    if (ret != 0) {
        printf("Failed to init recognition model! ret=%d\n", ret);
        release_ppocr_model(&sys_ctx.det_context);
        return -1;
    }

    printf("\n[3/3] Running OCR inference...\n");
    ppocr_det_postprocess_params params;
    params.threshold = det_threshold;
    params.box_threshold = box_threshold;
    params.use_dilate = false;
    params.db_score_mode = "fast";
    params.db_unclip_ratio = 1.5f;
    params.db_box_type = "quad";

    ppocr_text_recog_array_result_t results;
    memset(&results, 0, sizeof(results));

    ret = inference_ppocr_system_model(&sys_ctx, image.data, image.rows, image.cols, 3, &params, &results);
    if (ret != 0) {
        printf("OCR inference failed! ret=%d\n", ret);
        release_ppocr_model(&sys_ctx.det_context);
        release_ppocr_model(&sys_ctx.rec_context);
        return -1;
    }

    printf("\n========== OCR Results ==========\n");
    printf("Detected %d text regions\n\n", results.count);
    
    for (int i = 0; i < results.count; i++) {
        printf("[%d] Text: %s\n", i + 1, results.text_result[i].text.str);
        printf("    Score: %.4f\n", results.text_result[i].text.score);
        printf("    Box: (%d,%d) -> (%d,%d) -> (%d,%d) -> (%d,%d)\n",
               results.text_result[i].box.left_top.x, results.text_result[i].box.left_top.y,
               results.text_result[i].box.right_top.x, results.text_result[i].box.right_top.y,
               results.text_result[i].box.right_bottom.x, results.text_result[i].box.right_bottom.y,
               results.text_result[i].box.left_bottom.x, results.text_result[i].box.left_bottom.y);
        printf("\n");
    }
    printf("=================================\n");

    if (output_path != NULL) {
        printf("\nDrawing result boxes to %s\n", output_path);
        cv::Mat output_image;
        image.copyTo(output_image);
        
        for (int i = 0; i < results.count; i++) {
            std::vector<cv::Point> pts;
            pts.push_back(cv::Point(results.text_result[i].box.left_top.x, results.text_result[i].box.left_top.y));
            pts.push_back(cv::Point(results.text_result[i].box.right_top.x, results.text_result[i].box.right_top.y));
            pts.push_back(cv::Point(results.text_result[i].box.right_bottom.x, results.text_result[i].box.right_bottom.y));
            pts.push_back(cv::Point(results.text_result[i].box.left_bottom.x, results.text_result[i].box.left_bottom.y));
            
            cv::polylines(output_image, pts, true, cv::Scalar(0, 255, 0), 2);
            
            cv::putText(output_image, results.text_result[i].text.str, 
                        cv::Point(results.text_result[i].box.left_top.x, results.text_result[i].box.left_top.y - 5),
                        cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0, 0, 255), 1);
        }
        
        cv::imwrite(output_path, output_image);
        printf("Output saved!\n");
    }

    release_ppocr_model(&sys_ctx.det_context);
    release_ppocr_model(&sys_ctx.rec_context);

    printf("\nDone!\n");
    return 0;
}
