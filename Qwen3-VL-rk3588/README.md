# Qwen3-VL RK3588 部署包

本项目提供 Qwen3-VL 多模态模型在 RK3588 平台上的完整部署方案。

> **重要说明**: 本文档所有路径均为相对路径，执行任何命令前请确保已进入本项目根目录：
> ```bash
> cd qwen3-vl-rk3588
> ```

## 目录结构

```
qwen3-vl-rk3588/
├── build.sh                 # 编译脚本
├── CMakeLists.txt           # CMake配置
├── c_export.map             # 符号导出配置
├── setup.sh                 # 环境设置脚本
├── README.md                # 说明文档
├── include/
│   ├── rkllm.h              # RKLLM API头文件
│   └── rknn_api.h           # RKNN API头文件
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
│       ├── librkllmrt.so    # RKLLM运行时库 (需复制)
│       └── libomp.so        # OpenMP库 (如需要)
├── 3rdparty/
│   ├── opencv/              # OpenCV库 (需复制)
│   └── librknnrt/           # RKNN运行时库 (需复制)
├── models/
│   ├── qwen3-vl-2b_vision_rk3588.rknn           # Vision模型 (需复制)
│   └── qwen3-vl-2b-instruct_w8a8_rk3588.rkllm   # LLM模型 (需复制)
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

或手动复制：

```bash
# 复制RKLLM运行时库
cp ../rknn-llm/rkllm-runtime/Linux/librkllm_api/aarch64/librkllmrt.so lib/aarch64/

# 复制RKNN运行时库
mkdir -p 3rdparty/librknnrt/Linux/librknn_api/aarch64
cp ../rknn-llm/examples/multimodal_model_demo/deploy/3rdparty/librknnrt/Linux/librknn_api/aarch64/librknnrt.so 3rdparty/librknnrt/Linux/librknn_api/aarch64/
cp -r ../rknn-llm/examples/multimodal_model_demo/deploy/3rdparty/librknnrt/Linux/librknn_api/include 3rdparty/librknnrt/Linux/librknn_api/

# 复制OpenCV库
cp -r ../rknn-llm/examples/multimodal_model_demo/deploy/3rdparty/opencv/opencv-linux-aarch64 3rdparty/opencv/
```

### 2. 复制模型文件

```bash
cp /path/to/qwen3-vl-2b_vision_rk3588.rknn models/
cp /path/to/qwen3-vl-2b-instruct_w8a8_rk3588.rkllm models/
```

### 3. 编译并运行

详细的编译、部署和运行说明请参考：[RUN_ON_RK3588.md](RUN_ON_RK3588.md)

### 4. 采样参数说明

本程序默认配置了以下采样参数，针对OCR任务优化，避免重复生成：

| 参数 | 值 | 说明 |
|------|-----|------|
| `top_k` | 1 | 保留概率最高的1个token |
| `top_p` | 0.9 | 核采样，保留累计概率90%的token |
| `temperature` | 0.1 | 低温度，输出更确定，适合OCR |
| `repeat_penalty` | 1.5 | 强惩罚重复token，防止生成循环 |
| `frequency_penalty` | 0.5 | 惩罚频繁出现的token |
| `presence_penalty` | 0.5 | 惩罚已出现的token |
| `max_new_tokens` | 256 | 限制最大输出长度 |

> **注意**: 如果需要调整这些参数，请修改 `src/main.cpp` 中的参数设置，然后重新编译。

### 5. 性能参考 (RK3588)

| 阶段 | 耗时 |
|------|------|
| img-encoder (448x448) | ~2.08s |
| Prefill (len=196) | ~649ms |
| Decode | ~14.91 tokens/s |
| 内存占用 | ~1.9GB |

## 模型转换

如需自行转换模型，请参考 `rknn-llm` 仓库的 `examples/multimodal_model_demo/` 目录。

**导出Vision模型：**
```bash
pip install transformers==4.57.0
cd ../rknn-llm/examples/multimodal_model_demo
python export/export_vision.py --path=/path/to/Qwen3-VL --model_name=qwen3-vl --height=448 --width=448
python export/export_vision_rknn.py --path=./onnx/qwen3-vl_vision.onnx --model_name=qwen3-vl --target-platform rk3588
```

**导出LLM模型：**
```bash
cd ../rknn-llm/examples/multimodal_model_demo
python export/export_rkllm.py --path=/path/to/Qwen3-VL --target-platform rk3588 --num_npu_core 3 --quantized_dtype w8a8
```

## 相关链接

- [rknn-llm](https://github.com/airockchip/rknn-llm)
- [rknn-toolkit2](https://github.com/airockchip/rknn-toolkit2)
- [Qwen3-VL](https://huggingface.co/Qwen)
