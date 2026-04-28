# RKNN 仓库一键克隆脚本使用说明

## 脚本说明

本脚本用于快速克隆以下两个 RKNN 相关仓库：
- rknn-llm
- rknn_model_zoo

## 使用方法

### 1. 赋予执行权限

```bash
chmod +x clone_repos.sh
```

### 2. 执行脚本

```bash
./clone_repos.sh
```

## 执行结果

脚本执行完成后，将在当前目录下生成以下文件夹：

```
./
├── rknn-llm/          # RKNN LLM 仓库
├── rknn_model_zoo/    # RKNN Model Zoo 仓库
└── clone_repos.sh     # 本脚本
```

## 注意事项

1. 确保已安装 `git` 命令
2. 确保网络可以正常访问 GitHub
3. 如果目标文件夹已存在，脚本会自动跳过克隆
