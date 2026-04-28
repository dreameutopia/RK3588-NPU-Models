#!/bin/bash
# RK3588 开发板环境安装脚本

set -e

echo "=========================================="
echo "MMS-TTS RK3588 开发板环境安装"
echo "=========================================="
echo ""

# 检查是否在开发板上
if [ "$(uname -m)" != "aarch64" ]; then
    echo "警告: 此脚本应在 RK3588 开发板上运行"
    echo "当前架构: $(uname -m)"
    read -p "是否继续? (y/N): " continue
    if [ "$continue" != "y" ] && [ "$continue" != "Y" ]; then
        exit 0
    fi
fi

# 删除旧的虚拟环境
if [ -d ".venv" ]; then
    echo "删除旧的虚拟环境..."
    rm -rf .venv
fi

# 创建虚拟环境
echo "创建 Python 虚拟环境..."
python3 -m venv .venv

# 激活虚拟环境
echo "激活虚拟环境..."
source .venv/bin/activate

# 升级 pip
echo "升级 pip..."
pip install --upgrade pip

# 安装基础依赖
echo "安装基础依赖..."
pip install soundfile numpy

# 安装 PyTorch (CPU 版本)
echo "安装 PyTorch..."
pip install torch --index-url https://download.pytorch.org/whl/cpu 2>/dev/null || pip install torch

# 安装 rknn-toolkit-lite2
echo ""
echo "=========================================="
echo "安装 rknn-toolkit-lite2"
echo "=========================================="
echo ""

# 查找本地 wheel 文件
RKNN_WHL=$(ls rknn_toolkit_lite2-*.whl 2>/dev/null | head -1)

if [ -n "$RKNN_WHL" ]; then
    echo "找到本地安装包: $RKNN_WHL"
    pip install "$RKNN_WHL"
else
    echo "错误: 未找到 rknn_toolkit_lite2 wheel 文件!"
    echo "请将 rknn_toolkit_lite2-*.whl 文件放在项目根目录下"
    echo ""
    echo "下载地址: https://github.com/airockchip/rknn-toolkit2/tree/master/rknn-toolkit-lite2/packages"
    exit 1
fi

# 验证安装
echo ""
echo "=========================================="
echo "验证安装"
echo "=========================================="
echo ""

echo "Python 路径: $(which python)"
echo "Python 版本: $(python --version)"
echo ""

echo "检查 rknnlite 模块..."
python -c "from rknnlite.api import RKNNLite; print('✓ rknnlite.api.RKNNLite OK')" || {
    echo ""
    echo "✗ rknnlite 模块导入失败!"
    echo ""
    echo "尝试检查已安装的包:"
    pip list | grep -i rknn || echo "未找到 rknn 相关包"
    echo ""
    echo "请确保:"
    echo "1. 使用的是正确的 wheel 文件 (aarch64 架构)"
    echo "2. Python 版本与 wheel 文件匹配 (cp310=Python3.10, cp311=Python3.11)"
    exit 1
}

echo "✓ soundfile OK"
python -c "import soundfile"

echo "✓ numpy OK"
python -c "import numpy"

# 创建便捷运行脚本
cat > run.sh << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source .venv/bin/activate
python3 python/mms_tts.py "$@"
EOF
chmod +x run.sh

echo ""
echo "=========================================="
echo "安装完成!"
echo "=========================================="
echo ""
echo "使用方法:"
echo "  source .venv/bin/activate"
echo "  python3 python/mms_tts.py --encoder model/mms_tts_eng_encoder_200.rknn --decoder model/mms_tts_eng_decoder_200.rknn --text 'Hello world'"
echo ""
echo "或使用便捷脚本:"
echo "  ./run.sh --encoder model/mms_tts_eng_encoder_200.rknn --decoder model/mms_tts_eng_decoder_200.rknn --text 'Hello world'"
