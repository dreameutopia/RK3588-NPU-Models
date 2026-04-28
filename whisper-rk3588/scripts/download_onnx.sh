#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

ONNX_DIR="onnx"
MODEL_DIR="model"

ENCODER_ONNX_URL="https://ftrg.zbox.filez.com/v2/delivery/data/95f00b0fc900458ba134f8b180b3f7a1/examples/whisper/whisper_encoder_base_20s.onnx"
DECODER_ONNX_URL="https://ftrg.zbox.filez.com/v2/delivery/data/95f00b0fc900458ba134f8b180b3f7a1/examples/whisper/whisper_decoder_base_20s.onnx"

echo "=========================================="
echo "Whisper RK3588 ONNX Model Download"
echo "=========================================="
echo ""

mkdir -p $ONNX_DIR $MODEL_DIR

if [ -f "$ONNX_DIR/whisper_encoder_base.onnx" ] && [ -f "$ONNX_DIR/whisper_decoder_base.onnx" ]; then
    echo "ONNX models already exist, skipping download..."
    echo "  - $ONNX_DIR/whisper_encoder_base.onnx"
    echo "  - $ONNX_DIR/whisper_decoder_base.onnx"
else
    echo "Downloading encoder model..."
    wget -O "$ONNX_DIR/whisper_encoder_base.onnx" "$ENCODER_ONNX_URL"
    echo "Done!"
    
    echo ""
    echo "Downloading decoder model..."
    wget -O "$ONNX_DIR/whisper_decoder_base.onnx" "$DECODER_ONNX_URL"
    echo "Done!"
fi

echo ""
echo "Copying vocab and mel filter files..."

if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/vocab_en.txt" ]; then
    cp /workspace/rknn_model_zoo/examples/whisper/model/vocab_en.txt "$MODEL_DIR/"
    echo "  - vocab_en.txt copied"
else
    echo "Warning: vocab_en.txt not found in rknn_model_zoo"
fi

if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/vocab_zh.txt" ]; then
    cp /workspace/rknn_model_zoo/examples/whisper/model/vocab_zh.txt "$MODEL_DIR/"
    echo "  - vocab_zh.txt copied"
else
    echo "Warning: vocab_zh.txt not found in rknn_model_zoo"
fi

if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/mel_80_filters.txt" ]; then
    cp /workspace/rknn_model_zoo/examples/whisper/model/mel_80_filters.txt "$MODEL_DIR/"
    echo "  - mel_80_filters.txt copied"
else
    echo "Warning: mel_80_filters.txt not found in rknn_model_zoo"
fi

echo ""
echo "Copying test audio files..."

mkdir -p test/audio

if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/test_en.wav" ]; then
    cp /workspace/rknn_model_zoo/examples/whisper/model/test_en.wav test/audio/
    echo "  - test_en.wav copied"
else
    echo "Warning: test_en.wav not found in rknn_model_zoo"
fi

if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/test_zh.wav" ]; then
    cp /workspace/rknn_model_zoo/examples/whisper/model/test_zh.wav test/audio/
    echo "  - test_zh.wav copied"
else
    echo "Warning: test_zh.wav not found in rknn_model_zoo"
fi

echo ""
echo "=========================================="
echo "Download completed!"
echo "=========================================="
echo ""
echo "Downloaded files:"
ls -lh $ONNX_DIR/*.onnx 2>/dev/null || echo "  No ONNX files found"
echo ""
echo "Model support files:"
ls -lh $MODEL_DIR/*.txt 2>/dev/null || echo "  No support files found"
echo ""
echo "Test audio files:"
ls -lh test/audio/*.wav 2>/dev/null || echo "  No test audio files found"
echo ""
echo "Next steps:"
echo "  1. Convert ONNX to RKNN: python3 python/convert_rknn.py --onnx onnx/whisper_encoder_base.onnx --target rk3588"
echo "  2. Or use prepare_models.sh for automatic conversion"
