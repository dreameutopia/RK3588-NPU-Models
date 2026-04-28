#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

if [ -f "$PROJECT_DIR/.venv/bin/activate" ]; then
    source "$PROJECT_DIR/.venv/bin/activate"
fi

ENCODER_MODEL="model/whisper_encoder_base.rknn"
DECODER_MODEL="model/whisper_decoder_base.rknn"
TARGET="rk3588"
OUTPUT_DIR="test/output"

echo "=========================================="
echo "Whisper RK3588 Multi Audio Test"
echo "=========================================="
echo ""

if [ ! -f "$ENCODER_MODEL" ]; then
    echo "Error: Encoder model not found: $ENCODER_MODEL"
    echo "Please run ./prepare_models.sh first"
    exit 1
fi

if [ ! -f "$DECODER_MODEL" ]; then
    echo "Error: Decoder model not found: $DECODER_MODEL"
    echo "Please run ./prepare_models.sh first"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

test_audio() {
    local audio_file=$1
    local task=$2
    local test_name=$3
    
    echo "----------------------------------------"
    echo "Test: $test_name"
    echo "Audio: $audio_file"
    echo "Task: $task"
    echo ""
    
    if [ ! -f "$audio_file" ]; then
        echo "Warning: Audio file not found: $audio_file"
        echo "Skipping..."
        return
    fi
    
    python python/whisper.py \
        --encoder_model "$ENCODER_MODEL" \
        --decoder_model "$DECODER_MODEL" \
        --audio "$audio_file" \
        --task "$task" \
        --target "$TARGET" \
        --model_dir model
    
    echo ""
}

echo "Running test cases..."
echo ""

test_audio "test/audio/test_en.wav" "en" "English Test 1"
test_audio "test/audio/test_zh.wav" "zh" "Chinese Test 1"

echo "=========================================="
echo "All tests completed!"
echo "=========================================="
