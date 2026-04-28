# Qwen3-Embedding RK3588 板子运行指南

本文档介绍如何在 RK3588 开发板上编译、部署和运行 Qwen3-Embedding 文本嵌入模型。

## 前提条件

- ✅ RKLLM 模型文件已准备就绪（位于 `models/` 目录）
- ✅ 已设置好运行时库（通过 `setup.sh -s ../rknn-llm`）
- ✅ RK3588 开发板上已准备好 gcc 编译器

## 目录结构

在 RK3588 板子上的项目目录结构：

```
Qwen3-Embedding-rk3588/
├── install/
│   └── demo_Linux_aarch64/  # 编译输出目录
│       ├── demo             # 主程序可执行文件
│       ├── run.sh           # 便捷运行脚本
│       ├── test_single.sh   # 单次测试脚本
│       ├── test_batch.sh    # 批量测试脚本
│       ├── lib/             # 运行时库
│       │   └── librkllmrt.so  # RKLLM运行时库
│       ├── models/          # 模型文件
│       │   └── Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm  # 模型文件
│       └── test/            # 测试文本
│           └── sentences.txt
├── src/                 # 源代码
└── build.sh            # 编译脚本
```

## 步骤 1: 在 RK3588 开发板上编译项目

在 RK3588 开发板上直接编译项目：

```bash
# 进入项目目录
cd Qwen3-Embedding-rk3588

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
chmod +x test_batch.sh
```

### 运行模式

#### 交互模式

```bash
./run.sh
```

进入交互模式后，可以使用以下命令：

```
********************** Qwen3-Embedding Interactive Mode ********************
Commands:
  embed <text>                      - Generate embedding vector for text
  similarity <text1> | <text2>      - Compute cosine similarity between texts
  batch <file>                      - Batch embed texts from file
  save <text> <filename>            - Generate and save embedding to file
  exit                              - Exit program
*************************************************************************

user: embed What is machine learning?
robot: Embedding generated: dim=1024, norm=1.0000 (Inference Time: 45.23 ms)

user: similarity What is AI? | Artificial Intelligence is a field of computer science.
robot: Cosine Similarity: 0.8542 (Inference Time: 90.46 ms)
```

**交互命令说明：**

| 命令 | 用法 | 说明 |
|------|------|------|
| `embed` | `embed <text>` | 生成文本的嵌入向量 |
| `similarity` | `similarity <text1> \| <text2>` | 计算两个文本的余弦相似度 |
| `batch` | `batch <file>` | 批量处理文件中的文本 |
| `save` | `save <text> <filename>` | 生成嵌入并保存到文件 |
| `exit` | `exit` | 退出程序 |

#### 单次嵌入测试

```bash
# 使用默认文本
./test_single.sh

# 自定义文本
./test_single.sh -t "What is deep learning?"
```

#### 批量嵌入测试

```bash
# 使用默认测试文件
./test_batch.sh

# 指定自定义文本文件
./test_batch.sh -f /path/to/texts.txt
```

#### 可用性评估测试

运行内置的可用性评估测试，包含15个测试文本（5组，每组3个语义相似的文本）：

```bash
./test_eval.sh
```

测试内容：
- **组1 (水果/苹果)**: 苹果相关文本
- **组2 (汽车/交通)**: 交通工具相关文本
- **组3 (战争/和平)**: 战争和平相关文本
- **组4 (学习/教育)**: 教育相关文本
- **组5 (天气/自然)**: 天气相关文本

评估指标：
- 组内相似度：同组文本应具有较高相似度 (> 0.7)
- 组间区分度：不同语义组应具有较低相似度 (< 0.5)
- 语义相似组检测：相关话题组应有一定相似度 (> 0.3)

## 运行参数

### run.sh 参数

```bash
./run.sh [OPTIONS]

选项:
  -l, --llm MODEL       LLM模型路径
  -c, --context NUM     最大上下文长度 (默认: 4096)
  -n, --cores NUM       NPU核心数 (RK3588默认: 3)
  -h, --help            显示帮助信息
```

### 示例

