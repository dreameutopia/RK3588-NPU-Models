#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Download pre-converted MMS-TTS ONNX models from rknn_model_zoo"
    echo ""
    echo "Options:"
    echo "  -l, --language LANG     Language code (default: eng)"
    echo "  -m, --max_length LEN    Max input length (default: 200)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 -l eng -m 200"
    exit 1
}

LANG="eng"
MAX_LENGTH=200

while [[ $# -gt 0 ]]; do
    case $1 in
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

echo "=========================================="
echo "Downloading MMS-TTS ONNX models"
echo "Language: $LANG"
echo "Max Length: $MAX_LENGTH"
echo "=========================================="
echo ""

mkdir -p onnx model

ONNX_DIR="onnx"

if [ "$LANG" = "eng" ] && [ "$MAX_LENGTH" = "200" ]; then
    echo "Downloading pre-converted English models from rknn_model_zoo..."
    
    wget -O "$ONNX_DIR/mms_tts_eng_encoder_200.onnx" \
        https://ftrg.zbox.filez.com/v2/delivery/data/95f00b0fc900458ba134f8b180b3f7a1/examples/mms_tts/mms_tts_eng_encoder_200.onnx
    
    wget -O "$ONNX_DIR/mms_tts_eng_decoder_200.onnx" \
        https://ftrg.zbox.filez.com/v2/delivery/data/95f00b0fc900458ba134f8b180b3f7a1/examples/mms_tts/mms_tts_eng_decoder_200.onnx
    
    echo ""
    echo "Download completed!"
    echo "Encoder: $ONNX_DIR/mms_tts_eng_encoder_200.onnx"
    echo "Decoder: $ONNX_DIR/mms_tts_eng_decoder_200.onnx"
else
    echo "Pre-converted model not available for $LANG with max_length=$MAX_LENGTH"
    echo "Please export manually:"
    echo ""
    echo "  pip install transformers torch"
    echo "  python3 python/export_onnx.py --language $LANG --max_length $MAX_LENGTH"
fi

echo ""
echo "Next steps:"
echo "  python3 python/convert_rknn.py \\"
echo "    --encoder $ONNX_DIR/mms_tts_${LANG}_encoder_${MAX_LENGTH}.onnx \\"
echo "    --decoder $ONNX_DIR/mms_tts_${LANG}_decoder_${MAX_LENGTH}.onnx \\"
echo "    --target rk3588"
