# Qwen3-Embedding RK3588 部署包

本项目提供 Qwen3-Embedding 文本嵌入模型在 RK3588 平台上的完整部署方案。

> **重要说明**: 本文档所有路径均为相对路径，执行任何命令前请确保已进入本项目根目录：
> ```bash
> cd Qwen3-Embedding-rk3588
> ```

## 目录结构

```
Qwen3-Embedding-rk3588/
├── build.sh                 # 编译脚本
├── CMakeLists.txt           # CMake配置
├── c_export.map             # 符号导出配置
├── setup.sh                 # 环境设置脚本
├── README.md                # 说明文档
├── include/
│   └── rkllm.h              # RKLLM API头文件
├── src/
│   └── main.cpp             # 主程序
├── scripts/
│   ├── run.sh               # 运行脚本
│   ├── test_single.sh       # 单次测试脚本
│   └── test_batch.sh        # 批量测试脚本
├── lib/
│   └── aarch64/
│       └── librkllmrt.so    # RKLLM运行时库 (需复制)
├── models/
│   └── Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm  # 模型文件 (需复制)
└── test/
    └── sentences.txt        # 测试文本
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
```

### 2. 复制模型文件

```bash
cp /path/to/Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm models/
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

## 在 RK3588 上开始推理

### 方法一：交互模式

```bash
cd install/demo_Linux_aarch64
export LD_LIBRARY_PATH=./lib
./run.sh
```

进入交互模式后：

```
********************** Qwen3-Embedding Interactive Mode ********************
Commands:
  embed <text>                      - Generate embedding vector for text
  similarity <text1> | <text2>      - Compute cosine similarity between texts
  batch <file>                      - Batch embed texts from file
  exit                              - Exit program
*************************************************************************

user: embed What is machine learning?
robot: Embedding generated: dim=1024, norm=1.0000 (Inference Time: 45.23 ms)

user: similarity What is AI? | Artificial Intelligence is a field of computer science.
robot: Cosine Similarity: 0.8542 (Inference Time: 90.46 ms)
```

### 方法二：单次嵌入测试

```bash
cd install/demo_Linux_aarch64
export LD_LIBRARY_PATH=./lib
./test_single.sh
```

或自定义文本：

```bash
./test_single.sh -t "What is deep learning?"
```

### 方法三：批量嵌入测试

```bash
cd install/demo_Linux_aarch64
export LD_LIBRARY_PATH=./lib
./test_batch.sh
```

或指定文本文件：

```bash
./test_batch.sh -f ./test/sentences.txt
```

## 运行参数

```bash
./run.sh [OPTIONS]

选项:
  -l, --llm MODEL       LLM模型路径
  -c, --context NUM     最大上下文长度 (默认: 4096)
  -n, --cores NUM       NPU核心数 (RK3588默认: 3)
  -h, --help            显示帮助信息

示例:
  ./run.sh                                    # 使用默认设置
  ./run.sh -l ./models/custom_embedding.rkllm # 指定模型路径
```

## Embedding 模型说明

Qwen3-Embedding 是一个文本嵌入模型，用于将文本转换为高维向量表示。模型输出一个固定维度的向量（通常为 1024 维），可以用于：

### 典型应用场景

1. **语义搜索**: 将查询和文档转换为向量进行相似度匹配
2. **文本聚类**: 对文本进行语义聚类分析
3. **RAG 系统**: 为检索增强生成系统提供文档嵌入
4. **推荐系统**: 基于文本相似度进行内容推荐

### 嵌入向量特点

- **维度**: 1024 维浮点向量
- **归一化**: 输出向量已归一化，可直接用于余弦相似度计算
- **池化方式**: 使用最后一个 token 的隐藏层作为嵌入向量

### 相似度计算

使用余弦相似度计算两个文本向量的相似性：

```
similarity = dot(a, b) / (norm(a) * norm(b))
```

由于输出向量已归一化，余弦相似度简化为点积：

```
similarity = dot(a, b)
```

## 性能参考 (RK3588)

| 指标 | 数值 |
|------|------|
| 单次推理时间 | ~45ms |
| 批量处理速度 | ~22 texts/s |
| 向量维度 | 1024 |
| 内存占用 | ~500MB |

## 注意事项

1. **NPU核心数**: RK3588有3个NPU核心，RK3576有2个，请根据平台设置正确的核心数
2. **提频**: 为获得最佳性能，建议运行前执行提频脚本 `../rknn-llm/scripts/fix_freq_rk3588.sh`
3. **内存**: 确保设备有足够的内存（建议≥1GB可用内存）
4. **模型格式**: 确保使用正确格式的 RKLLM 模型文件

## 完整推理流程

### 步骤 1: 设置环境（首次运行）

```bash
# 进入项目目录
cd Qwen3-Embedding-rk3588

# 设置运行时库
./setup.sh -s ../rknn-llm

# 复制模型文件
cp /path/to/Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm models/
```

### 步骤 2: 编译项目

```bash
# 在 RK3588 开发板上编译
./build.sh
```

### 步骤 3: 部署到设备

```bash
# 推送到设备
adb push install/demo_Linux_aarch64 /data

# 进入设备
adb shell
```

### 步骤 4: 在设备上运行

```bash
# 在设备上执行
cd /data/demo_Linux_aarch64

# 设置库路径
export LD_LIBRARY_PATH=./lib

# (可选) 提频以获得最佳性能
bash /path/to/fix_freq_rk3588.sh

# 运行推理
./run.sh
```

## 模型转换

如需自行转换模型，请参考 `rknn-llm` 仓库的相关文档。

**导出Embedding模型：**
```bash
cd ../rknn-llm/examples/llm
python export_rkllm.py --model_path /path/to/Qwen3-Embedding \
                       --target_platform rk3588 \
                       --num_npu_core 3 \
                       --quantized_dtype w8a8
```

## 相关链接

- [rknn-llm](https://github.com/airockchip/rknn-llm)
- [rknn-toolkit2](https://github.com/airockchip/rknn-toolkit2)
- [Qwen3-Embedding](https://huggingface.co/Qwen)
