#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Setting up PPOCR RK3588 dependencies"
echo "=========================================="

RKNN_LLM_PATH="${1:-../rknn-llm}"

if [ ! -d "$RKNN_LLM_PATH" ]; then
    echo "Error: rknn-llm path not found: $RKNN_LLM_PATH"
    echo "Usage: $0 [rknn-llm-path]"
    echo "Example: $0 ../rknn-llm"
    exit 1
fi

echo "[1/3] Copying RKNN runtime library..."
mkdir -p 3rdparty/librknnrt/Linux/librknn_api/aarch64
mkdir -p 3rdparty/librknnrt/Linux/librknn_api/include

if [ -d "$RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/librknnrt" ]; then
    cp -r $RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/librknnrt/Linux/librknn_api/aarch64/librknnrt.so 3rdparty/librknnrt/Linux/librknn_api/aarch64/
    cp -r $RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/librknnrt/Linux/librknn_api/include/* 3rdparty/librknnrt/Linux/librknn_api/include/
    echo "  RKNN runtime copied successfully"
else
    echo "  Warning: RKNN runtime not found in expected location"
fi

echo "[2/3] Copying OpenCV library..."
mkdir -p 3rdparty/opencv
if [ -d "$RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/opencv" ]; then
    cp -r $RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/opencv/opencv-linux-aarch64 3rdparty/opencv/
    echo "  OpenCV copied successfully"
else
    echo "  Warning: OpenCV not found in expected location"
fi

echo "[3/3] Creating directories..."
mkdir -p model test

echo "=========================================="
echo "Setup completed for RK3588!"
echo ""
echo "Project structure:"
ls -la
echo ""
echo "Next steps:"
echo "1. Run: ./prepare_models.sh"
echo "   This will download and convert ONNX models to RKNN format for RK3588"
echo ""
echo "2. Build the project:"
echo "   ./build.sh"
echo ""
echo "3. Run OCR inference:"
echo "   ./scripts/test_single.sh -i test/test1.png"
echo "=========================================="
