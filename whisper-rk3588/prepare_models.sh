#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODEL_DIR="model"
ONNX_DIR="onnx"

ENCODER_ONNX_URL="https://ftrg.zbox.filez.com/v2/delivery/data/95f00b0fc900458ba134f8b180b3f7a1/examples/whisper/whisper_encoder_base_20s.onnx"
DECODER_ONNX_URL="https://ftrg.zbox.filez.com/v2/delivery/data/95f00b0fc900458ba134f8b180b3f7a1/examples/whisper/whisper_decoder_base_20s.onnx"

echo "=========================================="
echo "Whisper RK3588 Model Preparation"
echo "=========================================="
echo ""

mkdir -p $MODEL_DIR $ONNX_DIR

download_onnx_models() {
    echo "[Step 1/4] Downloading ONNX models..."
    echo ""
    
    if [ -f "$ONNX_DIR/whisper_encoder_base.onnx" ] && [ -f "$ONNX_DIR/whisper_decoder_base.onnx" ]; then
        echo "ONNX models already exist, skipping download..."
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
}

copy_support_files() {
    echo "[Step 2/4] Copying support files..."
    echo ""
    
    if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/vocab_en.txt" ]; then
        cp /workspace/rknn_model_zoo/examples/whisper/model/vocab_en.txt "$MODEL_DIR/"
        echo "✓ vocab_en.txt copied"
    else
        echo "✗ vocab_en.txt not found"
    fi
    
    if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/vocab_zh.txt" ]; then
        cp /workspace/rknn_model_zoo/examples/whisper/model/vocab_zh.txt "$MODEL_DIR/"
        echo "✓ vocab_zh.txt copied"
    else
        echo "✗ vocab_zh.txt not found"
    fi
    
    if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/mel_80_filters.txt" ]; then
        cp /workspace/rknn_model_zoo/examples/whisper/model/mel_80_filters.txt "$MODEL_DIR/"
        echo "✓ mel_80_filters.txt copied"
    else
        echo "✗ mel_80_filters.txt not found"
    fi
    
    echo ""
}

convert_models() {
    echo "[Step 3/4] Converting ONNX to RKNN for RK3588..."
    echo ""
    
    python3 << 'PYTHON_EOF'
from rknn.api import RKNN
import os

os.makedirs("model", exist_ok=True)

print("Converting encoder model...")
rknn = RKNN(verbose=False)
rknn.config(target_platform='rk3588')
ret = rknn.load_onnx(model='onnx/whisper_encoder_base.onnx')
if ret != 0:
    print('Load encoder model failed!')
    exit(1)
ret = rknn.build(do_quantization=False)
if ret != 0:
    print('Build encoder model failed!')
    exit(1)
ret = rknn.export_rknn('model/whisper_encoder_base.rknn')
rknn.release()
print('Encoder model saved!')

print("\nConverting decoder model...")
rknn = RKNN(verbose=False)
rknn.config(target_platform='rk3588')
ret = rknn.load_onnx(model='onnx/whisper_decoder_base.onnx')
if ret != 0:
    print('Load decoder model failed!')
    exit(1)
ret = rknn.build(do_quantization=False)
if ret != 0:
    print('Build decoder model failed!')
    exit(1)
ret = rknn.export_rknn('model/whisper_decoder_base.rknn')
rknn.release()
print('Decoder model saved!')
PYTHON_EOF
    
    echo ""
}

copy_test_audio() {
    echo "[Step 4/4] Copying test audio files..."
    echo ""
    
    mkdir -p test/audio
    
    if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/test_en.wav" ]; then
        cp /workspace/rknn_model_zoo/examples/whisper/model/test_en.wav test/audio/
        echo "✓ test_en.wav copied"
    else
        echo "✗ test_en.wav not found"
    fi
    
    if [ -f "/workspace/rknn_model_zoo/examples/whisper/model/test_zh.wav" ]; then
        cp /workspace/rknn_model_zoo/examples/whisper/model/test_zh.wav test/audio/
        echo "✓ test_zh.wav copied"
    else
        echo "✗ test_zh.wav not found"
    fi
    
    echo ""
}

check_models() {
    echo "Checking model files..."
    echo ""
    
    local all_ready=true
    
    if [ -f "$MODEL_DIR/whisper_encoder_base.rknn" ]; then
        echo "✓ Encoder model: $MODEL_DIR/whisper_encoder_base.rknn"
    else
        echo "✗ Encoder model not found"
        all_ready=false
    fi
    
    if [ -f "$MODEL_DIR/whisper_decoder_base.rknn" ]; then
        echo "✓ Decoder model: $MODEL_DIR/whisper_decoder_base.rknn"
    else
        echo "✗ Decoder model not found"
        all_ready=false
    fi
    
    if [ -f "$MODEL_DIR/vocab_en.txt" ]; then
        echo "✓ English vocab: $MODEL_DIR/vocab_en.txt"
    else
        echo "✗ English vocab not found"
        all_ready=false
    fi
    
    if [ -f "$MODEL_DIR/vocab_zh.txt" ]; then
        echo "✓ Chinese vocab: $MODEL_DIR/vocab_zh.txt"
    else
        echo "✗ Chinese vocab not found"
        all_ready=false
    fi
    
    if [ -f "$MODEL_DIR/mel_80_filters.txt" ]; then
        echo "✓ Mel filters: $MODEL_DIR/mel_80_filters.txt"
    else
        echo "✗ Mel filters not found"
        all_ready=false
    fi
    
    echo ""
    
    if [ "$all_ready" = true ]; then
        echo "=========================================="
        echo "All models are ready!"
        echo "=========================================="
        echo ""
        echo "Next steps:"
        echo "  1. Test English: ./scripts/test_single.sh -a test/audio/test_en.wav -t en"
        echo "  2. Test Chinese: ./scripts/test_single.sh -a test/audio/test_zh.wav -t zh"
        echo "  3. Multi test:   ./scripts/test_multi.sh"
    else
        echo "=========================================="
        echo "Some files are missing."
        echo "Please ensure rknn-toolkit2 is installed correctly."
        echo "=========================================="
        exit 1
    fi
}

main() {
    download_onnx_models
    copy_support_files
    convert_models
    copy_test_audio
    check_models
}

main "$@"
