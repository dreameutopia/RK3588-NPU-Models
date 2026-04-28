#!/bin/bash

REPOS=(
    "https://github.com/airockchip/rknn-llm"
    "https://github.com/airockchip/rknn_model_zoo"
)

echo "=========================================="
echo "  RKNN Repositories Clone Script"
echo "=========================================="

for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo")
    echo ""
    echo "[INFO] Cloning $repo_name ..."
    
    if [ -d "$repo_name" ]; then
        echo "[WARN] $repo_name already exists, skipping..."
    else
        git clone "$repo"
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] $repo_name cloned successfully!"
        else
            echo "[ERROR] Failed to clone $repo_name"
        fi
    fi
done

echo ""
echo "=========================================="
echo "  Clone completed!"
echo "=========================================="
echo ""
echo "Cloned repositories:"
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo")
    if [ -d "$repo_name" ]; then
        echo "  - $repo_name"
    fi
done
