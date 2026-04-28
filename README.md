<div align="center">

# RK3588 Model Zoo

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./.github/CONTRIBUTING.md)
[![Issue](https://img.shields.io/badge/Issues-welcome-blue.svg)](./.github/CONTRIBUTING.md)

A collection of AI model deployments for the RK3588 NPU platform, verified and optimized for the Radxa Rock 5T

**English** | [中文](./README_CN.md)

</div>

---

## Introduction

This project is a collection of AI model deployments targeting the RK3588 NPU platform. All models have been verified and adapted on the Radxa Rock 5T development board. Built on the Rockchip RKNN/RKLLM toolchain, it converts mainstream AI models into RKNN/RKLLM formats for NPU-accelerated inference.

## Supported Models

| Model | Category | Task | Details |
|-------|----------|------|---------|
| [Qwen3-VL](./qwen3-vl-rk3588) | Multimodal | Visual Understanding | Qwen3-VL-2B vision-language model |
| [InternVL3](./internvl3-rk3588) | Multimodal | Visual Understanding | InternVL3-1B vision-language model |
| [DeepSeek-OCR](./deepseek-ocr-rk3588) | Multimodal | OCR | DeepSeek-OCR optical character recognition |
| [PPOCRv4](./ppocr-rk3588) | CV | OCR | PaddleOCR v4 text recognition |
| [Whisper](./whisper-rk3588) | Audio | Speech Recognition (ASR) | OpenAI Whisper speech-to-text |
| [MMS-TTS](./mms_tts-rk3588) | Audio | Text-to-Speech (TTS) | Facebook MMS-TTS multilingual synthesis |
| [Qwen3-Embedding](./Qwen3-Embedding-rk3588) | NLP | Text Embedding | Qwen3-Embedding-0.6B text representation |
| [Qwen3-Rerank](./qwen3-rerank-rk3588) | NLP | Reranking | Qwen3-Reranker-0.6B text reranking |

## Getting Started

### Prerequisites

Before you begin, please read the following guides to set up your development environment:

- [Clone Guide](./CLONE_GUIDE.md) - Import the official rknn-llm and rknn_model_zoo repositories
- [Conda Setup Guide](./CONDA_GUIDE.md) - Configure the Conda environment required for RKNN development

### System Dependencies

```bash
apt-get install libglib2.0-0
apt-get install libgl1-mesa-glx libgl1-mesa-dev
apt-get install -y libglib2.0-0
```

### Usage

1. Follow the [Clone Guide](./CLONE_GUIDE.md) to import dependency repositories
2. Follow the [Conda Setup Guide](./CONDA_GUIDE.md) to configure your development environment
3. Choose a model from the table above and navigate to its directory for detailed deployment instructions

## Project Structure

```
.
├── qwen3-vl-rk3588/           # Qwen3-VL vision-language model
├── internvl3-rk3588/           # InternVL3 vision-language model
├── deepseek-ocr-rk3588/        # DeepSeek-OCR optical character recognition
├── ppocr-rk3588/               # PaddleOCR v4 text recognition
├── whisper-rk3588/             # Whisper speech recognition
├── mms_tts-rk3588/             # MMS-TTS text-to-speech
├── Qwen3-Embedding-rk3588/     # Qwen3-Embedding text embedding
├── qwen3-rerank-rk3588/        # Qwen3-Rerank text reranking
├── clone_repos.sh              # One-click clone script
├── setup_conda_env.sh          # Conda environment setup script
├── CLONE_GUIDE.md              # Repository cloning guide
├── CONDA_GUIDE.md              # Conda setup guide
└── README_CN.md                # Chinese documentation
```

## Contributing

We warmly welcome community contributions! Whether it's filing bugs, suggesting features, or adapting new models, please read the [Contributing Guide](./.github/CONTRIBUTING.md) to get started.

## Code of Conduct

This project follows the [Contributor Covenant](./.github/CODE_OF_CONDUCT.md) Code of Conduct. By participating, you are expected to uphold this code.

## License

This project is licensed under the [Apache License 2.0](./LICENSE).

## Acknowledgements

- [Rockchip RKNN Toolkit2](https://github.com/airockchip/rknn-toolkit2) - RKNN model conversion toolkit
- [rknn-llm](https://github.com/airockchip/rknn-llm) - RKLLM large language model deployment framework
- [rknn_model_zoo](https://github.com/airockchip/rknn_model_zoo) - RKNN model zoo reference implementations
- [Radxa](https://radxa.com/) - Rock 5T development board

---

> ⚠️ **Note**: This project is currently in its early stages of development. Some models have not yet passed complete integration testing. Stay tuned for updates and more model adaptations.
