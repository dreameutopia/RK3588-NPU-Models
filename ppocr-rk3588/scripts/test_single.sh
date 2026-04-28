#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

DEMO_PATH=""
LIB_PATH=""

if [ -f "./install/ppocr_demo" ]; then
    DEMO_PATH="./install/ppocr_demo"
    LIB_PATH="./install/lib"
elif [ -f "./ppocr_demo" ]; then
    DEMO_PATH="./ppocr_demo"
    LIB_PATH="./lib"
else
    echo "Error: ppocr_demo not found!"
    echo "Please run: ./build.sh"
    exit 1
fi

export LD_LIBRARY_PATH="$LIB_PATH:$LD_LIBRARY_PATH"

DET_MODEL="./model/ppocrv4_det_serverial.rknn"
REC_MODEL="./model/ppocrv4_rec_serverial.rknn"

if [ ! -f "$DET_MODEL" ]; then
    echo "Error: Detection model not found: $DET_MODEL"
    exit 1
fi

if [ ! -f "$REC_MODEL" ]; then
    echo "Error: Recognition model not found: $REC_MODEL"
    exit 1
fi

IMAGE_PATH=""
OUTPUT_PATH=""
DET_THRESHOLD=0.3
BOX_THRESHOLD=0.5

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            IMAGE_PATH="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -t|--threshold)
            DET_THRESHOLD="$2"
            shift 2
            ;;
        -b|--box_threshold)
            BOX_THRESHOLD="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -i, --image PATH        Input image path (default: test/test1.png)"
            echo "  -o, --output PATH       Output image path with boxes (optional)"
            echo "  -t, --threshold FLOAT   Detection pixel threshold (default: 0.3)"
            echo "  -b, --box_threshold FLOAT  Box threshold (default: 0.5)"
            echo "  -h, --help              Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$IMAGE_PATH" ]; then
    IMAGE_PATH="./test/test1.png"
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found: $IMAGE_PATH"
    exit 1
fi

echo "=========================================="
echo "PPOCR RK3588 Single Image Test"
echo "=========================================="
echo "Detection Model: $DET_MODEL"
echo "Recognition Model: $REC_MODEL"
echo "Image: $IMAGE_PATH"
echo "Detection Threshold: $DET_THRESHOLD"
echo "Box Threshold: $BOX_THRESHOLD"
echo "=========================================="
echo ""

echo "Start Time: $(date '+%Y-%m-%d %H:%M:%S.%3N')"
START_TIME=$(date +%s%3N)

if [ -n "$OUTPUT_PATH" ]; then
    $DEMO_PATH -d "$DET_MODEL" -r "$REC_MODEL" -i "$IMAGE_PATH" -t "$DET_THRESHOLD" -b "$BOX_THRESHOLD" -o "$OUTPUT_PATH"
else
    $DEMO_PATH -d "$DET_MODEL" -r "$REC_MODEL" -i "$IMAGE_PATH" -t "$DET_THRESHOLD" -b "$BOX_THRESHOLD"
fi

END_TIME=$(date +%s%3N)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "End Time: $(date '+%Y-%m-%d %H:%M:%S.%3N')"
echo "Total Duration: ${DURATION} ms"
echo "=========================================="
