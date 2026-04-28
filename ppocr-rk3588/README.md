# PPOCR RK3588 部署包

PaddleOCR (PPOCRv4) 在 RK3588 平台的完整部署方案。

## 目录结构

```
ppocr-rk3588/
├── build.sh              # 编译脚本
├── prepare_models.sh     # 模型准备脚本
├── clean.sh              # 清理临时文件
├── src/                  # 源代码
├── scripts/              # 测试脚本
│   ├── test_single.sh    # 单图测试
│   └── test_multi.sh     # 多图并发测试
├── 3rdparty/             # 依赖库
├── model/                # RKNN模型
│   ├── ppocrv4_det_serverial.rknn
│   └── ppocrv4_rec_serverial.rknn
├── install/              # 编译输出
│   ├── ppocr_demo        # 可执行文件
│   ├── lib/              # 运行时库
│   └── run.sh            # 运行脚本
├── onnx/                 # ONNX模型 (可清理)
└── test/                 # 测试图片
    ├── test1.png
    ├── test2.png
    └── test3.png
```

## 快速开始

### 步骤 1: 安装 rknn-toolkit2 环境

```bash
conda create -n rknn3 python=3.10 -y
conda activate rknn3
pip install rknn-toolkit2 setuptools==69.0.0 onnx==1.15.0 onnxruntime==1.16.3 opencv-python-headless numpy==1.26.4
python -c "from rknn.api import RKNN; print('OK')"
```

### 步骤 2: 准备模型

```bash
conda activate rknn3
./prepare_models.sh
```

### 步骤 3: 准备运行时库

```bash
./setup.sh  ../rknn-llm
```

### 步骤 4: 编译

```bash
./build.sh
```

### 步骤 5: 测试

```bash
# 单图测试
./scripts/test_single.sh -i test/test1.png

# 多图并发测试
./scripts/test_multi.sh
```

### 步骤 6: 清理临时文件

```bash
./clean.sh
```

## 运行参数

```bash
# 使用脚本
./scripts/test_single.sh -i test/test1.png -o result.jpg

# 或直接运行
cd install
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
./ppocr_demo -d ../model/ppocrv4_det_serverial.rknn \
             -r ../model/ppocrv4_rec_serverial.rknn \
             -i ../test/test1.png \
             -o result.jpg
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-d` | 检测模型路径 | model/ppocrv4_det_serverial.rknn |
| `-r` | 识别模型路径 | model/ppocrv4_rec_serverial.rknn |
| `-i` | 输入图片路径 | (必需) |
| `-o` | 输出标注图片路径 | (可选) |
| `-t` | 检测像素阈值 | 0.3 |
| `-b` | 检测框阈值 | 0.5 |

## RK3588 平台说明

详细部署指南请参考 [RUN_ON_RK3588.md](RUN_ON_RK3588.md)。

RK3588 是 Rockchip 的高性能 AI 处理器：
- 6 TOPS NPU 算力
- 支持 INT8/FP16 混合运算
- 三核 NPU 架构

> 💡 **提示**：PPOCR 支持 INT8 和 FP16 量化，可根据精度和性能需求选择。

## 常见问题

### Q: prepare_models.sh 报错 "No module named 'pkg_resources'"

```bash
pip install setuptools==69.0.0
```

### Q: prepare_models.sh 报错 "module 'onnx' has no attribute 'mapping'"

```bash
pip install onnx==1.15.0
```

### Q: prepare_models.sh 报错 "libGL.so.1: cannot open shared object file"

```bash
pip install opencv-python-headless
```

### Q: 运行时找不到 librknnrt.so

确保已正确运行 `./setup.sh` 并设置了 `LD_LIBRARY_PATH`:
```bash
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
```

## 参考资料

- [RKNN Model Zoo - PPOCR](https://github.com/airockchip/rknn_model_zoo/tree/main/examples/PPOCR)
- [RKNN Toolkit2](https://github.com/airockchip/rknn-toolkit2)
- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR)
