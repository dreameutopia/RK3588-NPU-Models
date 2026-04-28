#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RKNN_LLM_PATH="${RKNN_LLM_PATH:-../rknn-llm}"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --source PATH    Path to rknn-llm repository (default: ../rknn-llm)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -s ../rknn-llm"
    echo "  $0 -s /path/to/rknn-llm"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            RKNN_LLM_PATH="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [ ! -d "$RKNN_LLM_PATH" ]; then
    echo "Error: rknn-llm repository not found at: $RKNN_LLM_PATH"
    echo "Please specify the correct path using -s option"
    usage
fi

echo "=========================================="
echo "Setting up DeepSeek-OCR RK3588 deployment"
echo "=========================================="
echo "Source: $RKNN_LLM_PATH"
echo ""

echo "[1/4] Copying RKLLM runtime library..."
mkdir -p lib/aarch64
cp "$RKNN_LLM_PATH/rkllm-runtime/Linux/librkllm_api/aarch64/librkllmrt.so" lib/aarch64/
echo "  -> lib/aarch64/librkllmrt.so"

echo "[2/4] Copying RKNN runtime library..."
mkdir -p 3rdparty/librknnrt/Linux/librknn_api/aarch64
mkdir -p 3rdparty/librknnrt/Linux/librknn_api/include
cp "$RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/librknnrt/Linux/librknn_api/aarch64/librknnrt.so" 3rdparty/librknnrt/Linux/librknn_api/aarch64/
cp "$RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/librknnrt/Linux/librknn_api/include/"* 3rdparty/librknnrt/Linux/librknn_api/include/
echo "  -> 3rdparty/librknnrt/"

echo "[3/4] Copying OpenCV library..."
mkdir -p 3rdparty/opencv
cp -r "$RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/opencv/opencv-linux-aarch64" 3rdparty/opencv/
echo "  -> 3rdparty/opencv/opencv-linux-aarch64"

echo "[4/4] Creating models directory..."
mkdir -p models
echo "  -> models/"

echo ""
echo "=========================================="
echo "Setup completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Copy your models to the models/ directory:"
echo "   cp /path/to/deepseekocr_vision_rk3588.rknn models/"
echo "   cp /path/to/deepseekocr_w4a16_rk3588.rkllm models/"
echo ""
echo "2. Build the demo:"
echo "   ./build.sh"
echo ""
echo "3. Deploy to RK3588 device:"
echo "   adb push install/demo_Linux_aarch64 /data"
echo ""
echo "4. Run on device:"
echo "   cd /data/demo_Linux_aarch64"
echo "   export LD_LIBRARY_PATH=./lib"
echo ""
echo "5. Interactive mode:"
echo "   ./run.sh"
echo ""
echo "6. Single image test:"
echo "   ./test_single.sh"
echo ""
echo "7. Multi-image concurrent test:"
echo "   ./test_multi.sh"
