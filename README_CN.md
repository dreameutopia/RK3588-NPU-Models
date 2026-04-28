<div align="center">

# RK3588 Model Zoo

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./.github/CONTRIBUTING.md)
[![Issue](https://img.shields.io/badge/Issues-welcome-blue.svg)](./.github/CONTRIBUTING.md)

专为 Radxa Rock 5T 验证、设计、适配的 RK3588 AI 模型部署集合

[English](./README.md) | **中文**

</div>

---

## 项目简介

本项目是一个面向 RK3588 NPU 平台的 AI 模型部署集合，所有模型均已在 Radxa Rock 5T 开发板上完成验证与适配。项目基于 Rockchip RKNN/RKLLM 工具链，将主流 AI 模型转换为 RKNN/RKLLM 格式，实现 NPU 加速推理。

## 支持的模型

| 模型 | 类型 | 任务 | 详情 |
|------|------|------|------|
| [Qwen3-VL](./qwen3-vl-rk3588) | 多模态 | 视觉理解 | Qwen3-VL-2B 视觉语言模型 |
| [InternVL3](./internvl3-rk3588) | 多模态 | 视觉理解 | InternVL3-1B 视觉语言模型 |
| [DeepSeek-OCR](./deepseek-ocr-rk3588) | 多模态 | OCR 文字识别 | DeepSeek-OCR 光学字符识别 |
| [PPOCRv4](./ppocr-rk3588) | CV | OCR 文字识别 | PaddleOCR v4 文字识别 |
| [Whisper](./whisper-rk3588) | 语音 | 语音识别 (ASR) | OpenAI Whisper 语音转文字 |
| [MMS-TTS](./mms_tts-rk3588) | 语音 | 语音合成 (TTS) | Facebook MMS-TTS 文字转语音 |
| [Qwen3-Embedding](./Qwen3-Embedding-rk3588) | NLP | 文本嵌入 | Qwen3-Embedding-0.6B 文本表示 |
| [Qwen3-Rerank](./qwen3-rerank-rk3588) | NLP | 重排序 | Qwen3-Reranker-0.6B 文本重排序 |

## 快速开始

### 环境准备

请先阅读以下指南配置开发环境：

- [克隆官方仓库指南](./CLONE_GUIDE.md) - 导入 rknn-llm 和 rknn_model_zoo 官方仓库
- [Conda 环境配置指南](./CONDA_GUIDE.md) - 配置 RKNN 开发所需的 Conda 环境

### 系统依赖

```bash
apt-get install libglib2.0-0
apt-get install libgl1-mesa-glx libgl1-mesa-dev
apt-get install -y libglib2.0-0
```

### 使用步骤

1. 按照 [克隆官方仓库指南](./CLONE_GUIDE.md) 导入依赖仓库
2. 按照 [Conda 环境配置指南](./CONDA_GUIDE.md) 配置开发环境
3. 选择上方表格中的模型，进入对应目录查看详细部署说明

## 项目结构

```
.
├── qwen3-vl-rk3588/           # Qwen3-VL 视觉语言模型
├── internvl3-rk3588/           # InternVL3 视觉语言模型
├── deepseek-ocr-rk3588/        # DeepSeek-OCR 光学字符识别
├── ppocr-rk3588/               # PaddleOCR v4 文字识别
├── whisper-rk3588/             # Whisper 语音识别
├── mms_tts-rk3588/             # MMS-TTS 语音合成
├── Qwen3-Embedding-rk3588/     # Qwen3-Embedding 文本嵌入
├── qwen3-rerank-rk3588/        # Qwen3-Rerank 文本重排序
├── clone_repos.sh              # 一键克隆脚本
├── setup_conda_env.sh          # Conda 环境配置脚本
├── CLONE_GUIDE.md              # 克隆指南
├── CONDA_GUIDE.md              # Conda 配置指南
└── README.md                   # 英文说明文档
```

## 参与贡献

我们非常欢迎社区贡献！无论是提交 Bug、建议新功能、还是适配新模型，请阅读 [贡献指南](./.github/CONTRIBUTING.md) 了解如何参与。

## 行为准则

本项目采用 [Contributor Covenant](./.github/CODE_OF_CONDUCT.md) 行为准则，参与本项目即表示您同意遵守其条款。

## 许可证

本项目基于 [Apache License 2.0](./LICENSE) 开源。

## 致谢

- [Rockchip RKNN Toolkit2](https://github.com/airockchip/rknn-toolkit2) - RKNN 模型转换工具
- [rknn-llm](https://github.com/airockchip/rknn-llm) - RKLLM 大语言模型部署框架
- [rknn_model_zoo](https://github.com/airockchip/rknn_model_zoo) - RKNN 模型库参考实现
- [Radxa](https://radxa.com/) - Rock 5T 开发板

---

> ⚠️ **注意**：本项目目前处于初步构建阶段，部分模型尚未通过完整实例测试，欢迎关注后续更新和更多模型的适配。
