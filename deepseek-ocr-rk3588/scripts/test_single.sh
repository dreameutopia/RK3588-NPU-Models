#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f "./demo" ]; then
    echo "Error: demo executable not found!"
    echo "Please run build.sh first to compile the demo."
    exit 1
fi

export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH

find_model() {
    local model_name=$1
    local paths=(
        "./models/$model_name"
        "../models/$model_name"
        "../../models/$model_name"
        "$SCRIPT_DIR/models/$model_name"
    )
    
    for path in "${paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    echo ""
    return 1
}

VISION_MODEL=$(find_model "deepseekocr_vision_rk3588.rknn")
LLM_MODEL=$(find_model "deepseekocr_w4a16_rk3588.rkllm")

IMAGE_PATH="./test/test1.png"
if [ ! -f "$IMAGE_PATH" ]; then
    IMAGE_PATH="../test/test1.png"
fi

PROMPT="<image>
Free OCR."

MAX_NEW_TOKENS=256
MAX_CONTEXT_LEN=4096
NPU_CORES=3

IMG_START=""
IMG_END=""
IMG_CONTENT="<｜▁pad▁｜>"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --image PATH      Image path"
    echo "  -p, --prompt TEXT     Prompt text (default: $PROMPT)"
    echo "  -v, --vision MODEL    Vision model path"
    echo "  -l, --llm MODEL       LLM model path"
    echo "  -t, --tokens NUM      Max new tokens (default: $MAX_NEW_TOKENS)"
    echo "  -h, --help            Show this help message"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            IMAGE_PATH="$2"
            shift 2
            ;;
        -p|--prompt)
            PROMPT="$2"
            shift 2
            ;;
        -v|--vision)
            VISION_MODEL="$2"
            shift 2
            ;;
        -l|--llm)
            LLM_MODEL="$2"
            shift 2
            ;;
        -t|--tokens)
            MAX_NEW_TOKENS="$2"
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

if [ -z "$VISION_MODEL" ] || [ ! -f "$VISION_MODEL" ]; then
    echo "Error: Vision model not found!"
    echo "Please copy model to one of these locations:"
    echo "  ./models/deepseekocr_vision_rk3588.rknn"
    echo "  ../models/deepseekocr_vision_rk3588.rknn"
    echo ""
    echo "Or specify with: $0 -v /path/to/model.rknn"
    exit 1
fi

if [ -z "$LLM_MODEL" ] || [ ! -f "$LLM_MODEL" ]; then
    echo "Error: LLM model not found!"
    echo "Please copy model to one of these locations:"
    echo "  ./models/deepseekocr_w4a16_rk3588.rkllm"
    echo "  ../models/deepseekocr_w4a16_rk3588.rkllm"
    echo ""
    echo "Or specify with: $0 -l /path/to/model.rkllm"
    exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found: $IMAGE_PATH"
    exit 1
fi

echo "=========================================="
echo "DeepSeek-OCR RK3588 Single Image Test"
echo "=========================================="
echo "Vision Model: $VISION_MODEL"
echo "LLM Model: $LLM_MODEL"
echo "Image: $IMAGE_PATH"
echo "Prompt: $PROMPT"
echo "=========================================="
echo ""

echo -e "$PROMPT\nexit" | ./demo "$IMAGE_PATH" "$VISION_MODEL" "$LLM_MODEL" "$MAX_NEW_TOKENS" "$MAX_CONTEXT_LEN" "$NPU_CORES" "$IMG_START" "$IMG_END" "$IMG_CONTENT"
