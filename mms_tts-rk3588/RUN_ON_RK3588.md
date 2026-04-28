# RK3588 板子运行指南

本文档介绍如何在 RK3588 开发板上部署和运行 MMS-TTS 语音合成。

## 重要说明

> ⚠️ **开发板和 PC 使用不同的 RKNN 包：**

| 环境 | 使用包 | 用途 |
|------|--------|------|
| PC (x86) | `rknn-toolkit2` | 模型转换、仿真测试 |
| RK3588 板子 | `rknn-toolkit-lite2` | 运行推理 |

## 前提条件

- 已完成 PC 端的模型准备（参考 [README.md](README.md) 的"快速开始"部分）
- RKNN 模型文件已准备就绪（位于 `model/` 目录）
- 已下载 `rknn_toolkit_lite2-*.whl` 文件到项目根目录

## 步骤 1: 下载并准备 rknn-toolkit-lite2

### 1.1 确认 Python 版本

在开发板上运行以下命令确认 Python 版本：

```bash
python --version
```

### 1.2 下载对应版本的 wheel 文件

根据 Python 版本选择对应的 wheel 文件：

| Python 版本 | 下载命令 |
|------------|---------|
| Python 3.7 | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| Python 3.8 | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| Python 3.9 | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp39-cp39-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| **Python 3.10** | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp310-cp310-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| **Python 3.11** | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| Python 3.12 | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |

> 💡 **提示**：Rock 5T 开发板通常预装 Python 3.10 或 Python 3.11，使用 cp310 或 cp311 版本。

### 1.3 示例下载命令

以 Python 3.11 为例：

```bash
# 进入项目目录
cd /www/wwwroot/rk-3588/mms_tts-rk3588

# 下载 Python 3.11 版本的 wheel 文件
wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl

# 确认文件已下载
ls -la rknn_toolkit_lite2-*.whl
```

wheel 文件应放在项目根目录下（与 setup_board.sh 同目录）。

## 步骤 2: 运行安装脚本

```bash
chmod +x setup_board.sh
./setup_board.sh
```

脚本会自动：
1. 创建 Python 虚拟环境 `.venv`
2. 安装依赖 (soundfile, numpy, torch)
3. 从本地 wheel 文件安装 rknn-toolkit-lite2
4. 创建 `run.sh` 便捷运行脚本

## 步骤 3: 验证安装

```bash
source .venv/bin/activate
python -c "from rknnlite.api import RKNNLite; print('RKNN OK')"
```

## 步骤 4: 运行推理

```bash
# 激活虚拟环境
source .venv/bin/activate

# 使用便捷脚本
./run.sh --encoder model/mms_tts_eng_encoder_200.rknn --decoder model/mms_tts_eng_decoder_200.rknn --text "Hello from RK3588"

# 或直接运行
python3 python/mms_tts.py \
    --encoder model/mms_tts_eng_encoder_200.rknn \
    --decoder model/mms_tts_eng_decoder_200.rknn \
    --text "Hello world"
```

### 输出文件位置

运行成功后，音频文件会保存在以下位置：

| 运行方式 | 输出路径 | 说明 |
|---------|---------|------|
| 使用 `--output` 参数 | 自定义路径 | 可指定绝对路径 |
| 默认输出 | `output.wav` | 当前工作目录下 |

**示例 - 指定输出路径：**

```bash
# 保存到 /root 目录
python3 python/mms_tts.py \
    --encoder model/mms_tts_eng_encoder_200.rknn \
    --decoder model/mms_tts_eng_decoder_200.rknn \
    --text "Hello from RK3588" \
    --output /root/hello.wav

# 保存到项目目录下的 test/output 文件夹
python3 python/mms_tts.py \
    --encoder model/mms_tts_eng_encoder_200.rknn \
    --decoder model/mms_tts_eng_decoder_200.rknn \
    --text "Hello from RK3588" \
    --output test/output/hello.wav
```

**音频参数：**
- 采样率：16000 Hz
- 格式：WAV

## 完整部署流程

```
┌─────────────────────────────────────────────────────────────┐
│                         PC (x86)                             │
│                                                              │
│  1. python3 -m venv .venv && source .venv/bin/activate      │
│  2. pip install rknn-toolkit2                                │
│  3. 运行 prepare_models.sh 准备 RKNN 模型                    │
│  4. 下载 rknn_toolkit_lite2-*.whl 到项目目录                 │
│  5. scp 复制整个项目到开发板                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      RK3588 开发板                           │
│                                                              │
│  1. ./setup_board.sh (创建 venv + 安装依赖)                  │
│  2. source .venv/bin/activate                                │
│  3. ./run.sh --encoder ... --decoder ... --text "..."        │
└─────────────────────────────────────────────────────────────┘
```

## 运行参数

### run.sh 便捷脚本

```bash
./run.sh \
    --encoder model/mms_tts_eng_encoder_200.rknn \
    --decoder model/mms_tts_eng_decoder_200.rknn \
    --text "Hello world" \
    --output output.wav \
    --max_length 200
```

### mms_tts.py 直接调用

```bash
python3 python/mms_tts.py \
    --encoder model/mms_tts_eng_encoder_200.rknn \
    --decoder model/mms_tts_eng_decoder_200.rknn \
    --text "Hello world" \
    --output output.wav \
    --max_length 200
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--encoder` | Encoder RKNN 模型路径 | (必需) |
| `--decoder` | Decoder RKNN 模型路径 | (必需) |
| `--text` | 要合成的文本 | (必需) |
| `--output` | 输出音频文件 | output.wav |
| `--max_length` | 最大输入长度 | 200 |

## 常见问题

### Q: 开发板上报错 "No module named 'rknn'"

这是最常见的问题！`rknn-toolkit-lite2` 使用的是 `rknnlite` 模块，而不是 `rknn` 模块。

**代码已自动适配**：mms_tts.py 会自动尝试两种导入方式：
1. 先尝试 `from rknn.api import RKNN` (PC 端)
2. 失败后尝试 `from rknnlite.api import RKNNLite as RKNN` (开发板)

**验证安装**：

```bash
source .venv/bin/activate

# 验证 rknnlite 模块
python -c "from rknnlite.api import RKNNLite; print('OK')"
# 应该显示: OK
```

**如果仍然失败**，请按以下步骤排查：

**步骤 1: 确认虚拟环境已激活**

```bash
source .venv/bin/activate
which python
# 应该显示: /path/to/mms_tts-rk3588/.venv/bin/python
```

**步骤 2: 确认 Python 版本与 wheel 文件匹配**

```bash
python --version
# 如果是 Python 3.11.x，需要使用 cp311 的 wheel 文件
# 如果是 Python 3.10.x，需要使用 cp310 的 wheel 文件
```

**步骤 3: 重新安装**

```bash
rm -rf .venv
./setup_board.sh
```

**步骤 4: 检查 wheel 文件**

```bash
ls -la rknn_toolkit_lite2-*.whl
# 文件名格式: rknn_toolkit_lite2-版本-cp版本-架构.whl
# 例如: rknn_toolkit_lite2-2.3.2-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
#       cp311 = Python 3.11
#       aarch64 = ARM 64位架构 (RK3588)
```

### Q: rknn_toolkit_lite2 wheel 文件哪里下载？

https://github.com/airockchip/rknn-toolkit2/tree/master/rknn-toolkit-lite2/packages

选择对应 Python 版本的文件：
- `cp310` = Python 3.10
- `cp311` = Python 3.11
