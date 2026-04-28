#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -l, --language LANG     Language code (default: eng)"
    echo "  -m, --max_length LEN    Max input length (default: 200)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 -l eng"
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

echo "=========================================="
echo "MMS-TTS RK3588 Multi-Test"
echo "=========================================="
echo "Language: $LANG"
echo "Encoder: $ENCODER"
echo "Decoder: $DECODER"
echo "Output Directory: $OUTPUT_DIR"
echo "=========================================="
echo ""

case $LANG in
    eng)
        TEST_CASES=(
            "Hello, this is a test of the MMS TTS system."
            "The quick brown fox jumps over the lazy dog."
            "Welcome to RK3588 text to speech demo."
            "Artificial intelligence is transforming our world."
            "Thank you for using this demo."
            "The weather today is sunny and warm."
            "Please speak clearly into the microphone."
            "Testing one two three, this is a voice synthesis test."
            "Rockchip RK3588 is a powerful AI processor."
            "Have a nice day!"
        )
        ;;
    zho)
        TEST_CASES=(
            "你好，这是一个测试。"
            "欢迎使用文字转语音系统。"
            "今天天气很好。"
            "人工智能正在改变我们的世界。"
            "谢谢使用本演示程序。"
            "请说清楚一点。"
            "测试一二三。"
            "瑞芯微RK3588是一款强大的AI处理器。"
            "祝你今天愉快！"
            "这是一个语音合成测试。"
        )
        ;;
    deu)
        TEST_CASES=(
            "Hallo, dies ist ein Test."
            "Willkommen beim Sprachsynthese-System."
            "Das Wetter heute ist schoen."
            "Kuenstliche Intelligenz veraendert unsere Welt."
            "Vielen Dank fuer die Nutzung."
        )
        ;;
    fra)
        TEST_CASES=(
            "Bonjour, ceci est un test."
            "Bienvenue dans le systeme de synthese vocale."
            "Le temps est beau aujourd'hui."
            "L'intelligence artificielle transforme notre monde."
            "Merci d'utiliser cette demo."
        )
        ;;
    spa)
        TEST_CASES=(
            "Hola, esto es una prueba."
            "Bienvenido al sistema de sintesis de voz."
            "El clima hoy es soleado."
            "La inteligencia artificial esta transformando nuestro mundo."
            "Gracias por usar esta demostracion."
        )
        ;;
    jpn)
        TEST_CASES=(
            "こんにちは、これはテストです。"
            "音声合成システムへようこそ。"
            "今日の天気は晴れです。"
            "人工知能は私たちの世界を変えています。"
            "このデモをご利用いただきありがとうございます。"
        )
        ;;
    kor)
        TEST_CASES=(
            "안녕하세요, 이것은 테스트입니다."
            "음성 합성 시스템에 오신 것을 환영합니다."
            "오늘 날씨가 맑습니다."
            "인공 지능이 우리 세상을 바꾸고 있습니다."
            "이 데모를 사용해 주셔서 감사합니다."
        )
        ;;
    *)
        TEST_CASES=(
            "Hello, this is a test."
            "Welcome to the TTS system."
            "Thank you for using this demo."
        )
        ;;
esac

echo "Running ${#TEST_CASES[@]} test cases for language: $LANG"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for i in "${!TEST_CASES[@]}"; do
    idx=$((i + 1))
    text="${TEST_CASES[$i]}"
    output="${OUTPUT_DIR}/test_${idx}_${TIMESTAMP}.wav"
    
    echo "[$idx/${#TEST_CASES[@]}] Text: $text"
    
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
done

echo "=========================================="
echo "Multi-test completed!"
echo "=========================================="
echo "Language: $LANG"
echo "Total: ${#TEST_CASES[@]}"
echo "Success: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"
echo ""
echo "Output files saved to: $OUTPUT_DIR/"
echo ""
echo "To download all outputs:"
echo "  scp -r user@device:/path/to/mms_tts-rk3588/test/output ."
echo "=========================================="
