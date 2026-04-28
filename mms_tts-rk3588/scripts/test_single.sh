#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# 激活虚拟环境
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --text TEXT         Text to synthesize (required)"
    echo "  -o, --output PATH       Output audio file (default: output.wav)"
    echo "  -l, --language LANG     Language code (default: eng)"
    echo "  -m, --max_length LEN    Max input length (default: 200)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -t 'Hello world'"
    echo "  $0 -t 'Hello world' -o result.wav"
    exit 1
}

TEXT=""
OUTPUT=""
LANG="eng"
MAX_LENGTH=200

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--text)
            TEXT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -l|--language)
            LANG="$2"
            shift 2
            ;;
        -m|--max_length)
            MAX_LENGTH="$2"
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

if [ -z "$TEXT" ]; then
    echo "Error: Text is required!"
    usage
fi

ENCODER="model/mms_tts_${LANG}_encoder_${MAX_LENGTH}.rknn"
DECODER="model/mms_tts_${LANG}_decoder_${MAX_LENGTH}.rknn"

if [ ! -f "$ENCODER" ]; then
    echo "Error: Encoder model not found: $ENCODER"
    echo "Please prepare the model first."
    exit 1
fi

if [ ! -f "$DECODER" ]; then
    echo "Error: Decoder model not found: $DECODER"
    exit 1
fi

OUTPUT_DIR="test/output/${LANG}"
mkdir -p "$OUTPUT_DIR"

if [ -z "$OUTPUT" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT="${OUTPUT_DIR}/single_${TIMESTAMP}.wav"
fi

echo "=========================================="
echo "MMS-TTS RK3588 Single Test"
echo "=========================================="
echo "Language: $LANG"
echo "Encoder: $ENCODER"
echo "Decoder: $DECODER"
echo "Max Length: $MAX_LENGTH"
echo "Text: $TEXT"
echo "Output: $OUTPUT"
echo "=========================================="

python3 python/mms_tts.py \
    --encoder "$ENCODER" \
    --decoder "$DECODER" \
    --text "$TEXT" \
    --output "$OUTPUT" \
    --max_length $MAX_LENGTH

echo ""
echo "Test completed!"
echo "Audio saved to: $OUTPUT"
