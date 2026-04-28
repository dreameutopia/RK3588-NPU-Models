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
echo "Setting up InternVL3 RK3588 deployment"
echo "=========================================="
echo "Source: $RKNN_LLM_PATH"
echo ""

RKLLM_RT_PATH="$RKNN_LLM_PATH/rkllm-runtime/Linux/librkllm_api"
RKNN_RT_PATH="$RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/librknnrt"
OPENCV_PATH="$RKNN_LLM_PATH/examples/multimodal_model_demo/deploy/3rdparty/opencv"

check_file() {
    local file_path="$1"
    local description="$2"
    if [ ! -f "$file_path" ]; then
        echo "Error: $description not found at: $file_path"
        return 1
    fi
    return 0
}

echo "[1/4] Copying RKLLM runtime library..."
mkdir -p lib/aarch64
if check_file "$RKLLM_RT_PATH/aarch64/librkllmrt.so" "RKLLM runtime library"; then
    cp "$RKLLM_RT_PATH/aarch64/librkllmrt.so" lib/aarch64/
    echo "  -> lib/aarch64/librkllmrt.so"
else
    echo "  Warning: Skipping RKLLM runtime library"
fi

echo "[2/4] Copying RKNN runtime library..."
mkdir -p 3rdparty/librknnrt/Linux/librknn_api/aarch64
mkdir -p 3rdparty/librknnrt/Linux/librknn_api/include
if check_file "$RKNN_RT_PATH/Linux/librknn_api/aarch64/librknnrt.so" "RKNN runtime library"; then
    cp "$RKNN_RT_PATH/Linux/librknn_api/aarch64/librknnrt.so" 3rdparty/librknnrt/Linux/librknn_api/aarch64/
    echo "  -> 3rdparty/librknnrt/Linux/librknn_api/aarch64/librknnrt.so"
fi
if [ -d "$RKNN_RT_PATH/Linux/librknn_api/include" ]; then
    cp "$RKNN_RT_PATH/Linux/librknn_api/include/"* 3rdparty/librknnrt/Linux/librknn_api/include/ 2>/dev/null || true
    echo "  -> 3rdparty/librknnrt/Linux/librknn_api/include/"
fi

echo "[3/4] Copying OpenCV library..."
mkdir -p 3rdparty/opencv
if [ -d "$OPENCV_PATH/opencv-linux-aarch64" ]; then
    cp -r "$OPENCV_PATH/opencv-linux-aarch64" 3rdparty/opencv/
    echo "  -> 3rdparty/opencv/opencv-linux-aarch64"
else
    echo "  Warning: OpenCV library not found at $OPENCV_PATH/opencv-linux-aarch64"
fi

echo "[4/4] Creating models directory..."
mkdir -p models
echo "  -> models/"

echo ""
echo "=========================================="
echo "Verifying setup..."
echo "=========================================="

ERRORS=0

if [ ! -f "lib/aarch64/librkllmrt.so" ]; then
    echo "  [MISSING] lib/aarch64/librkllmrt.so"
    ERRORS=$((ERRORS + 1))
else
    echo "  [OK] lib/aarch64/librkllmrt.so"
fi

if [ ! -f "3rdparty/librknnrt/Linux/librknn_api/aarch64/librknnrt.so" ]; then
    echo "  [MISSING] 3rdparty/librknnrt/Linux/librknn_api/aarch64/librknnrt.so"
    ERRORS=$((ERRORS + 1))
else
    echo "  [OK] 3rdparty/librknnrt/Linux/librknn_api/aarch64/librknnrt.so"
fi

if [ ! -d "3rdparty/opencv/opencv-linux-aarch64" ]; then
    echo "  [MISSING] 3rdparty/opencv/opencv-linux-aarch64"
    ERRORS=$((ERRORS + 1))
else
    echo "  [OK] 3rdparty/opencv/opencv-linux-aarch64"
fi

if [ ! -f "include/rkllm.h" ]; then
    echo "  [MISSING] include/rkllm.h"
    ERRORS=$((ERRORS + 1))
else
    echo "  [OK] include/rkllm.h"
fi

if [ ! -f "include/rknn_api.h" ]; then
    echo "  [MISSING] include/rknn_api.h"
    ERRORS=$((ERRORS + 1))
else
    echo "  [OK] include/rknn_api.h"
fi

echo ""
if [ $ERRORS -gt 0 ]; then
    echo "=========================================="
    echo "Setup completed with $ERRORS error(s)!"
    echo "=========================================="
    echo ""
    echo "Please check the missing files above."
else
    echo "=========================================="
    echo "Setup completed successfully!"
    echo "=========================================="
fi

echo ""
echo "Next steps:"
echo "1. Copy your models to the models/ directory:"
echo "   cp /path/to/internvl3-1b_vision_fp16_rk3588.rknn models/"
echo "   cp /path/to/internvl3-1b_w8a8_rk3588.rkllm models/"
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
