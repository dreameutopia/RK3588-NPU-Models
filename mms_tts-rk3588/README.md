# MMS-TTS RK3588 部署包

Facebook MMS-TTS (Massively Multilingual Speech) 在 RK3588 平台的完整部署方案，实现文字转语音功能。

## 简介

MMS-TTS 是 Facebook 发布的大规模多语言语音合成模型，支持超过 1000 种语言。本项目基于 [rknn_model_zoo/examples/mms_tts](https://github.com/airockchip/rknn_model_zoo/tree/main/examples/mms_tts) 实现，将模型拆分为 encoder 和 decoder 两部分，使其能够在 RKNN NPU 上运行。

### 支持的语言

| 语言代码 | 语言 | HuggingFace 模型 |
|---------|------|-----------------|
| eng | 英语 | facebook/mms-tts-eng |
| zho | 中文 | facebook/mms-tts-zho |
| deu | 德语 | facebook/mms-tts-deu |
| fra | 法语 | facebook/mms-tts-fra |
| spa | 西班牙语 | facebook/mms-tts-spa |
| jpn | 日语 | facebook/mms-tts-jpn |
| kor | 韩语 | facebook/mms-tts-kor |

## 目录结构

```
mms_tts-rk3588/
├── prepare_models.sh     # PC 端模型准备脚本
├── setup_board.sh        # 开发板环境安装脚本
├── clean.sh              # 清理临时文件
├── run.sh                # 便捷运行脚本
├── python/               # Python 源代码
│   ├── export_onnx.py    # ONNX 导出脚本
│   ├── convert_rknn.py   # RKNN 转换脚本
│   └── mms_tts.py        # 推理脚本
├── scripts/              # 测试脚本
│   ├── test_single.sh    # 单文本测试
│   ├── test_multi.sh     # 多文本测试
│   └── download_onnx.sh  # 下载预转换 ONNX 模型
├── model/                # RKNN 模型
│   ├── mms_tts_eng_encoder_200.rknn
│   └── mms_tts_eng_decoder_200.rknn
├── onnx/                 # ONNX 模型 (可清理)
└── test/                 # 测试相关
    ├── test_texts.txt    # 测试文本
    └── output/           # 音频输出
```

## 快速开始

### 步骤 1: 安装 rknn-toolkit2 环境 (PC 端)

```bash
# 创建虚拟环境
python3 -m venv .venv
source .venv/bin/activate

# 安装依赖
pip install rknn-toolkit2 setuptools==69.0.0 onnx==1.15.0 onnxruntime==1.16.3 soundfile numpy torch
python -c "from rknn.api import RKNN; print('OK')"
```

### 步骤 2: 准备模型

#### 方法 A: 下载预转换的 ONNX 模型 (推荐)

```bash
chmod +x ./scripts/download_onnx.sh
./scripts/download_onnx.sh
```

#### 方法 B: 从源码导出 ONNX

```bash
# 安装依赖
pip install transformers torch

# 导出英文模型
python3 python/export_onnx.py --language eng --max_length 200
```

### 步骤 3: 转换为 RKNN

```bash
source .venv/bin/activate

python3 python/convert_rknn.py \
    --encoder onnx/mms_tts_eng_encoder_200.onnx \
    --decoder onnx/mms_tts_eng_decoder_200.onnx \
    --target rk3588
```

或使用一键脚本：

```bash
chmod +x ./prepare_models.sh
./prepare_models.sh
```

### 步骤 4: 测试

```bash
./scripts/test_single.sh -t "Hello, this is a test."
```

## 运行参数

### mms_tts.py 参数

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
| `--encoder` | Encoder RKNN/ONNX 模型路径 | (必需) |
| `--decoder` | Decoder RKNN/ONNX 模型路径 | (必需) |
| `--text` | 要合成的文本 | (必需) |
| `--output` | 输出音频文件 | output.wav |
| `--max_length` | 最大输入长度 | 200 |

## 中文 TTS RKNN 模型导出教程

本节详细介绍如何导出中文 TTS RKNN 模型。英文模型导出方法类似，只需修改语言代码。

### 导出中文 ONNX 模型

#### 步骤 1: 安装依赖

```bash
source .venv/bin/activate
pip install transformers torch
```

#### 步骤 2: 导出 ONNX 模型

```bash
python3 python/export_onnx.py \
    --model_name facebook/mms-tts-zho \
    --language zho \
    --max_length 200 \
    --output_dir onnx
```

参数说明：
- `--model_name`: HuggingFace 模型名称，固定为 `facebook/mms-tts-zho`
- `--language`: 语言代码，用于输出文件命名，此处为 `zho`
- `--max_length`: 最大输入长度，默认为 200
- `--output_dir`: ONNX 模型输出目录

#### 步骤 3: 转换为 RKNN

```bash
source .venv/bin/activate

python3 python/convert_rknn.py \
    --encoder onnx/mms_tts_zho_encoder_200.onnx \
    --decoder onnx/mms_tts_zho_decoder_200.onnx \
    --target rk3588
```

转换成功后，RKNN 模型将保存在 `model/` 目录下：
- `model/mms_tts_zho_encoder_200.rknn`
- `model/mms_tts_zho_decoder_200.rknn`

### 运行中文语音合成

#### PC 端测试

```bash
python3 python/mms_tts.py \
    --encoder model/mms_tts_zho_encoder_200.rknn \
    --decoder model/mms_tts_zho_decoder_200.rknn \
    --text "你好，这是一段中文测试语音。" \
    --output output_chinese.wav \
    --max_length 200
```

或使用便捷脚本：

```bash
./run.sh --encoder model/mms_tts_zho_encoder_200.rknn --decoder model/mms_tts_zho_decoder_200.rknn --text "你好，欢迎使用中文语音合成。"
```

#### RK3588 开发板运行

```bash
source .venv/bin/activate

python3 python/mms_tts.py \
    --encoder model/mms_tts_zho_encoder_200.rknn \
    --decoder model/mms_tts_zho_decoder_200.rknn \
    --text "你好，这是一段中文测试语音。" \
    --output /root/output_chinese.wav
```

### 中文输入注意事项

1. **输入长度限制**：中文输入长度建议不超过 200 字符，超长文本会被截断
2. **标点符号**：支持中文标点符号（如，。！？：；""）
3. **特殊字符**：建议避免使用特殊符号或表情符号
4. **中英文混合**：MMS-TTS 是单语言模型，如需中英文混合请参考"关于中英文混合"章节

### 其他语言导出方法

如需导出其他语言模型，只需修改 `--model_name` 和 `--language` 参数：

```bash
# 德语
python3 python/export_onnx.py --model_name facebook/mms-tts-deu --language deu --max_length 200

# 法语
python3 python/export_onnx.py --model_name facebook/mms-tts-fra --language fra --max_length 200

# 日语
python3 python/export_onnx.py --model_name facebook/mms-tts-jpn --language jpn --max_length 200

# 韩语
python3 python/export_onnx.py --model_name facebook/mms-tts-kor --language kor --max_length 200
```

然后转换为 RKNN：

```bash
python3 python/convert_rknn.py \
    --encoder onnx/mms_tts_<language>_encoder_200.onnx \
    --decoder onnx/mms_tts_<language>_decoder_200.onnx \
    --target rk3588
```

## 在 RK3588 板子上运行

详细部署指南请参考 [RUN_ON_RK3588.md](RUN_ON_RK3588.md)。

主要步骤：

1. **准备 rknn-toolkit-lite2** - 下载对应 Python 版本的 wheel 文件到项目根目录
2. **运行安装脚本** - `./setup_board.sh`
3. **验证安装** - `python -c "from rknnlite.api import RKNNLite; print('RKNN OK')"`
4. **运行推理** - `./run.sh --encoder ... --decoder ... --text "..."`

> ⚠️ **重要提示**：开发板使用 `rknn-toolkit-lite2`（模块名 `rknnlite`），PC 端使用 `rknn-toolkit2`（模块名 `rknn`）。

## 关于中英文混合

MMS-TTS 是**单语言模型**，每个语言需要单独的模型文件。如需中英文混合：

### 方案 1: 分段合成后拼接

```python
import soundfile as sf
import numpy as np

# 分别用中英文模型合成
audio_en, sr = sf.read("english_part.wav")
audio_zh, sr = sf.read("chinese_part.wav")

# 拼接
combined = np.concatenate([audio_en, audio_zh])
sf.write("combined.wav", combined, sr)
```

### 方案 2: 使用多语言模型

推荐使用 [vits-melo-tts-zh_en](https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models)，原生支持中英文混合。

## 常见问题

### Q: PC 上准备模型时报错 "No module named 'rknn'"

```bash
source .venv/bin/activate
pip install rknn-toolkit2
```

### Q: 导出 ONNX 时报错 "No module named 'transformers'"

```bash
pip install transformers torch
```

### Q: RKNN 转换失败

确保使用 rknn-toolkit2 >= 2.0.0：

```bash
pip install rknn-toolkit2 --upgrade
```

### Q: RKNN 转换时报错 "AttributeError: module 'onnx' has no attribute 'mapping'"

这是 **onnx 版本与 rknn-toolkit2 不兼容** 的问题。rknn-toolkit2 2.3.2 要求 onnx 版本在 1.16.0-1.16.x 之间，但默认安装的 onnx 1.21.0 不兼容。

**解决方法**：锁定 onnx 版本

```bash
pip install 'onnx>=1.16.0,<1.17.0' 'numpy<=1.26.4' 'protobuf<=4.25.4'
```

**注意**：如果使用 `prepare_models.sh` 脚本，脚本已内置正确的版本锁定。如果手动安装依赖，请务必指定版本。

版本要求：
| 包名 | 版本要求 | 说明 |
|------|----------|------|
| onnx | 1.16.0 - 1.16.x | 必须有 mapping 属性 |
| numpy | <= 1.26.4 | 与 rknn-toolkit2 兼容 |
| protobuf | <= 4.25.4 | 与 rknn-toolkit2 兼容 |

### Q: 音频质量不好

尝试调整 max_length 参数，确保文本长度不超过设置值。

## 参考资料

- [rknn_model_zoo/examples/mms_tts](https://github.com/airockchip/rknn_model_zoo/tree/main/examples/mms_tts) - 官方示例
- [MMS-TTS HuggingFace](https://huggingface.co/facebook/mms-tts)
- [RKNN-Toolkit2](https://github.com/airockchip/rknn-toolkit2)

## 许可证

MMS-TTS 模型遵循其原始许可证 (CC BY-NC 4.0)。本项目代码遵循 MIT 许可证。
