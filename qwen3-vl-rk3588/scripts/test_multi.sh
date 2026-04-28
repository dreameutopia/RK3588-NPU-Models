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

VISION_MODEL=$(find_model "qwen3-vl-2b_vision_rk3588.rknn")
LLM_MODEL=$(find_model "qwen3-vl-2b-instruct_w8a8_rk3588.rkllm")

IMAGES=(
    "./test/test1.png"
    "./test/test2.png"
    "./test/test3.png"
)

PROMPT="<image>请识别图片中的所有文字，直接输出识别结果。"

MAX_NEW_TOKENS=256
MAX_CONTEXT_LEN=4096
NPU_CORES=3

IMG_START="<|vision_start|>"
IMG_END="<|vision_end|>"
IMG_CONTENT="<|image_pad|>"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --prompt TEXT     Prompt text (default: $PROMPT)"
    echo "  -v, --vision MODEL    Vision model path"
    echo "  -l, --llm MODEL       LLM model path"
    echo "  -t, --tokens NUM      Max new tokens (default: $MAX_NEW_TOKENS)"
    echo "  -n, --cores NUM       NPU cores (default: $NPU_CORES for RK3588)"
    echo "  -h, --help            Show this help message"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
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
        -n|--cores)
            NPU_CORES="$2"
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
    echo "  ./models/qwen3-vl-2b_vision_rk3588.rknn"
    echo "  ../models/qwen3-vl-2b_vision_rk3588.rknn"
    exit 1
fi

if [ -z "$LLM_MODEL" ] || [ ! -f "$LLM_MODEL" ]; then
    echo "Error: LLM model not found!"
    echo "Please copy model to one of these locations:"
    echo "  ./models/qwen3-vl-2b-instruct_w8a8_rk3588.rkllm"
    echo "  ../models/qwen3-vl-2b-instruct_w8a8_rk3588.rkllm"
    exit 1
fi

echo "=========================================="
echo "Qwen3-VL RK3588 Multi-Image Concurrent Test"
echo "=========================================="
echo "Vision Model: $VISION_MODEL"
echo "LLM Model: $LLM_MODEL"
echo "Images: ${IMAGES[*]}"
echo "Prompt: $PROMPT"
echo "NPU Cores: $NPU_CORES"
echo "=========================================="
echo ""

run_single_test() {
    local image_path=$1
    local task_id=$2
    local log_file="/tmp/qwen3vl_task_${task_id}.log"
    
    if [ ! -f "$image_path" ]; then
        local alt_path="../test/$(basename $image_path)"
        if [ -f "$alt_path" ]; then
            image_path="$alt_path"
        else
            echo "[Task $task_id] Error: Image not found: $image_path"
            return 1
        fi
    fi
    
    echo "[Task $task_id] Starting inference for: $image_path"
    echo "[Task $task_id] Start Time: $(date '+%Y-%m-%d %H:%M:%S.%3N')"
    
    local start_time=$(date +%s%3N)
    
    echo -e "$PROMPT\nexit" | ./demo "$image_path" "$VISION_MODEL" "$LLM_MODEL" "$MAX_NEW_TOKENS" "$MAX_CONTEXT_LEN" "$NPU_CORES" "$IMG_START" "$IMG_END" "$IMG_CONTENT" > "$log_file" 2>&1
    
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    echo "[Task $task_id] End Time: $(date '+%Y-%m-%d %H:%M:%S.%3N')"
    echo "[Task $task_id] Total Duration: ${duration} ms"
    echo ""
    echo "[Task $task_id] ========== Output =========="
    cat "$log_file"
    echo "[Task $task_id] ============================"
    echo ""
    
    rm -f "$log_file"
}

echo "Starting concurrent inference for ${#IMAGES[@]} images..."
echo ""

OVERALL_START=$(date +%s%3N)

for i in "${!IMAGES[@]}"; do
    run_single_test "${IMAGES[$i]}" "$i" &
done

wait

OVERALL_END=$(date +%s%3N)
OVERALL_DURATION=$((OVERALL_END - OVERALL_START))

echo ""
echo "=========================================="
echo "Multi-Image Concurrent Test Summary"
echo "=========================================="
echo "Total Images: ${#IMAGES[@]}"
echo "Overall Duration: ${OVERALL_DURATION} ms"
echo "Average Duration per Image: $((OVERALL_DURATION / ${#IMAGES[@]})) ms"
echo "=========================================="
