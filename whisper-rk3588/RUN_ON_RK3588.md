# RK3588 板子运行指南

本文档介绍如何在 RK3588 开发板上部署和运行 Whisper 语音识别。

## 重要说明

> ⚠️ **开发板和 PC 使用不同的 RKNN 包：**

| 环境 | 使用包 | 用途 |
|------|--------|------|
| PC (x86) | `rknn-toolkit2` | 模型转换、仿真测试 |
| RK3588 板子 | `rknn-toolkit-lite2` | 运行推理 |

## 前提条件

- PC 端已完成模型准备（参考 [README.md](README.md) 的"快速开始"部分）
- RKNN 模型文件已准备就绪（位于 `model/` 目录）
- 已下载 `rknn_toolkit_lite2-*.whl` 文件到项目根目录

## 步骤 1: 复制文件到开发板

在 PC 上执行，将必要文件复制到 RK3588 开发板：

```bash
scp -r model/ python/ scripts/ test/ setup_board.sh requirements-board.txt root@<RK3588_IP>:/www/wwwroot/whisper-rk3588/
```

> 💡 **提示**：将 `<RK3588_IP>` 替换为开发板的实际 IP 地址。

## 步骤 2: 安装 rknn-toolkit-lite2

### 2.1 确认 Python 版本

在开发板上运行以下命令确认 Python 版本：

```bash
python --version
```

### 2.2 下载对应版本的 wheel 文件

根据 Python 版本选择对应的 wheel 文件：

| Python 版本 | 下载命令 |
|------------|---------|
| Python 3.7 | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp37-cp37m-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| Python 3.8 | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| Python 3.9 | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp39-cp39-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| **Python 3.10** | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp310-cp310-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| **Python 3.11** | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp311-cp311-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |
| Python 3.12 | `wget https://github.com/airockchip/rknn-toolkit2/raw/master/rknn-toolkit-lite2/packages/rknn_toolkit_lite2-2.3.2-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl` |

### 2.3 运行安装脚本

```bash
# 进入项目目录
cd /www/wwwroot/whisper-rk3588

# 使用 setup 脚本自动安装
chmod +x setup_board.sh
./setup_board.sh
```

脚本会自动：

1. 创建 Python 虚拟环境 `.venv`
2. 安装依赖 (soundfile, numpy, scipy, librosa)
3. **自动检测并安装 rknn-toolkit-lite2**：
   - 优先查找本地已下载的 `rknn_toolkit_lite2-*.whl` 文件
   - 如果本地没有，自动从 GitHub 下载对应 Python 版本的 whl 文件
   - 安装完成后验证是否成功
4. 验证安装

> 💡 **提示**：
> - Rock 5T 开发板通常预装 Python 3.10 或 Python 3.11
> - 如果已经下载了 whl 文件，确保它在项目根目录下，脚本会自动识别并安装
> - 如果没有下载，脚本会自动从 GitHub 下载

## 步骤 3: 验证安装

```bash
# 激活虚拟环境
source .venv/bin/activate

# 验证
python -c "from rknn.api import RKNN; print('RKNN OK')"
```

## 步骤 4: 性能优化 (可选)

在 RK3588 开发板上，运行以下脚本可以固定 CPU/NPU/GPU 频率以获得最佳性能：

```bash
# 设置性能模式
./scripts/fix_freq_rk3588.sh
```

该脚本会：
- 禁用 CPU 空闲状态
- 固定 NPU 频率到 1GHz
- 固定 GPU 频率到 1GHz
- 固定 CPU 频率到最高值
- 固定 DDR 频率到最高值

## 步骤 5: 运行推理

```bash
cd /www/wwwroot/whisper-rk3588

# 激活虚拟环境
source .venv/bin/activate

# 英文识别
./scripts/test_single.sh -a test/audio/test_en.wav -t en

# 中文识别
./scripts/test_single.sh -a test/audio/test_zh.wav -t zh

# 多音频测试
./scripts/test_multi.sh
```

## 运行参数

### 完整参数说明

```bash
python3 python/whisper.py \
    --encoder_model model/whisper_encoder_base.rknn \
    --decoder_model model/whisper_decoder_base.rknn \
    --audio test/audio/test_en.wav \
    --task en \
    --target rk3588
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--encoder_model` | Encoder RKNN 模型路径 | (必需) |
| `--decoder_model` | Decoder RKNN 模型路径 | (必需) |
| `--audio` | 输入音频文件 | (必需) |
| `--task` | 识别任务 (en/zh) | en |
| `--target` | 目标平台 | rk3588 |
| `--device_id` | 设备 ID | None |

### 输出文件位置

运行成功后，识别结果会显示在终端：
- 识别的文本内容
- 识别耗时
- 使用的语言模型

## 完整部署流程

```
┌─────────────────────────────────────────────────────────────┐
│                         PC (x86)                             │
│                                                              │
│  1. python3 -m venv .venv && source .venv/bin/activate      │
│  2. pip install rknn-toolkit2                                │
│  3. 运行 prepare_models.sh 准备 RKNN 模型                    │
│  4. scp 复制文件到开发板                                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      RK3588 开发板                           │
│                                                              │
│  1. ./setup_board.sh (创建 venv + 安装依赖)                  │
│  2. source .venv/bin/activate                                │
│  3. ./scripts/fix_freq_rk3588.sh (可选，性能优化)            │
│  4. ./scripts/test_single.sh                                 │
└─────────────────────────────────────────────────────────────┘
```

## 常见问题

### Q: 开发板上报错 "No module named 'rknn'"

这是最常见的问题！`rknn-toolkit-lite2` 使用的是 `rknnlite` 模块，而不是 `rknn` 模块。

**代码已自动适配**：whisper.py 会自动尝试两种导入方式：
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
# 应该显示: /path/to/whisper-rk3588/.venv/bin/python
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
```

### Q: rknn_toolkit_lite2 wheel 文件哪里下载？

https://github.com/airockchip/rknn-toolkit2/tree/master/rknn-toolkit-lite2/packages

选择对应 Python 版本的文件：
- `cp310` = Python 3.10
- `cp311` = Python 3.11

### Q: 识别结果不准确

1. 确保音频质量良好，背景噪音较少
2. 确保音频采样率为 16kHz（程序会自动重采样）
3. 尝试使用更大的模型 (small/medium)

### Q: RK3588 和 RK3576 有什么区别？

| 特性 | RK3588 | RK3576 |
|------|--------|--------|
| NPU 核心 | 3 个 (6 TOPS) | 2 个 (6 TOPS) |
| NPU 设备路径 | fdab0000.npu | 27700000.npu |
| GPU 设备路径 | fb000000.gpu | 27800000.gpu |
| CPU 核心数 | 8 核 (4xA55 + 4xA76) | 8 核 (4xA53 + 4xA72) |
| 最大 NPU 频率 | 1 GHz | 1 GHz |
| 最大 GPU 频率 | 1 GHz | 950 MHz |

### Q: 支持实时语音识别吗？

当前版本支持离线音频文件识别。实时语音识别需要额外的音频流处理逻辑。
