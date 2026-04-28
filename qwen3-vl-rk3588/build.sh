#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --target TARGET     Target platform: rk3588 (default: rk3588)"
    echo "  -c, --compiler PATH     Path to cross-compiler (optional, for cross-compilation)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                              # Build for RK3588 (native compilation on board)"
    echo "  $0 -c ~/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu  # Cross-compile"
    exit 1
}

TARGET_PLATFORM="rk3588"
COMPILER_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET_PLATFORM="$2"
            shift 2
            ;;
        -c|--compiler)
            COMPILER_PATH="$2"
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
echo "Building Qwen3-VL Demo for $TARGET_PLATFORM"
echo "=========================================="

rm -rf build
mkdir -p build && cd build

if [ -n "$COMPILER_PATH" ]; then
    echo "Cross-compiling with: $COMPILER_PATH"
    cmake .. \
        -DCMAKE_CXX_COMPILER=${COMPILER_PATH}/bin/aarch64-none-linux-gnu-g++ \
        -DCMAKE_C_COMPILER=${COMPILER_PATH}/bin/aarch64-none-linux-gnu-gcc \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR=aarch64
else
    echo "Native compilation"
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release
fi

make -j$(nproc)
make install

echo ""
echo "=========================================="
echo "Build completed successfully!"
echo "=========================================="
echo ""
echo "Output directory: ${SCRIPT_DIR}/install/demo_Linux_aarch64"
echo ""
echo "Next steps:"
echo "1. Copy models to install/demo_Linux_aarch64/models/"
echo "   cp /path/to/qwen3-vl-2b_vision_rk3588.rknn install/demo_Linux_aarch64/models/"
echo "   cp /path/to/qwen3-vl-2b-instruct_w8a8_rk3588.rkllm install/demo_Linux_aarch64/models/"
echo ""
echo "2. Push to device: adb push install/demo_Linux_aarch64 /data"
echo ""
echo "3. Run on device:"
echo "   cd /data/demo_Linux_aarch64"
echo "   export LD_LIBRARY_PATH=./lib"
echo ""
echo "4. Interactive mode:"
echo "   ./run.sh"
echo ""
echo "5. Single image test:"
echo "   ./test_single.sh"
echo ""
echo "6. Multi-image concurrent test:"
echo "   ./test_multi.sh"
