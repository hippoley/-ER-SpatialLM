# SpatialLM Docker 部署指南

<!-- markdownlint-disable first-line-h1 -->
<!-- markdownlint-disable html -->
<!-- markdownlint-disable no-duplicate-header -->

<div align="center">
  <img src="figures/logo_light.png#gh-light-mode-only" width="60%" alt="SpatialLM" />
  <img src="figures/logo_dark.png#gh-dark-mode-only" width="60%" alt="SpatialLM" />
</div>

## 环境要求

已在以下环境测试通过：

- NVIDIA GPU with CUDA 12.4 support
- Docker 24.0 or later
- NVIDIA Container Toolkit
- 20GB+ 可用磁盘空间

## Docker 部署方式

### 方式一：使用预构建镜像（推荐）

1. 在源机器上导出镜像：
```bash
# 查看镜像 ID
docker images

# 保存镜像（替换 <image_id> 为实际的镜像 ID）
docker save -o spatiallm_image.tar <image_id>
```

2. 将镜像文件传输到目标机器：
   - 使用外部存储设备
   - 使用网络传输（scp, rsync 等）
   - 使用云存储服务

3. 在目标机器上加载镜像：
```bash
docker load -i spatiallm_image.tar
```

### 方式二：从源代码构建

1. 克隆代码仓库：
```bash
git clone https://github.com/manycore-research/SpatialLM.git
cd -ER-SpatialLM
```

2. 构建 Docker 镜像：
```bash
docker-compose build --no-cache
```

3. 启动容器：
```bash
docker-compose up -d
```

## 数据迁移

### 模型文件
模型文件位置：
- Windows: `C:\Users\用户名\.cache\huggingface\hub`
- Linux: `~/.cache/huggingface/hub`

需要迁移的模型：
- `manycore-research/SpatialLM-Llama-1B`
- `manycore-research/SpatialLM-Qwen-0.5B`

### 数据集
确保以下目录结构：
```
-ER-SpatialLM/
  ├── data/          # 数据集目录
  │   └── pcd/       # 点云文件
  └── models/        # 模型文件（可选）
```

## 运行推理

1. 进入容器：
```bash
docker-compose exec spatiallm bash
```

2. 激活环境：
```bash
conda activate spatiallm
```

3. 运行推理：
```bash
python inference.py --point_cloud pcd/scene0000_00.ply --output scene0000_00.txt --model_path manycore-research/SpatialLM-Llama-1B
```

## 常见问题

### 1. CUDA 相关问题

检查 GPU 驱动：
```bash
nvidia-smi
```

检查容器内 CUDA：
```bash
docker run --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

### 2. 权限问题

确保用户在 docker 组中：
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. 网络问题

检查 Docker 网络：
```bash
docker network ls
docker network inspect bridge
```

## 注意事项

1. 确保目标机器的 GPU 驱动版本支持 CUDA 12.4
2. 检查磁盘空间是否充足（至少 20GB）
3. 确保网络连接稳定，特别是在拉取大型模型文件时
4. 建议使用版本控制来管理代码和配置文件
5. 定期备份重要的模型文件和数据集

## 许可证

本项目遵循与 SpatialLM 相同的许可证条款：
- SpatialLM-Llama-1B: Llama3.2 license
- SpatialLM-Qwen-0.5B: Apache 2.0 License
- SceneScript point cloud encoder: CC-BY-NC-4.0 License
- TorchSparse: MIT License

## 致谢

感谢以下项目的支持：

[Llama3.2](https://github.com/meta-llama) | [Qwen2.5](https://github.com/QwenLM/Qwen2.5) | [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit) | [Docker](https://www.docker.com/) 