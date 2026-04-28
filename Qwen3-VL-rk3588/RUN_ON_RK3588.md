# Qwen3-VL RK3588 板子运行指南

本文档介绍如何在 RK3588 开发板上编译、部署和运行 Qwen3-VL 多模态模型。

## 前提条件

- ✅ RKNN 和 RKLLM 模型文件已准备就绪（位于 `models/` 目录）
- ✅ 已设置好运行时库（通过 `setup.sh -s ../rknn-llm`）
- ✅ RK3588 开发板上已准备好 gcc 编译器

## 目录结构

在 RK3588 板子上的项目目录结构：

```
qwen3-vl-rk3588/
├── install/
│   └── demo_Linux_aarch64/  # 编译输出目录
│       ├── demo             # 主程序可执行文件
│       ├── run.sh           # 便捷运行脚本
│       ├── test_single.sh   # 单图测试脚本
│       ├── test_multi.sh    # 多图并发测试脚本
│       ├── lib/             # 运行时库
│       │   ├── aarch64/
│       │   │   └── librkllmrt.so  # RKLLM运行时库
│       │   └── librknnrt.so
│       ├── 3rdparty/        # 第三方库
│       │   ├── librknnrt/   # RKNN运行时库
│       │   └── opencv/      # OpenCV图像处理库
│       ├── models/          # 模型文件
│       │   ├── qwen3-vl-2b_vision_rk3588.rknn        # Vision模型
│       │   └── qwen3-vl-2b-instruct_w8a8_rk3588.rkllm  # LLM模型
│       └── test/            # 测试图片
│           ├── test1.png
│           ├── test2.png
│           └── test3.png
├── src/                 # 源代码
└── build.sh            # 编译脚本
```

## 步骤 1: 在 RK3588 开发板上编译项目

在 RK3588 开发板上直接编译项目：

```bash
# 进入项目目录
cd qwen3-vl-rk3588

# 添加执行权限
chmod +x build.sh

# 编译项目（默认在板子上编译）
./build.sh
```

### 编译输出

编译成功后，会在 `install/demo_Linux_aarch64/` 目录下生成可执行文件：

```bash
ls -la install/demo_Linux_aarch64/
# 应该看到 demo 可执行文件和 lib/ 目录
```

## 步骤 2: 在 RK3588 开发板上运行

### 基本运行流程

```bash
# 进入编译输出目录
cd install/demo_Linux_aarch64

# 设置库路径
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH

# 添加运行脚本执行权限
chmod +x run.sh
chmod +x test_single.sh
chmod +x test_multi.sh
```

### 运行模式

#### 交互模式

```bash
./run.sh
```

进入交互模式后，可以选择预设问题或自定义输入：

```
**********************
可输入以下问题对应序号获取回答 / 或自定义输入
**********************

[0] <image>What is in the image?
[1] <image>这张图片中有什么？

user: 0
<image>What is in the image?
robot: The image shows...
```

**特殊命令：**
- 输入 `exit` 退出程序
- 输入 `clear` 清除 KV 缓存

#### 单图测试模式

```bash
# 使用默认图片和提示
./test_single.sh

# 自定义图片和提示
./test_single.sh -i ./test/test1.png -p "<image>请识别图片中的所有文字。"
```

#### 多图并发测试模式

```bash
./test_multi.sh
```

## 运行参数

### run.sh 参数

```bash
./run.sh [OPTIONS] [IMAGE_PATH]

选项:
  -v, --vision MODEL    Vision模型路径 (默认: ./models/qwen3-vl-2b_vision_rk3588.rknn)
  -l, --llm MODEL       LLM模型路径 (默认: ./models/qwen3-vl-2b-instruct_w8a8_rk3588.rkllm)
  -t, --tokens NUM      最大生成token数 (默认: 2048)
  -c, --context NUM     最大上下文长度 (默认: 4096)
  -n, --cores NUM       NPU核心数 (RK3588默认: 3)
  -h, --help            显示帮助信息
```

### 示例

```bash
# 使用默认设置
./run.sh

# 自定义 token 数和图片
./run.sh -t 1024 ./test/test1.png

# 指定自定义模型
./run.sh -v ./models/custom_vision.rknn -l ./models/custom_llm.rkllm

# 指定 NPU 核心数（RK3576 使用 2）
./run.sh -n 2
```

## 性能优化

### 提频脚本

为获得最佳性能，建议在运行前执行提频脚本：

```bash
# 提频（RK3588）
bash /path/to/fix_freq_rk3588.sh

# 运行推理
./run.sh
```

