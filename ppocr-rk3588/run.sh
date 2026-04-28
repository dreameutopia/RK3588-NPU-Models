#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <image_path> [output_image_path]"
    echo "Example: $0 test.jpg result.jpg"
    exit 1
fi

IMAGE_PATH=$1
OUTPUT_PATH=${2:-""}

export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH

if [ -n "$OUTPUT_PATH" ]; then
    ./ppocr_demo -i $IMAGE_PATH -o $OUTPUT_PATH
else
    ./ppocr_demo -i $IMAGE_PATH
fi
