# RK3588 板子运行指南

本文档介绍如何在 RK3588 开发板上部署和运行 PPOCR 文字识别。

## RK3588 平台说明

RK3588 是 Rockchip 的高性能 AI 处理器，具有以下特点：
- 6 TOPS NPU 算力
- 支持 INT8/FP16 混合运算
- 三核 NPU 架构

### 模型量化选项

对于 RK3588 平台，PPOCR 模型支持以下量化选项：

**检测模型 (ppocrv4_det)**:
- `i8`: INT8 量化（推荐，精度更高）
- `fp`: FP16 无量化

**识别模型 (ppocrv4_rec)**:
- `fp`: FP16 无量化（推荐，识别精度更高）

### 性能优化建议

1. 使用 INT8 量化的检测模型可以获得更好的性能
2. 识别模型建议使用 FP16 以保证 OCR 精度
3. 可以通过调整检测阈值来平衡精度和速度

## 前提条件

- RKNN 模型文件已准备就绪（位于 `model/` 目录）
- RKNN 运行时库已准备（`3rdparty/` 或 `install/lib/` 目录）

## 在 RK3588 上编译

Rock 5T (RK3588) 可以直接编译本项目，无需交叉编译：

### 1.1 进入项目目录

```bash
cd /www/wwwroot/rk-3588/ppocr-rk3588
```

> 💡 **注意**：路径根据实际部署位置调整。

### 1.2 编译项目

```bash
chmod +x ./build.sh
./build.sh
```

编译输出：

```
==========================================
Building PPOCR Demo for RK3588
==========================================
Native compilation mode
...
[100%] Built target ppocr_demo
Install the project...
-- Installing: /www/wwwroot/rk-3588/ppocr-rk3588/install/./ppocr_demo
-- Installing: /www/wwwroot/rk-3588/ppocr-rk3588/install/lib/librknnrt.so
==========================================
Build completed successfully!
Output: install/
==========================================
```

编译完成后，可执行文件和依赖库位于 `install/` 目录：

```
install/
├── ppocr_demo      # 可执行文件
├── lib/
│   └── librknnrt.so   # RKNN 运行时库
└── run.sh          # 运行脚本
```

## 完整部署流程

```
┌─────────────────────────────────────────────────────────────┐
│                      RK3588 开发板                           │
│                                                              │
│  1. 进入项目目录: cd /www/wwwroot/rk-3588/ppocr-rk3588      │
│  2. 编译: ./build.sh                                         │
│  3. 运行: cd install && ./ppocr_demo -d ../model/...         │
└─────────────────────────────────────────────────────────────┘
```

> 💡 **提示**：如果模型文件在 PC 端准备，可使用 scp 复制到开发板：

```bash
# 从 PC 复制模型到 RK3588
scp -r model/ root@<RK3588_IP>:/www/wwwroot/rk-3588/ppocr-rk3588/
scp -r test/ root@<RK3588_IP>:/www/wwwroot/rk-3588/ppocr-rk3588/
```

## 在 RK3588 上运行

### 2.1 进入安装目录

```bash
cd /www/wwwroot/rk-3588/ppocr-rk3588/install
```

### 2.2 设置环境变量

```bash
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
```

### 2.3 运行 OCR 识别

```bash
# 单图测试（使用相对路径）
./ppocr_demo \
    -d ../model/ppocrv4_det_serverial.rknn \
    -r ../model/ppocrv4_rec_serverial.rknn \
    -i ../test/test1.png \
    -o result.jpg

# 或回到项目根目录使用脚本测试
cd /www/wwwroot/rk-3588/ppocr-rk3588
./scripts/test_single.sh -i test/test1.png
```

### 2.4 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-d` | 检测模型路径 | model/ppocrv4_det_serverial.rknn |
| `-r` | 识别模型路径 | model/ppocrv4_rec_serverial.rknn |
| `-i` | 输入图片路径 | (必需) |
| `-o` | 输出标注图片路径 | (可选) |
| `-t` | 检测像素阈值 | 0.3 |
| `-b` | 检测框阈值 | 0.5 |

### 2.5 输出文件位置

运行成功后：
- 如果指定了 `-o` 参数，标注图片保存在指定路径
- 如果未指定，程序会显示识别结果（文本内容和位置）

## 常见问题

### Q: 运行时找不到 librknnrt.so

确保已正确设置 `LD_LIBRARY_PATH`:

```bash
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
```

如果库文件不在 `install/lib/` 目录下，请检查 `3rdparty/librknnrt/` 目录。

### Q: 编译报错 "CMake error"

确保 RK3588 上已安装必要的编译工具:

```bash
apt update && apt install -y cmake gcc g++ make
```

### Q: OCR 识别结果不准确

1. 检查输入图片质量，确保文字清晰
2. 调整检测阈值 `-t`（默认 0.3，降低可检测更多区域）
3. 调整检测框阈值 `-b`（默认 0.5，降低可保留更多检测框）
4. 确保使用了正确的 RKNN 模型文件

### Q: 模型文件放在哪里？

RKNN 模型文件应放在 `model/` 目录，运行时通过 `-d` 和 `-r` 参数指定：

```bash
# 模型默认位置
model/ppocrv4_det_serverial.rknn   # 检测模型
model/ppocrv4_rec_serverial.rknn   # 识别模型
```

### Q: 如何处理中文识别？

PPOCRv4 支持中文识别，请使用中文优化的模型版本。具体请参考 [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) 的中文模型导出说明。
