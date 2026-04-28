#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Cleaning temporary files..."
echo "=========================================="
echo ""

read -p "This will remove ONNX models and output files. Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "Removing ONNX models..."
rm -rf onnx/*.onnx
echo "Done!"

echo ""
echo "Removing output files..."
rm -rf test/output/*
echo "Done!"

echo ""
echo "=========================================="
echo "Cleanup completed!"
echo "=========================================="
echo ""
echo "Remaining files:"
echo "  - model/ (RKNN models)"
echo "  - python/ (source code)"
echo "  - scripts/ (test scripts)"
echo "  - test/audio/ (test audio files)"
