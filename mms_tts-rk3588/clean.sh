#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Cleaning MMS-TTS RK3588 temporary files"
echo "=========================================="
echo ""

# 清除 RKNN 转换中间文件
echo "Removing RKNN intermediate files..."
rm -f check0_base_optimize.onnx
rm -f check1_fold_constant.onnx
rm -f check2_correct_ops.onnx
rm -f check3_fuse_ops.onnx
rm -f check*.onnx
echo "Done."

# 清除 ONNX 模型
read -p "Clean ONNX models? (y/N): " clean_onnx
if [ "$clean_onnx" = "y" ] || [ "$clean_onnx" = "Y" ]; then
    echo "Removing onnx/..."
    rm -rf onnx/*
    echo "Done."
fi

# 清除测试输出
read -p "Clean test outputs? (y/N): " clean_test
if [ "$clean_test" = "y" ] || [ "$clean_test" = "Y" ]; then
    echo "Removing test/output/..."
    rm -rf test/output/*
    echo "Done."
fi

# 清除下载的压缩包
read -p "Clean downloaded archives? (y/N): " clean_archives
if [ "$clean_archives" = "y" ] || [ "$clean_archives" = "Y" ]; then
    echo "Removing *.tar.bz2..."
    rm -f *.tar.bz2
    echo "Done."
fi

# 清除 Python 缓存
read -p "Clean build cache? (y/N): " clean_build
if [ "$clean_build" = "y" ] || [ "$clean_build" = "Y" ]; then
    echo "Removing __pycache__..."
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
    echo "Done."
fi

echo ""
echo "=========================================="
echo "Cleanup completed!"
echo "=========================================="