```bash
# 使用默认设置
./run.sh

# 指定自定义模型
./run.sh -l ./models/custom_embedding.rkllm

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

## Embedding 模型说明

### 输出格式

模型输出一个归一化的浮点向量，维度通常为 1024：

- **向量维度**: 1024
- **归一化**: 输出向量已归一化（norm = 1.0）
- **池化方式**: 使用最后一个 token 的隐藏层

### 相似度计算

余弦相似度用于衡量两个文本向量之间的相似性：

```
similarity = dot(a, b) / (norm(a) * norm(b))
```

由于输出向量已归一化，余弦相似度简化为点积：

```
similarity = dot(a, b)
```

**相似度范围**: 0.0 ~ 1.0
- **接近 1.0**: 文本语义高度相似
- **接近 0.0**: 文本语义不相关

### 典型应用场景

1. **语义搜索**: 将查询和文档转换为向量进行相似度匹配
2. **文本聚类**: 对文本进行语义聚类分析
3. **RAG 系统**: 为检索增强生成系统提供文档嵌入
4. **推荐系统**: 基于文本相似度进行内容推荐

## 性能参考

### RK3588 性能数据

| 指标 | 数值 |
|------|------|
| 单次推理时间 | ~45ms |
| 批量处理速度 | ~22 texts/s |
| 向量维度 | 1024 |
| 内存占用 | ~500MB |

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
│     cd Qwen3-Embedding-rk3588                                │
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

## 输出示例

### 单次嵌入输出

```
========== Embedding Result ==========
Text: What is machine learning?
Dimension: 1024
Norm: 1.0000
First 10 values: 0.0234 -0.0156 0.0089 -0.0312 0.0456 -0.0223 0.0178 -0.0098 0.0345 -0.0267
Inference Time:    45.23 ms
======================================
```

### 相似度计算输出

```
========== Similarity Result ==========
Text 1: What is AI?
Text 2: Artificial Intelligence is a field of computer science.
Cosine Similarity: 0.8542
Total Inference Time:    90.46 ms
=======================================
```

### 批量处理输出

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                     Qwen3-Embedding Batch Processing Demo                    ║
╚══════════════════════════════════════════════════════════════════════════════╝

▶ Loading texts from: ./test/sentences.txt

▶ Processing 10 texts...

  ✓ Text[ 0] Dim: 1024 | Time:  45.23 ms
  ✓ Text[ 1] Dim: 1024 | Time:  44.87 ms
  ✓ Text[ 2] Dim: 1024 | Time:  45.12 ms
  ...

─────────────────────────────────────────── Performance Stats ───────────────────────────────────────────
  ⏱  Total time:     452.34 ms
  ⏱  Average time:    45.23 ms/text
  ⚡ Throughput:      22.11 texts/sec
───────────────────────────────────────────────────────────────────────────────────────────────────
```

## 常见问题

### Q: 提示 "LLM model not found"

模型文件未找到。请确保已将模型文件复制到 `models/` 目录：

```bash
ls models/
# 应显示：
# Qwen3-Embedding-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm
```

如果模型在其他位置，可以使用 `-l` 参数指定：

```bash
./run.sh -l /path/to/model.rkllm
```

### Q: 提示 "librkllmrt.so not found"

库路径未正确设置。请执行：

```bash
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
./run.sh
```

### Q: 内存不足错误

确保设备有足够的内存（建议 ≥1GB 可用内存）：

```bash
free -h
```

如果内存不足，可以：
1. 关闭其他占用内存的程序
2. 减少 `max_context_len` 参数

### Q: 推理速度慢

1. **执行提频**：
   ```bash
   bash /path/to/fix_freq_rk3588.sh
   ```

2. **检查 NPU 核心数**：确保使用正确的核心数（RK3588 为 3）
   ```bash
   ./run.sh -n 3
   ```

### Q: 如何保存嵌入向量到文件？

在交互模式中使用 `save` 命令：

```
user: save What is machine learning? embedding.bin
robot: Embedding saved to embedding.bin (dim=1024, time=45.23 ms)
```

### Q: 如何使用嵌入向量进行语义搜索？

1. 预先计算所有文档的嵌入向量并保存
2. 计算查询文本的嵌入向量
3. 计算查询向量与所有文档向量的余弦相似度
4. 返回相似度最高的文档

## 相关链接

- [rknn-llm](https://github.com/airockchip/rknn-llm)
- [rknn-toolkit2](https://github.com/airockchip/rknn-toolkit2)
- [Qwen3-Embedding](https://huggingface.co/Qwen)