提频脚本位置：`../rknn-llm/scripts/fix_freq_rk3588.sh`

## 采样参数说明

程序默认配置了以下采样参数，针对 OCR 任务优化：

| 参数 | 值 | 说明 |
|------|-----|------|
| `top_k` | 1 | 保留概率最高的1个token |
| `top_p` | 0.9 | 核采样，保留累计概率90%的token |
| `temperature` | 0.1 | 低温度，输出更确定，适合OCR |
| `repeat_penalty` | 1.5 | 强惩罚重复token，防止生成循环 |
| `frequency_penalty` | 0.5 | 惩罚频繁出现的token |
| `presence_penalty` | 0.5 | 惩罚已出现的token |
| `max_new_tokens` | 256 | 限制最大输出长度 |

> **注意**：如果需要调整这些参数，请修改 `src/main.cpp` 中的参数设置，然后重新编译。

## 性能参考

### RK3588 性能数据

| 阶段 | 耗时 |
|------|------|
| img-encoder (448x448) | ~2.08s |
| Prefill (len=196) | ~649ms |
| Decode | ~14.91 tokens/s |
| 内存占用 | ~1.9GB |

### NPU 核心配置

| 平台 | NPU 核心数 | 参数设置 |
|------|-----------|---------|
| RK3588 | 3 | `-n 3` |
| RK3576 | 2 | `-n 2` |

## 完整运行流程

```
┌─────────────────────────────────────────────────────────────┐
│                      RK3588 开发板                           │
│                                                              │
│  1. 进入项目目录                                              │
│     cd qwen3-vl-rk3588                                       │
│                                                              │
│  2. 编译项目                                                  │
│     ./build.sh                                               │
│                                                              │
│  3. 进入编译输出目录                                          │
│     cd install/demo_Linux_aarch64                            │
│                                                              │
│  4. 设置库路径                                                │
│     export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH           │
│                                                              │
│  5. 运行推理                                                  │
│     ./run.sh                                                 │
└─────────────────────────────────────────────────────────────┘
```

## 图片分辨率处理

程序支持任意分辨率的图片输入，处理流程如下：

1. **读取图片**：使用 OpenCV 读取图片并转换为 RGB 格式
2. **扩展为正方形**：使用 `expand2square` 函数将非正方形图片扩展为正方形，背景填充灰色(127.5)
3. **缩放到模型尺寸**：根据 Vision 模型的输入尺寸要求进行缩放（默认 448x448）

> **注意**：Vision 模型在导出时指定了固定的输入尺寸（如 448x448），程序会自动将图片缩放到该尺寸。Qwen3-VL 的 patch_size 为 16，因此输入尺寸应为 16 的倍数。

## 常见问题

### Q: 提示 "Vision model not found"

模型文件未找到。请确保已将模型文件复制到 `models/` 目录：

```bash
ls models/
# 应显示：
# qwen3-vl-2b_vision_rk3588.rknn
# qwen3-vl-2b-instruct_w8a8_rk3588.rkllm
```

如果模型在其他位置，可以使用 `-v` 和 `-l` 参数指定：

```bash
./run.sh -v /path/to/vision.rknn -l /path/to/llm.rkllm
```

### Q: 提示 "librkllmrt.so not found"

库路径未正确设置。请执行：

```bash
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
./run.sh
```

### Q: 内存不足错误

确保设备有足够的内存（建议 ≥2GB 可用内存）：

```bash
free -h
```

如果内存不足，可以：
1. 关闭其他占用内存的程序
2. 减少 `max_context_len` 参数
3. 使用更小的模型

### Q: 推理速度慢

1. **执行提频**：
   ```bash
   bash /path/to/fix_freq_rk3588.sh
   ```

2. **检查 NPU 核心数**：确保使用正确的核心数（RK3588 为 3）
   ```bash
   ./run.sh -n 3
   ```

### Q: 遇到 "libgomp.so not found" 错误

缺少 OpenMP 库。确保在板子上安装了 libgomp：

```bash
# 在 RK3588 板子上
sudo apt-get install libgomp1
```

### Q: 如何测试不同的图片？

使用 `-i` 参数指定图片路径：

```bash
./run.sh -i /path/to/your/image.png
```

## 相关链接

- [rknn-llm](https://github.com/airockchip/rknn-llm)
- [rknn-toolkit2](https://github.com/airockchip/rknn-toolkit2)
- [Qwen3-VL](https://huggingface.co/Qwen)
