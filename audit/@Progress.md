# SpatialLM项目进度日志

<2025年3月21日 10:45>

## 实现的功能
- 尝试搭建SpatialLM项目环境
- 安装了poetry包管理工具
- 配置了poetry不创建虚拟环境(virtualenvs.create false)

## 遇到的错误
1. **网络连接问题**：使用poetry安装依赖时出现多次连接超时错误，无法从PyPI下载依赖包如sympy。
2. **HuggingFace连接问题**：尝试从HuggingFace下载测试数据集也遇到了连接超时。
3. **缺少基本依赖**：直接运行inference.py时发现缺少torch等基本依赖。
4. **PowerShell命令语法**：带有前缀连字符的目录名(-ER-SpatialLM)在PowerShell中被误认为是命令参数。

## 解决方法
1. **Poetry配置**：使用`poetry config virtualenvs.create false --local`成功配置了poetry不创建虚拟环境。
2. **PowerShell路径处理**：对于带连字符的目录，使用引号包裹并添加相对路径前缀，如：`cd "./-ER-SpatialLM"`。
3. **网络问题**：网络连接问题尚待解决，可能需要设置代理或使用镜像源。

## 流程梳理
1. **项目分析**：通过README.md了解项目是一个3D大型语言模型，用于处理3D点云数据。
2. **环境准备**：按照文档使用poetry管理依赖，但遇到网络问题。
3. **数据获取**：尝试从HuggingFace下载示例点云数据进行测试，但连接失败。
4. **运行尝试**：尝试直接运行inference.py查看需求，但缺少依赖。

## 下一步计划
1. 解决网络连接问题，尝试使用国内镜像源或设置代理。
2. 完成依赖安装，特别是PyTorch、transformers等核心组件。
3. 获取测试数据，尝试运行模型进行推理。
4. 验证可视化功能是否正常工作。

</2025年3月21日 10:45>

<2025年3月25日 01:45>

## 实现的功能
1. **Docker环境配置**
   - 创建了基于CUDA 12.4的Docker环境
   - 配置了conda环境管理
   - 设置了poetry依赖管理
   - 添加了GPU支持

2. **项目文件组织**
   - 创建了Dockerfile
   - 创建了docker-compose.yml
   - 创建了.dockerignore

## 遇到的错误
1. **环境配置错误**：
   - 最初使用系统Python而不是conda环境
   - torchsparse安装方式与README不符
   - 缺少必要的CUDA配置

2. **Windows兼容性问题**：
   - torchsparse在Windows上无法直接安装
   - 需要通过Docker解决跨平台兼容性问题

## 解决方法
1. **Docker环境优化**：
   - 使用nvidia/cuda:12.4.0-devel-ubuntu22.04基础镜像
   - 通过conda管理Python环境和CUDA工具包
   - 使用poetry管理项目依赖
   - 按README使用poe install-torchsparse安装torchsparse

2. **容器配置优化**：
   - 添加GPU支持配置
   - 设置数据持久化
   - 配置工作目录挂载

## 流程梳理
1. **需求分析**
   ```
   Windows环境 -> torchsparse不支持 -> 需要Linux环境
   解决方案：使用Docker容器化
   ```

2. **环境配置流程**
   ```
   基础镜像选择
   ↓
   conda环境配置
   ↓
   CUDA工具安装
   ↓
   Poetry依赖管理
   ↓
   torchsparse安装
   ```

3. **Docker配置优化**
   ```
   创建Dockerfile
   ↓
   添加docker-compose.yml
   ↓
   配置.dockerignore
   ↓
   优化构建过程
   ```

## 当前文件变更
```bash
git status
Changes to be committed:
  new file:   Dockerfile
  new file:   docker-compose.yml
  new file:   .dockerignore
  modified:   audit/@Progress.md
```

## 下一步计划
1. 测试Docker环境构建
2. 验证GPU支持是否正常
3. 运行示例推理测试
4. 完善数据集管理和持久化存储

</2025年3月25日 01:45> 