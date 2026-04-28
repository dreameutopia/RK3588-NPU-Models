#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODEL_PATH="${MODEL_PATH:-../../models/Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm}"
MAX_CONTEXT_LEN=16384
NPU_CORES=3

echo "========================================== "
echo " LLM Model: $MODEL_PATH"
echo " Mode: eval (可用性评估测试)"
echo " NPU Cores: $NPU_CORES"
echo "========================================== "
echo ""

export LD_LIBRARY_PATH=$SCRIPT_DIR/lib:$LD_LIBRARY_PATH
$SCRIPT_DIR/demo $MODEL_PATH $MAX_CONTEXT_LEN $NPU_CORES eval
