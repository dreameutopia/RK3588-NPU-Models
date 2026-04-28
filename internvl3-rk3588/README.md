# InternVL3 RK3588 部署包

本项目提供 InternVL3 多模态模型在 RK3588 平台上的完整部署方案。

> **重要说明**: 本文档所有路径均为相对路径，执行任何命令前请确保已进入本项目根目录：
> ```bash
> cd internvl3-rk3588
> ```

## 目录结构

```
internvl3-rk3588/
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
│   ├── internvl3-1b_vision_fp16_rk3588.rknn   # Vision模型 (需复制)
│   └── internvl3-1b_w8a8_rk3588.rkllm         # LLM模型 (需复制)
└── test/
    ├── test1.png            # 测试图片1
    ├── test2.png            # 测试图片2
    └── test3.png            # 测试图片3
```

## 快速开始

### 步骤 1: 准备运行时库

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

### 步骤 2: 复制模型文件

将转换好的模型文件复制到 models 目录：

```bash
cp /path/to/internvl3-1b_vision_fp16_rk3588.rknn models/
cp /path/to/internvl3-1b_w8a8_rk3588.rkllm models/
```

### 步骤 3: 编译

**在RK3588开发板上直接编译：**
```bash
chmod +x build.sh
./build.sh
```

**交叉编译（在PC上编译）：**
```bash
./build.sh -c ~/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu
```

编译完成后，会在 `install/demo_Linux_aarch64` 目录下生成可执行文件。

### 步骤 4: 部署到RK3588设备

```bash
# 推送到设备
adb push install/demo_Linux_aarch64 /data

# 进入设备shell
adb shell
```

## 在RK3588上开始推理

### 方式一：交互模式

```bash
cd /data/demo_Linux_aarch64
export LD_LIBRARY_PATH=./lib
./run.sh
```

运行后进入交互模式：

```
==========================================
InternVL3 RK3588 Demo
==========================================
Vision Model: ./models/internvl3-1b_vision_fp16_rk3588.rknn
LLM Model: ./models/internvl3-1b_w8a8_rk3588.rkllm
Image: ./test/test1.png
Max Tokens: 256
NPU Cores: 3
==========================================

rkllm init success
main: LLM Model loaded in 1234.56 ms
model input num: 1, output num: 1
...
main: ImgEnc Model loaded in 567.89 ms
Original image size: 640 x 480
Resized image size: 448 x 448
main: ImgEnc Model inference took 2080.12 ms

********************** 可输入以下问题对应序号获取回答 / 或自定义输入 ********************

[0] <image>What is in the image?
[1] <image>这张图片中有什么？

*************************************************************************

user: 0
<image>What is in the image?
robot: The image shows...

========== Performance Statistics ==========
First Token Time:     649.00 ms
Total Inference Time: 1234.56 ms
Total Tokens:        50
Token Rate:          40.50 tokens/s
============================================
```

**特殊命令：**
- 输入 `exit` 退出程序
- 输入 `clear` 清除KV缓存

### 方式二：单图测试

```bash
cd /data/demo_Linux_aarch64
export LD_LIBRARY_PATH=./lib
./test_single.sh
```

或指定图片和提示：

```bash
./test_single.sh -i ./test/test1.png -p "<image>请描述这张图片"
```

### 方式三：多图并发测试

```bash
cd /data/demo_Linux_aarch8
export LD_LIBRARY_PATH=./lib
./test_multi.sh
```

同时测试test目录下的三张图片，验证多路并发能力。

## 运行参数

```bash
./run.sh [OPTIONS] [IMAGE_PATH]

选项:
  -i, --image PATH      图片路径
  -v, --vision MODEL    Vision模型路径 (默认: ./models/internvl3-1b_vision_fp16_rk3588.rknn)
  -l, --llm MODEL       LLM模型路径 (默认: ./models/internvl3-1b_w8a8_rk3588.rkllm)
  -t, --tokens NUM      最大生成token数 (默认: 256)
  -n, --cores NUM       NPU核心数 (RK3588默认: 3)
  -h, --help            显示帮助信息

示例:
  ./run.sh                                    # 使用默认设置
  ./run.sh -i ./test/test1.png                # 指定图片
  ./run.sh -t 512 -i ./test/test2.png         # 自定义token数和图片
  ./run.sh -v ./models/custom_vision.rknn -l ./models/custom_llm.rkllm
```

## 性能优化

### 1. NPU提频

为获得最佳性能，建议运行前执行提频脚本：

```bash
# 在RK3588设备上执行
../rknn-llm/scripts/fix_freq_rk3588.sh
```

### 2. 内存优化

确保设备有足够的可用内存（建议≥2GB）：

```bash
# 检查可用内存
free -h

# 清理缓存
sync && echo 3 > /proc/sys/vm/drop_caches
```

### 3. NPU核心配置

RK3588有3个NPU核心，默认使用全部3核：
- 单核模式：`-n 1`
- 双核模式：`-n 2`
- 三核模式：`-n 3`（推荐）

