#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "PPOCR Model Cleanup"
echo "=========================================="
echo ""

echo "Files to be removed:"
echo ""

REMOVED=0

echo "Intermediate ONNX files:"
for f in check*.onnx; do
    if [ -f "$f" ]; then
        SIZE=$(du -h "$f" | cut -f1)
        echo "  - $f ($SIZE)"
        REMOVED=$((REMOVED + 1))
    fi
done

ONNX_DIR="onnx"
if [ -d "$ONNX_DIR" ]; then
    echo ""
    echo "ONNX models in $ONNX_DIR/:"
    for f in "$ONNX_DIR"/*.onnx; do
        if [ -f "$f" ]; then
            SIZE=$(du -h "$f" | cut -f1)
            echo "  - $f ($SIZE)"
            REMOVED=$((REMOVED + 1))
        fi
    done
    
    for f in "$ONNX_DIR"/*.txt; do
        if [ -f "$f" ]; then
            SIZE=$(du -h "$f" | cut -f1)
            echo "  - $f ($SIZE)"
            REMOVED=$((REMOVED + 1))
        fi
    done
fi

if [ $REMOVED -eq 0 ]; then
    echo "No files to remove."
    exit 0
fi

echo ""
read -p "Remove these files? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Removing files..."

rm -f check*.onnx 2>/dev/null

if [ -d "$ONNX_DIR" ]; then
    rm -f "$ONNX_DIR"/*.onnx 2>/dev/null
    rm -f "$ONNX_DIR"/*.txt 2>/dev/null
fi

echo ""
echo "=========================================="
echo "Cleanup complete!"
echo ""
echo "Remaining RKNN models:"
ls -lh model/*.rknn 2>/dev/null || echo "  (none)"
echo "=========================================="
