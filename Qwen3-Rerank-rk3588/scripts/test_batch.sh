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

LLM_MODEL=$(find_model "Qwen3-Reranker-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm")

QUERY="What is machine learning and how does it work?"
DOCUMENTS_FILE="./test/documents.txt"

MAX_CONTEXT_LEN=4096
NPU_CORES=3

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -q, --query TEXT      Query text"
    echo "  -f, --file PATH       Documents file path"
    echo "  -l, --llm MODEL       LLM model path"
    echo "  -c, --context NUM     Max context length (default: $MAX_CONTEXT_LEN)"
    echo "  -n, --cores NUM       NPU cores (default: $NPU_CORES for RK3588)"
    echo "  -h, --help            Show this help message"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--query)
            QUERY="$2"
            shift 2
            ;;
        -f|--file)
            DOCUMENTS_FILE="$2"
            shift 2
            ;;
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
    echo "  ./models/Qwen3-Reranker-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm"
    echo "  ../models/Qwen3-Reranker-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm"
    echo ""
    echo "Or specify with: $0 -l /path/to/model.rkllm"
    exit 1
fi

if [ ! -f "$DOCUMENTS_FILE" ]; then
    echo "Creating sample documents file: $DOCUMENTS_FILE"
    mkdir -p "$(dirname "$DOCUMENTS_FILE")"
    cat > "$DOCUMENTS_FILE" << 'EOF'
Machine learning is a subset of artificial intelligence that enables systems to learn and improve from experience.
The weather today is sunny with temperatures around 25 degrees Celsius.
Deep learning is a type of machine learning that uses neural networks with many layers.
Python is a popular programming language used for web development and data science.
Natural language processing allows computers to understand and generate human language.
EOF
fi

echo "=========================================="
echo "Qwen3-Rerank RK3588 Batch Test"
echo "=========================================="
echo "LLM Model: $LLM_MODEL"
echo "Query: $QUERY"
echo "Documents File: $DOCUMENTS_FILE"
echo "NPU Cores: $NPU_CORES"
echo "=========================================="
echo ""

./demo "$LLM_MODEL" "$MAX_CONTEXT_LEN" "$NPU_CORES" "batch" "$QUERY" "$DOCUMENTS_FILE"
