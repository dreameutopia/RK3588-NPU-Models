# Conda 环境一键配置脚本使用说明

## 脚本说明

本脚本用于快速配置 RKNN 开发所需的 Conda 环境，包括：
- 自动安装 Miniconda（如未安装）
- 初始化 Conda 支持（bash 和 zsh）
- 创建指定的 Python 环境

## 使用方法

### 1. 赋予执行权限

```bash
chmod +x setup_conda_env.sh
```

### 2. 执行脚本

```bash
./setup_conda_env.sh
```

### 3. 激活环境

脚本执行完成后，需要激活环境：

**对于 bash 用户：**
```bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate rknn3
```

**对于 zsh 用户：**
```bash
source ~/.zshrc
conda activate rknn3
```

## 自定义配置

脚本支持通过环境变量自定义配置：

```bash
# 自定义 Miniconda 安装目录
export MINICONDA_DIR=/path/to/miniconda

# 自定义环境名称
export ENV_NAME=my_env

# 自定义 Python 版本
export PYTHON_VERSION=3.11

# 执行脚本
./setup_conda_env.sh
```

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| MINICONDA_DIR | $HOME/miniconda3 | Miniconda 安装目录 |
| ENV_NAME | rknn3 | Conda 环境名称 |
| PYTHON_VERSION | 3.10 | Python 版本 |

## 执行结果

脚本执行完成后，将创建以下环境：

```
~/miniconda3/
├── bin/               # Conda 可执行文件
├── envs/
│   └── rknn3/        # RKNN 开发环境 (Python 3.10)
└── ...
```

## 注意事项

1. 确保已安装 `wget` 命令用于下载 Miniconda 安装包
2. 确保网络可以正常访问 Anaconda 仓库
3. 如果 Miniconda 已安装，脚本会自动跳过安装步骤
4. 如果环境已存在，脚本会自动跳过创建步骤
5. 首次使用需要重新加载 shell 配置或重启终端
