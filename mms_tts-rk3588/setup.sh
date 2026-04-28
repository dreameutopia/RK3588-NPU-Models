#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Setup runtime dependencies for MMS-TTS on RK3588"
    echo ""
    echo "Options:"
    echo "  -s, --src PATH     Path to rknn-llm or rknn_model_zoo directory"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -s ../rknn-llm"
    echo "  $0 -s ../rknn_model_zoo"
    exit 1
}

SRC_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--src)
            SRC_PATH="$2"
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

if [ -z "$SRC_PATH" ]; then
    usage
fi

if [ ! -d "$SRC_PATH" ]; then
    echo "Error: Source directory not found: $SRC_PATH"
    exit 1
fi

echo "=========================================="
echo "Setting up MMS-TTS RK3588 runtime"
echo "=========================================="
echo ""

mkdir -p 3rdparty/librknnrt/Linux/librknn_api/aarch64
mkdir -p 3rdparty/librknnrt/Linux/librknn_api/include

if [ -d "$SRC_PATH/rkllm-runtime/Linux/librkllm_api" ]; then
    echo "Copying from rknn-llm..."
    cp -r "$SRC_PATH/rkllm-runtime/Linux/librknn_api/"* 3rdparty/librknnrt/Linux/librknn_api/ 2>/dev/null || true
elif [ -d "$SRC_PATH/3rdparty/rknpu2" ]; then
    echo "Copying from rknn_model_zoo..."
    cp -r "$SRC_PATH/3rdparty/rknpu2/Linux/aarch64/"* 3rdparty/librknnrt/Linux/librknn_api/aarch64/ 2>/dev/null || true
    cp -r "$SRC_PATH/3rdparty/rknpu2/include/"* 3rdparty/librknnrt/Linux/librknn_api/include/ 2>/dev/null || true
else
    echo "Error: Could not find RKNN runtime libraries in $SRC_PATH"
    exit 1
fi

echo ""
echo "=========================================="
echo "Setup completed!"
echo "=========================================="
echo ""
echo "Runtime libraries installed to: 3rdparty/librknnrt/"
