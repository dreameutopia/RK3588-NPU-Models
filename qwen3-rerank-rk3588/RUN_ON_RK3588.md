# RK3588 板子运行指南

> **完整指南** 请查看 [README.md](README.md) 获取完整的项目说明和部署流程。

本文档介绍在 RK3588 开发板上编译和运行 Qwen3-Rerank 重排序模型的操作步骤。

## 核心步骤速览

| 步骤 | 命令 | 说明 |
|------|------|------|
| 1 | `./setup.sh -s ../rknn-llm` | 复制 RKLLM 运行时库 |
| 2 | `./build.sh` | 编译项目 |
| 3 | `export LD_LIBRARY_PATH=./lib` | 设置库路径 |
| 4 | `./run.sh` | 运行推理 |

## 详细步骤

### 1. 准备运行时库

复制 RKLLM 运行时库：

```bash
cd qwen3-rerank-rk3588
./setup.sh -s ../rknn-llm
```

或手动复制：

```bash
mkdir -p lib/aarch64
cp ../rknn-llm/rkllm-runtime/Linux/librkllm_api/aarch64/librkllmrt.so lib/aarch64/
```

### 2. 编译项目

```bash
chmod +x build.sh
./build.sh
```

编译完成后，可执行文件和脚本位于 `install/demo_Linux_aarch64/` 目录：

```bash
cd install/demo_Linux_aarch64
chmod +x run.sh test_single.sh test_batch.sh
```

### 3. 设置环境

```bash
export LD_LIBRARY_PATH=./lib
```

### 4. 运行推理

#### 交互模式

```bash
./run.sh
```

进入交互模式后输入命令：

```
rerank <query> | <document>  - 计算相关性分数
batch <query> | <file>       - 批量重排序
exit                         - 退出程序
```

示例：

```
user: rerank What is AI? | Artificial Intelligence is a field of computer science.
robot: Relevance Score: 0.8542 (Inference Time: 45.23 ms)
```

#### 单次查询测试

```bash
./test_single.sh
```

自定义参数：

```bash
./test_single.sh -q "What is Python?" -d "Python is a high-level programming language."
```

#### 批量重排序测试（推荐）

批量测试可以评估一个查询与多个文档的相关性，并按相关性排序显示结果：

```bash
./test_batch.sh
```

默认测试：查询"什么是机器学习？"，评估10个不同主题的文档

**自定义查询和文档文件：**

```bash
./test_batch.sh -q "Your query here" -f ./test/documents.txt
```

**测试内容说明：**

批量测试包含10个不同相关度的文档：
- **高相关**: 机器学习、深度学习、Python、NLP、RNN 等 AI/ML 相关内容
- **低相关**: 埃菲尔铁塔、天气、美国内战、金融市场 等无关内容
- **中相关**: CNN（计算机视觉）与机器学习有一定关联

预期结果：
- AI/ML 相关文档排在前面（分数 > 0.5）
- 无关文档排在后面（分数 < 0.5）

### 5. 运行参数

```bash
./run.sh [OPTIONS]

选项:
  -l, --llm MODEL       LLM模型路径
  -c, --context NUM     最大上下文长度 (默认: 4096)
  -n, --cores NUM       NPU核心数 (RK3588默认: 3)
  -h, --help            显示帮助信息
```

### 6. 性能优化（可选）

运行推理前执行提频脚本以获得最佳性能：

```bash
bash /path/to/rknn-llm/scripts/fix_freq_rk3588.sh
```

## 性能参考 (RK3588)

| 指标 | 数值 |
|------|------|
| 单次推理时间 | ~45ms |
| 批量处理速度 | ~22 docs/s |
| 内存占用 | ~500MB |

## 注意事项

1. **NPU核心数**: RK3588 有 3 个 NPU 核心，RK3576 有 2 个
2. **内存**: 确保设备有足够的内存（建议 ≥1GB 可用内存）
3. **模型文件**: 确保 `models/` 目录下有 RKLLM 模型文件
4. **环境变量**: 每次运行前需设置 `export LD_LIBRARY_PATH=./lib`

## 详细文档

完整的部署指南、环境准备和常见问题解答请查看：
- [README.md](README.md) - 完整项目说明和部署流程
