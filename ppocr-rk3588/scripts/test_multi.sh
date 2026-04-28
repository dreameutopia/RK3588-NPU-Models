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

IMAGES=(
    "./test/test1.png"
    "./test/test2.png"
    "./test/test3.png"
)

DET_THRESHOLD=0.3
BOX_THRESHOLD=0.5

echo "=========================================="
echo "PPOCR RK3588 Multi-Image Concurrent Test"
echo "=========================================="
echo "Detection Model: $DET_MODEL"
echo "Recognition Model: $REC_MODEL"
echo "Images: ${#IMAGES[@]} files"
echo "Detection Threshold: $DET_THRESHOLD"
echo "Box Threshold: $BOX_THRESHOLD"
echo "=========================================="
echo ""

run_single_test() {
    local image_path=$1
    local task_id=$2
    local log_file="/tmp/ppocr_task_${task_id}.log"
    
    if [ ! -f "$image_path" ]; then
        echo "[Task $task_id] Error: Image not found: $image_path"
        return 1
    fi
    
    echo "[Task $task_id] Starting: $image_path"
    echo "[Task $task_id] Start Time: $(date '+%Y-%m-%d %H:%M:%S.%3N')"
    
    local start_time=$(date +%s%3N)
    
    $DEMO_PATH -d "$DET_MODEL" -r "$REC_MODEL" -i "$image_path" -t "$DET_THRESHOLD" -b "$BOX_THRESHOLD" > "$log_file" 2>&1
    
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))
    
    echo "[Task $task_id] End Time: $(date '+%Y-%m-%d %H:%M:%S.%3N')"
    echo "[Task $task_id] Duration: ${duration} ms"
    echo ""
    echo "[Task $task_id] ========== Output =========="
    cat "$log_file"
    echo "[Task $task_id] ============================"
    echo ""
    
    rm -f "$log_file"
}

echo "Starting concurrent OCR inference for ${#IMAGES[@]} images..."
echo ""

OVERALL_START=$(date +%s%3N)

for i in "${!IMAGES[@]}"; do
    run_single_test "${IMAGES[$i]}" "$i" &
done

wait

OVERALL_END=$(date +%s%3N)
OVERALL_DURATION=$((OVERALL_END - OVERALL_START))

echo ""
echo "=========================================="
echo "Multi-Image Concurrent Test Summary"
echo "=========================================="
echo "Total Images: ${#IMAGES[@]}"
echo "Overall Duration: ${OVERALL_DURATION} ms"
echo "Average Duration per Image: $((OVERALL_DURATION / ${#IMAGES[@]})) ms"
echo "=========================================="
