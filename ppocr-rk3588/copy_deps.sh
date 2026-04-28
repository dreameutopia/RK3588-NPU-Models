#!/bin/bash

echo "Copying necessary files from rknn_model_zoo..."

SRC_DIR="/workspace/rknn_model_zoo/examples/PPOCR/PPOCR-System/cpp"
DST_DIR="/workspace/ppocr-rk3588/src"

echo "[1/3] Copying clipper.h..."
cp ${SRC_DIR}/clipper.h ${DST_DIR}/clipper.h

echo "[2/3] Copying clipper.cc..."
cp ${SRC_DIR}/clipper.cc ${DST_DIR}/clipper.cc

echo "[3/3] Copying dict.h (full version)..."
cp ${SRC_DIR}/dict.h ${DST_DIR}/dict.h

echo "Done! Files copied to ${DST_DIR}"
ls -la ${DST_DIR}/
