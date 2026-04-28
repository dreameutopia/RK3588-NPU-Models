# Qwen3-Rerank RK3588 部署包

本项目提供 Qwen3-Rerank 重排序模型在 RK3588 平台上的完整部署方案。

> **重要说明**: 本文档所有路径均为相对路径，执行任何命令前请确保已进入本项目根目录：
> ```bash
> cd qwen3-rerank-rk3588
> ```

## 目录结构

```
qwen3-rerank-rk3588/
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
│   └── Qwen3-Reranker-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm  # 模型文件 (需复制)
└── test/
    └── documents.txt        # 测试文档
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
cp /path/to/Qwen3-Reranker-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm models/
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
********************** Qwen3-Rerank Interactive Mode ********************
Commands:
  rerank <query> | <document>  - Compute relevance score
  batch <query> | <file>       - Batch rerank documents from file
  exit                         - Exit program
*************************************************************************

user: rerank What is AI? | Artificial Intelligence is a field of computer science.
robot: Relevance Score: 0.8542 (Inference Time: 45.23 ms)
```

### 方法二：单次查询测试

```bash
cd install/demo_Linux_aarch64
export LD_LIBRARY_PATH=./lib
./test_single.sh
```

或自定义查询和文档：

```bash
./test_single.sh -q "What is Python?" -d "Python is a high-level programming language."
```

### 方法三：批量重排序测试

```bash
cd install/demo_Linux_aarch64
export LD_LIBRARY_PATH=./lib
./test_batch.sh
```

或指定查询和文档文件：

```bash
./test_batch.sh -q "What is machine learning?" -f ./test/documents.txt
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
  ./run.sh -l ./models/custom_rerank.rkllm    # 指定模型路径
```

## 重排序模型说明

Qwen3-Rerank 是一个文本重排序模型，用于评估查询和文档之间的相关性。模型输出一个 0-1 之间的相关性分数：

- **分数接近 1**: 文档与查询高度相关
- **分数接近 0**: 文档与查询不相关

### 典型应用场景

1. **搜索结果重排序**: 对搜索引擎返回的结果进行二次排序
2. **RAG 系统优化**: 对检索到的文档进行相关性排序
3. **问答系统**: 选择与问题最相关的上下文

### Prompt 格式

模型使用以下格式的 prompt 进行推理：

```
<Instruct>: Given a query, determine whether the document is relevant to the query.
<Query>: [查询文本]
<Document>: [文档文本]
<Answer>: 
```

### 分数计算原理

模型使用 `RKLLM_INFER_GET_LOGITS` 模式获取最后一个 token 的 logits，然后提取特定 token ID 的 logits 计算 softmax 概率：

- `true_token_id = 151945` (表示相关)
- `false_token_id = 151946` (表示不相关)

最终分数 = softmax(true_logit, false_logit)[0]

## 性能参考 (RK3588)

| 指标 | 数值 |
|------|------|
| 单次推理时间 | ~45ms |
| 批量处理速度 | ~22 docs/s |
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
cd qwen3-rerank-rk3588

# 设置运行时库
./setup.sh -s ../rknn-llm

# 复制模型文件
cp /path/to/Qwen3-Reranker-0.6B-rk3588-w8a8_g256-opt-1-hybrid-ratio-0.0.rkllm models/
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

**导出Rerank模型：**
```bash
cd ../rknn-llm/examples/llm
python export_rkllm.py --model_path /path/to/Qwen3-Reranker \
                       --target_platform rk3588 \
                       --num_npu_core 3 \
                       --quantized_dtype w8a8
```

## 相关链接

- [rknn-llm](https://github.com/airockchip/rknn-llm)
- [rknn-toolkit2](https://github.com/airockchip/rknn-toolkit2)
- [Qwen3-Rerank](https://huggingface.co/Qwen)
