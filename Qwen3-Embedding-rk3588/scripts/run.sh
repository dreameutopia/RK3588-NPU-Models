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

LLM_MODEL=$(find_model "Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm")

MAX_CONTEXT_LEN=4096
NPU_CORES=3

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -l, --llm MODEL       LLM model path"
    echo "  -c, --context NUM     Max context length (default: $MAX_CONTEXT_LEN)"
    echo "  -n, --cores NUM       NPU cores (default: $NPU_CORES for RK3588)"
    echo "  -h, --help            Show this help message"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--llm)
            LLM_MODEL="$2"
            shift 2
            ;;
        -c|--context)
            MAX_CONTEXT_LEN="$2"
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

if [ -z "$LLM_MODEL" ] || [ ! -f "$LLM_MODEL" ]; then
    echo "Error: LLM model not found!"
    echo "Please copy model to one of these locations:"
    echo "  ./models/Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm"
    echo "  ../models/Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm"
    exit 1
fi

echo "=========================================="
echo "Qwen3-Embedding RK3588 Demo"
echo "=========================================="
echo "LLM Model: $LLM_MODEL"
echo "Max Context: $MAX_CONTEXT_LEN"
echo "NPU Cores: $NPU_CORES"
echo "=========================================="
echo ""
echo "Interactive mode - Commands:"
echo "  embed <text>                      - Generate embedding vector for text"
echo "  similarity <text1> | <text2>      - Compute cosine similarity between texts"
echo "  batch <file>                      - Batch embed texts from file"
echo "  save <text> <filename>            - Generate and save embedding to file"
echo "  exit                              - Exit program"
echo ""

./demo "$LLM_MODEL" "$MAX_CONTEXT_LEN" "$NPU_CORES" "interactive"
