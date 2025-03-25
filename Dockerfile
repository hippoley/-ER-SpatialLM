FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# 设置非交互式模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装基本依赖
RUN apt-get update && apt-get install -y \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# 安装Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# 将conda添加到PATH
ENV PATH=/opt/conda/bin:$PATH

# 创建conda环境
RUN conda create -n spatiallm python=3.11 -y && \
    conda init bash && \
    echo "conda activate spatiallm" >> ~/.bashrc

SHELL ["/bin/bash", "--login", "-c"]

# 激活环境并安装依赖
RUN conda activate spatiallm && \
    conda install -y -c nvidia/label/cuda-12.4.0 cuda-toolkit && \
    conda install -y -c conda-forge sparsehash && \
    pip install poetry && \
    poetry config virtualenvs.create false --local

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . /app/

# 安装项目依赖
RUN conda activate spatiallm && \
    poetry install && \
    poe install-torchsparse

# 设置环境变量
ENV PYTHONPATH=/app:$PYTHONPATH

# 设置默认的conda环境
ENV CONDA_DEFAULT_ENV=spatiallm

# 设置容器启动命令
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "spatiallm"]
CMD ["/bin/bash"] 