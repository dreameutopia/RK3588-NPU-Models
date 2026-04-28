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
AUDIO_PATH="test/audio/test1.mp3"
TASK="en"
TARGET="rk3588"
OUTPUT_DIR="test/output"

usage() {
    echo "Usage: $0 [-a <audio_path>] [-t <task>] [-e <encoder_model>] [-d <decoder_model>] [-o <output_dir>]"
    echo ""
    echo "Options:"
    echo "  -a <audio_path>      Input audio file (default: test/audio/test1.mp3)"
    echo "  -t <task>            Recognition task: en or zh (default: en)"
    echo "  -e <encoder_model>   Encoder model path (default: model/whisper_encoder_base.rknn)"
    echo "  -d <decoder_model>   Decoder model path (default: model/whisper_decoder_base.rknn)"
    echo "  -o <output_dir>      Output directory (default: test/output)"
    echo "  -h                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                              # Test default audio (test/audio/test1.mp3)"
    echo "  $0 -a test/audio/test_en.wav    # Test specific audio"
    echo "  $0 -a test/audio/test_zh.wav -t zh  # Test Chinese audio"
    exit 1
}

while getopts "a:t:e:d:o:h" opt; do
    case $opt in
        a) AUDIO_PATH="$OPTARG" ;;
        t) TASK="$OPTARG" ;;
        e) ENCODER_MODEL="$OPTARG" ;;
        d) DECODER_MODEL="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ ! -f "$AUDIO_PATH" ]; then
    echo "Error: Audio file not found: $AUDIO_PATH"
    echo ""
    echo "Please put your audio file at: test/audio/test1.mp3"
    echo "Or specify a different audio file with -a option"
    exit 1
fi

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

echo "=========================================="
echo "Whisper RK3588 Single Audio Test"
echo "=========================================="
echo ""
echo "Audio: $AUDIO_PATH"
echo "Task: $TASK"
echo "Encoder: $ENCODER_MODEL"
echo "Decoder: $DECODER_MODEL"
echo ""

python python/whisper.py \
    --encoder_model "$ENCODER_MODEL" \
    --decoder_model "$DECODER_MODEL" \
    --audio "$AUDIO_PATH" \
    --task "$TASK" \
    --target "$TARGET" \
    --model_dir model

echo ""
echo "Test completed!"