## 采样参数说明

本程序默认配置了以下采样参数，针对OCR任务优化：

| 参数 | 值 | 说明 |
|------|-----|------|
| `top_k` | 1 | 保留概率最高的1个token |
| `top_p` | 0.9 | 核采样，保留累计概率90%的token |
| `temperature` | 0.1 | 低温度，输出更确定 |
| `repeat_penalty` | 1.5 | 强惩罚重复token，防止生成循环 |
| `frequency_penalty` | 0.5 | 惩罚频繁出现的token |
| `presence_penalty` | 0.5 | 惩罚已出现的token |
| `max_new_tokens` | 256 | 限制最大输出长度 |

> **注意**: 如需调整参数，请修改 `src/main.cpp` 中的参数设置，然后重新编译。

## 图片分辨率处理

本程序支持任意分辨率的图片输入：

1. **读取图片**: 使用OpenCV读取图片并转换为RGB格式
2. **扩展为正方形**: 将非正方形图片扩展为正方形，背景填充灰色(127.5)
3. **缩放到模型尺寸**: 根据Vision模型的输入尺寸进行缩放（默认448x448）

> **注意**: Vision模型在导出时指定了固定的输入尺寸（如448x448），程序会自动将图片缩放到该尺寸。

## InternVL3 特殊标记

InternVL3 使用以下图像标记：

| 标记 | 说明 |
|------|------|
| `<img>` | 图像开始标记 |
| `</img>` | 图像结束标记 |
| `<IMG_CONTEXT>` | 图像内容标记 |

这些标记在程序中已配置为默认值，如需修改可在运行时通过命令行参数指定。

## 性能参考 (RK3588)

| 阶段 | 耗时 |
|------|------|
| img-encoder (448x448) | 待测试 |
| Prefill | 待测试 |
| Decode | 待测试 |
| 内存占用 | 待测试 |

## 常见问题

### Q: 运行时找不到 librkllmrt.so

确保已正确运行 `./setup.sh` 并设置了 `LD_LIBRARY_PATH`：

```bash
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
```

### Q: 运行时找不到 libomp.so

从交叉编译工具链中复制该库：

```bash
cp ~/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/lib/libomp.so lib/aarch64/
```

### Q: NPU核心设置不生效

检查NPU驱动是否正确加载：

```bash
cat /sys/kernel/debug/rknpu/load
```

### Q: 内存不足

确保设备有足够的可用内存：

```bash
free -h
# 清理缓存
sync && echo 3 > /proc/sys/vm/drop_caches
```

### Q: 编译时找不到 rkllm.h 或 rknn_api.h

确保 `include/` 目录下存在这两个头文件。如果缺失，可以从 `rknn-llm` 仓库复制：

```bash
cp ../rknn-llm/rkllm-runtime/Linux/librkllm_api/include/rkllm.h include/
cp ../rknn-llm/examples/multimodal_model_demo/deploy/3rdparty/librknnrt/Linux/librknn_api/include/rknn_api.h include/
```

### Q: 推理结果不正确

检查以下几点：
1. 确保模型文件与代码中的图像标记匹配
2. 确保Vision模型的输入尺寸正确（默认448x448）
3. 检查采样参数是否适合您的任务

## 模型转换

如需自行转换模型，请参考 `rknn-llm` 仓库的 `examples/multimodal_model_demo/` 目录。

### 环境准备

```bash
pip install transformers torch onnx
pip install rknn-toolkit2 -i https://mirrors.aliyun.com/pypi/simple
pip install rkllm-toolkit
```

### 导出Vision模型

```bash
cd ../rknn-llm/examples/multimodal_model_demo

# 导出ONNX模型
python export/export_vision.py --path=/path/to/InternVL3-1B --model_name=internvl3-1b --height=448 --width=448

# 转换为RKNN模型
python export/export_vision_rknn.py --path=./onnx/internvl3-1b_vision.onnx --model_name=internvl3-1b --target-platform rk3588 --height=448 --width=448
```

### 导出LLM模型

```bash
cd ../rknn-llm/examples/multimodal_model_demo

# 生成量化数据
python data/make_input_embeds_for_quantize.py --path=/path/to/InternVL3-1B

# 导出RKLLM模型
python export/export_rkllm.py --path=/path/to/InternVL3-1B --target-platform rk3588 --num_npu_core 3 --quantized_dtype w8a8 --device cpu
```

### 模型文件说明

转换完成后，将生成以下文件：
- `rknn/internvl3-1b_vision_rk3588.rknn` - Vision模型
- `internvl3-1b_rk3588.rkllm` - LLM模型

将这两个文件复制到 `models/` 目录即可。

## 相关链接

- [rknn-llm](https://github.com/airockchip/rknn-llm)
- [rknn-toolkit2](https://github.com/airockchip/rknn-toolkit2)
- [InternVL3](https://huggingface.co/OpenGVLab/InternVL3-1B)
