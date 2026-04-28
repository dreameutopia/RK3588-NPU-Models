#!/bin/bash
set -e

echo "=========================================="
echo "Whisper RK3588 Board Setup"
echo "=========================================="
echo ""
echo "This script sets up the environment on RK3588 board."
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/.venv"

create_venv() {
    echo "[Step 1/5] Creating Python virtual environment..."
    echo ""

    if [ -d "$VENV_DIR" ]; then
        echo "Virtual environment already exists at $VENV_DIR"
        read -p "Remove and recreate? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$VENV_DIR"
        else
            echo "Using existing virtual environment."
            source "$VENV_DIR/bin/activate"
            return
        fi
    fi

    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"

    echo "Virtual environment created at $VENV_DIR"
    echo ""
}

install_dependencies() {
    echo "[Step 2/5] Installing Python dependencies..."
    echo ""

    pip install --upgrade pip

    pip install -r requirements-board.txt

    echo "Dependencies installed."
    echo ""
}

get_python_version() {
    local py_version=$(python --version 2>&1 | grep -oP '\d+\.\d+' | head -1 | tr -d '.')
    case $py_version in
        37) echo "cp37" ;;
        38) echo "cp38" ;;
        39) echo "cp39" ;;
        310) echo "cp310" ;;
        311) echo "cp311" ;;
        312) echo "cp312" ;;
        *)
            echo "ERROR: Unsupported Python version" >&2
            exit 1
            ;;
    esac
}

install_rknn_lite() {
    echo "[Step 3/5] Installing rknn-toolkit-lite2..."
    echo ""

    if python -c "from rknnlite.api import RKNNLite" 2>/dev/null || python -c "from rknn.api import RKNN" 2>/dev/null; then
        echo "RKNN Toolkit Lite2 is already installed."
        echo ""
        return
    fi

    local py_version=$(get_python_version)
    local py_ver_short=$(python --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
    echo "Detected Python version: $py_ver_short ($py_version)"

    local whl_file=""
    local whl_pattern="rknn_toolkit_lite2-*-$py_version-*.whl"

    if ls $PROJECT_DIR/rknn_toolkit_lite2-*.whl 1> /dev/null 2>&1; then
        whl_file=$(ls $PROJECT_DIR/rknn_toolkit_lite2-*.whl 2>/dev/null | head -1)
        echo "Found local whl file: $whl_file"
    else
        echo "No local whl file found. Downloading..."
        local download_url="https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-$py_version-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
        whl_file="$PROJECT_DIR/rknn_toolkit_lite2-2.3.2-$py_version-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"

        echo "Downloading from: $download_url"
        if wget -q --show-progress -O "$whl_file" "$download_url"; then
            echo "Download completed: $whl_file"
        else
            echo "Download failed! Please download manually from:"
            echo "  https://github.com/airockchip/rknn-toolkit2/tree/master/rknn-toolkit-lite2/packages"
            echo ""
            echo "Place the whl file in: $PROJECT_DIR/"
            echo "Then run: pip install $PROJECT_DIR/rknn_toolkit_lite2-2.3.2-$py_version-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
            exit 1
        fi
    fi

    echo "Installing: $whl_file"
    pip install "$whl_file"

    if python -c "from rknnlite.api import RKNNLite" 2>/dev/null || python -c "from rknn.api import RKNN" 2>/dev/null; then
        echo "RKNN Toolkit Lite2 installed successfully!"
    else
        echo "ERROR: Installation failed!"
        exit 1
    fi
    echo ""
}

verify_installation() {
    echo "[Step 4/5] Verifying installation..."
    echo ""

    echo "Checking Python packages..."
    python -c "import numpy; print(f'  numpy: {numpy.__version__}')"
    python -c "import scipy; print(f'  scipy: {scipy.__version__}')"
    python -c "import soundfile; print('  soundfile: OK')"
    if python -c "from rknnlite.api import RKNNLite" 2>/dev/null; then
        python -c "from rknnlite.api import RKNNLite; print('  rknnlite: OK')"
    else
        python -c "from rknn.api import RKNN; print('  rknn: OK')"
    fi

    echo ""
    echo "[Step 5/5] Setup completed successfully!"
    echo "=========================================="
    echo ""
    echo "Virtual environment: $VENV_DIR"
    echo ""
    echo "Usage:"
    echo "  source .venv/bin/activate"
    echo "  ./scripts/test_single.sh -a test/audio/test_en.wav -t en"
    echo ""
    echo "For performance optimization, run:"
    echo "  ./scripts/fix_freq_rk3588.sh"
    echo ""
}

main() {
    create_venv
    install_dependencies
    install_rknn_lite
    verify_installation
}

main "$@"
