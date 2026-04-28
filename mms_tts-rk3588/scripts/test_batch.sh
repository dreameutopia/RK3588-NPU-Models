#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --file PATH         Path to text file (default: test/test_texts.txt)"
    echo "  -l, --language LANG     Language code (default: eng)"
    echo "  -m, --max_length LEN    Max input length (default: 200)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 -f my_texts.txt"
    echo "  $0 -l zho -f test/test_zho.txt"
    exit 1
}

LANG="eng"
MAX_LENGTH=200
TEXT_FILE="test/test_texts.txt"

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            TEXT_FILE="$2"
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

if [ ! -f "$TEXT_FILE" ]; then
    echo "Error: Text file not found: $TEXT_FILE"
    exit 1
fi

ENCODER="model/mms_tts_${LANG}_encoder_${MAX_LENGTH}.rknn"
DECODER="model/mms_tts_${LANG}_decoder_${MAX_LENGTH}.rknn"

if [ ! -f "$ENCODER" ]; then
    echo "Error: Encoder model not found: $ENCODER"
    echo "Please run: ./prepare_models.sh -l $LANG"
    exit 1
fi

if [ ! -f "$DECODER" ]; then
    echo "Error: Decoder model not found: $DECODER"
    echo "Please run: ./prepare_models.sh -l $LANG"
    exit 1
fi

OUTPUT_DIR="test/output/${LANG}"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

TOTAL_LINES=$(grep -c . "$TEXT_FILE")

echo "=========================================="
echo "MMS-TTS RK3588 Batch Test"
echo "=========================================="
echo "Language: $LANG"
echo "Encoder: $ENCODER"
echo "Decoder: $DECODER"
echo "Text File: $TEXT_FILE"
echo "Total Lines: $TOTAL_LINES"
echo "Output Directory: $OUTPUT_DIR"
echo "=========================================="
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
LINE_NUM=0

while IFS= read -r text || [ -n "$text" ]; do
    [ -z "$text" ] && continue
    
    LINE_NUM=$((LINE_NUM + 1))
    output="${OUTPUT_DIR}/batch_${LINE_NUM}_${TIMESTAMP}.wav"
    
    echo "[$LINE_NUM/$TOTAL_LINES] Text: $text"
    
    python3 python/mms_tts.py \
        --encoder "$ENCODER" \
        --decoder "$DECODER" \
        --text "$text" \
        --output "$output" \
        --max_length $MAX_LENGTH 2>&1 | grep -E "(saved|Error|duration)"
    
    if [ $? -eq 0 ] && [ -f "$output" ]; then
        echo "    ✓ Output: $output"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "    ✗ Failed to synthesize"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    echo ""
done < "$TEXT_FILE"

echo "=========================================="
echo "Batch test completed!"
echo "=========================================="
echo "Language: $LANG"
echo "Text File: $TEXT_FILE"
echo "Total: $LINE_NUM"
echo "Success: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""
echo "Output files saved to: $OUTPUT_DIR/"
echo ""
echo "To download all outputs:"
echo "  scp -r user@device:/path/to/mms_tts-rk3588/test/output ."
echo "=========================================="
