# DeepSeek-OCR RK3588 部署包

本项目提供 DeepSeek-OCR 模型在 RK3588 平台上的完整部署方案，专为 OCR（光学字符识别）任务优化。

> **重要说明**: 本文档所有路径均为相对路径，执行任何命令前请确保已进入本项目根目录：
> ```bash
> cd deepseek-ocr-rk3588
> ```

## 目录结构

```
deepseek-ocr-rk3588/
├── build.sh                 # 编译脚本
├── CMakeLists.txt           # CMake配置
├── c_export.map             # 符号导出配置
├── setup.sh                 # 环境设置脚本
├── README.md                # 说明文档
├── include/
│   └── rkllm.h              # RKLLM API头文件
├── src/
│   ├── image_enc.h          # 图像编码器头文件
│   ├── image_enc.cc         # 图像编码器实现
│   ├── img_encoder.cpp      # 独立图像编码工具
│   └── main.cpp             # 主程序
├── scripts/
│   ├── run.sh               # 运行脚本
│   ├── test_single.sh       # 单图测试脚本
│   └── test_multi.sh        # 多图并发测试脚本
├── lib/
│   └── aarch64/
│       └── librkllmrt.so    # RKLLM运行时库 (需复制)
├── 3rdparty/
│   ├── opencv/              # OpenCV库 (需复制)
│   └── librknnrt/           # RKNN运行时库 (需复制)
├── models/
│   ├── deepseekocr_vision_rk3588.rknn    # Vision模型 (需复制)
│   └── deepseekocr_w4a16_rk3588.rkllm    # LLM模型 (需复制)
└── test/
    ├── test1.png            # 测试图片1
    ├── test2.png            # 测试图片2
    └── test3.png            # 测试图片3
```

## 快速开始

### 1. 准备运行时库

使用 `setup.sh` 脚本自动复制依赖库：

```bash
chmod +x setup.sh
./setup.sh -s ../rknn-llm
```

### 2. 复制模型文件

```bash
cp /path/to/deepseekocr_vision_rk3588.rknn models/
cp /path/to/deepseekocr_w4a16_rk3588.rkllm models/
```

### 3. 编译

**在RK3588开发板上直接编译：**
```bash
chmod +x build.sh
./build.sh
```

**交叉编译（在PC上编译）：**
```bash
./build.sh -c ~/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu
```

### 4. 部署到设备

```bash
adb push install/demo_Linux_aarch64 /data

adb shell
cd /data/demo_Linux_aarch64
export LD_LIBRARY_PATH=./lib
chmod +x run.sh
./run.sh
```

## 一键测试推理

### 单图测试

测试test目录下的单张图片：

```bash
cd install/demo_Linux_aarch64
./test_single.sh
```

### 多图并发测试

同时测试test目录下的三张图片（多路并发任务测试）：

```bash
cd install/demo_Linux_aarch64
./test_multi.sh
```

测试脚本会实时打印：
- 推理结果
- 推理用时
- Token速率
- 首Token耗时

## DeepSeek-OCR 特殊配置

DeepSeek-OCR 与其他多模态模型（如 Qwen3-VL）有以下关键差异：

| 配置项 | DeepSeek-OCR | Qwen3-VL |
|--------|--------------|----------|
| `img_start` | `""` (空) | `<\|vision_start\|>` |
| `img_end` | `""` (空) | `<\|vision_end\|>` |
| `img_content` | `<｜▁pad▁｜>` | `<\|image_pad\|>` |

> **重要**: `img_content` 使用的是**全角竖线** `｜` (U+FF5C)，而不是半角竖线 `|` (U+007C)。pad 两边的 `▁` 是下划线字符 (U+2581)。

这些配置已在代码中预设，无需手动指定。

## Prompt 格式

DeepSeek-OCR 支持以下 prompt 格式：

| Prompt | 用途 |
|--------|------|
| `<image>\nFree OCR.` | 简单 OCR 识别 |
| `<image>\n<\|grounding\|>Convert the document to markdown.` | 转换为 Markdown 格式 |

> **注意**: `<image>` 标签后需要换行，然后再输入具体指令。

## 采样参数说明

本程序默认配置了以下采样参数，针对OCR任务优化：

| 参数 | 值 | 说明 |
|------|-----|------|
| `top_k` | 1 | 保留概率最高的1个token |
| `top_p` | 0.9 | 核采样，保留累计概率90%的token |
| `temperature` | 0.0 | 确定性输出，适合OCR任务 |
| `repeat_penalty` | 1.0 | 不惩罚重复token |
| `frequency_penalty` | 0.0 | 不惩罚频繁出现的token |
| `presence_penalty` | 0.0 | 不惩罚已出现的token |
| `skip_special_token` | false | 保留特殊token |
| `max_new_tokens` | 256 | 限制最大输出长度 |

> **注意**: 这些参数是根据 DeepSeek-OCR 官方推荐配置设置的。如果需要调整，请修改 `src/main.cpp` 中的参数设置，然后重新编译。

## 图片分辨率处理

本程序支持任意分辨率的图片输入，处理流程如下：

1. **读取图片**: 使用OpenCV读取图片并转换为RGB格式
2. **扩展为正方形**: 使用`expand2square`函数将非正方形图片扩展为正方形，背景填充灰色(127.5)
3. **缩放到模型尺寸**: 根据Vision模型的输入尺寸要求进行缩放（默认448x448）

## 性能参考 (RK3588)

| 阶段 | 耗时 |
|------|------|
| img-encoder (448x448) | ~1.5s |
| Prefill | ~800ms |
| Decode | ~30 tokens/s |
| 内存占用 | ~1.5GB |

## 注意事项

1. **NPU核心数**: RK3588有3个NPU核心，RK3576有2个，请根据平台设置正确的核心数
2. **提频**: 为获得最佳性能，建议运行前执行提频脚本 `../rknn-llm/scripts/fix_freq_rk3588.sh`
3. **内存**: 确保设备有足够的内存（建议≥2GB可用内存）
4. **libomp.so**: 如果遇到 `libomp.so not found` 错误，需要从交叉编译工具链中复制该库

## 模型转换

如需自行转换模型，请参考 `rknn-llm` 仓库的 `examples/multimodal_model_demo/` 目录。

**导出Vision模型：**
```bash
cd ../rknn-llm/examples/multimodal_model_demo
python export/export_vision.py --path=/path/to/DeepSeek-OCR --model_name=deepseekocr --height=448 --width=448
python export/export_vision_rknn.py --path=./onnx/deepseekocr_vision.onnx --model_name=deepseekocr --target-platform rk3588
```

**导出LLM模型：**
```bash
cd ../rknn-llm/examples/multimodal_model_demo
python export/export_rkllm.py --path=/path/to/DeepSeek-OCR --target-platform rk3588 --num_npu_core 3 --quantized_dtype w4a16
```

## 相关链接

- [rknn-llm](https://github.com/airockchip/rknn-llm)
- [rknn-toolkit2](https://github.com/airockchip/rknn-toolkit2)
- [DeepSeek-OCR](https://huggingface.co/deepseek-ai/DeepSeek-OCR)
