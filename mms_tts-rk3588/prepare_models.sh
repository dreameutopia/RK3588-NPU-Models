#!/bin/bash
# PC 端模型准备脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Prepare MMS-TTS RKNN models on PC"
    echo ""
    echo "Options:"
    echo "  -l, --language LANG     Language code (default: eng)"
    echo "  -m, --max_length LEN    Max input length (default: 200)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 -l eng -m 200"
    echo "  $0 -l zho"
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
echo "MMS-TTS RKNN Model Preparation"
echo "=========================================="
echo "Language: $LANG"
echo "Max Length: $MAX_LENGTH"
echo "=========================================="
echo ""

# 检查虚拟环境
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# 激活虚拟环境
echo "Activating virtual environment..."
source .venv/bin/activate

# 安装依赖
echo "Installing dependencies..."
pip install --upgrade pip
pip install rknn-toolkit2 'onnx>=1.16.0,<1.17.0' onnxruntime soundfile 'numpy<=1.26.4' 'protobuf<=4.25.4' torch transformers

# 创建目录
mkdir -p onnx model

# 下载或导出 ONNX
ENCODER_ONNX="onnx/mms_tts_${LANG}_encoder_${MAX_LENGTH}.onnx"
DECODER_ONNX="onnx/mms_tts_${LANG}_decoder_${MAX_LENGTH}.onnx"

if [ "$LANG" = "eng" ] && [ "$MAX_LENGTH" = "200" ]; then
    if [ ! -f "$ENCODER_ONNX" ] || [ ! -f "$DECODER_ONNX" ]; then
        echo ""
        echo "Downloading pre-converted ONNX models..."
        wget -O "$ENCODER_ONNX" \
            https://ftrg.zbox.filez.com/v2/delivery/data/95f00b0fc900458ba134f8b180b3f7a1/examples/mms_tts/mms_tts_eng_encoder_200.onnx
        wget -O "$DECODER_ONNX" \
            https://ftrg.zbox.filez.com/v2/delivery/data/95f00b0fc900458ba134f8b180b3f7a1/examples/mms_tts/mms_tts_eng_decoder_200.onnx
    fi
else
    if [ ! -f "$ENCODER_ONNX" ] || [ ! -f "$DECODER_ONNX" ]; then
        echo ""
        echo "Exporting ONNX models..."
        MODEL_NAME="facebook/mms-tts-${LANG}"
        python3 python/export_onnx.py --model_name "$MODEL_NAME" --language "$LANG" --max_length "$MAX_LENGTH"
    fi
fi

# 转换为 RKNN
ENCODER_RKNN="model/mms_tts_${LANG}_encoder_${MAX_LENGTH}.rknn"
DECODER_RKNN="model/mms_tts_${LANG}_decoder_${MAX_LENGTH}.rknn"

if [ ! -f "$ENCODER_RKNN" ] || [ ! -f "$DECODER_RKNN" ]; then
    echo ""
    echo "Converting to RKNN..."
    python3 python/convert_rknn.py \
        --encoder "$ENCODER_ONNX" \
        --decoder "$DECODER_ONNX" \
        --target rk3588
fi

# 清理中间文件
rm -f check*.onnx 2>/dev/null || true

echo ""
echo "=========================================="
echo "Model preparation completed!"
echo "=========================================="
echo ""
echo "Generated files:"
ls -lh model/*.rknn 2>/dev/null || echo "No RKNN files found"
echo ""
echo "Next steps:"
echo "  1. Test on PC:"
echo "     python3 python/mms_tts.py --encoder $ENCODER_RKNN --decoder $DECODER_RKNN --text 'Hello world'"
echo ""
echo "  2. Deploy to RK3588:"
echo "     scp -r model/*.rknn python/mms_tts.py scripts/ root@192.168.1.100:/path/to/mms_tts/"
