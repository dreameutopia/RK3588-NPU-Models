#!/bin/bash
# 便捷运行脚本 (用于开发板)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 激活虚拟环境
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# 默认参数
ENCODER="model/mms_tts_eng_encoder_200.rknn"
DECODER="model/mms_tts_eng_decoder_200.rknn"
TEXT="Hello, this is a text to speech demo on RK3588."
OUTPUT="output.wav"
MAX_LENGTH=200
SPEAKING_RATE=0.8

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--encoder)
            ENCODER="$2"
            shift 2
            ;;
        -d|--decoder)
            DECODER="$2"
            shift 2
            ;;
        -t|--text)
            TEXT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -m|--max_length)
            MAX_LENGTH="$2"
            shift 2
            ;;
        -s|--speaking_rate)
            SPEAKING_RATE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --encoder PATH       Encoder model path"
            echo "  -d, --decoder PATH       Decoder model path"
            echo "  -t, --text TEXT          Text to synthesize"
            echo "  -o, --output PATH        Output audio file"
            echo "  -m, --max_length LEN     Max input length"
            echo "  -s, --speaking_rate RATE Speaking rate (default: 0.8, lower=slower)"
            echo "  -h, --help               Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

python3 python/mms_tts.py \
    --encoder "$ENCODER" \
    --decoder "$DECODER" \
    --text "$TEXT" \
    --output "$OUTPUT" \
    --max_length $MAX_LENGTH \
    --speaking_rate $SPEAKING_RATE
