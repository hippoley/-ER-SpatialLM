# 使用 NVIDIA CUDA 12.4 基础镜像
FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
# 设置较长的 conda 超时时间
ENV CONDA_TIMEOUT=600
# 设置 pip 超时时间
ENV PIP_TIMEOUT=600

# 安装基本依赖和构建工具
RUN apt-get update && apt-get install -y \
    wget \
    git \
    build-essential \
    ninja-build \
    cmake \
    libsparsehash-dev \
    ca-certificates \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 更新证书并配置 wget
RUN update-ca-certificates && \
    echo "check_certificate = off" >> ~/.wgetrc

# 安装 Miniconda（带重试机制）
RUN set -x && \
    MINICONDA_FILE="Miniconda3-latest-Linux-x86_64.sh" && \
    MINICONDA_DEST="/root/${MINICONDA_FILE}" && \
    MAX_TRIES=5 && \
    ATTEMPT=1 && \
    while [ $ATTEMPT -le $MAX_TRIES ]; do \
        echo "下载尝试 $ATTEMPT / $MAX_TRIES" && \
        if curl -sL --connect-timeout 30 --retry 5 --retry-delay 10 \
                --retry-max-time 300 -o "${MINICONDA_DEST}" \
                "https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/${MINICONDA_FILE}" || \
           curl -sL --connect-timeout 30 --retry 5 --retry-delay 10 \
                --retry-max-time 300 -o "${MINICONDA_DEST}" \
                "https://mirrors.bfsu.edu.cn/anaconda/miniconda/${MINICONDA_FILE}" || \
           curl -sL --connect-timeout 30 --retry 5 --retry-delay 10 \
                --retry-max-time 300 -o "${MINICONDA_DEST}" \
                "https://mirrors.ustc.edu.cn/anaconda/miniconda/${MINICONDA_FILE}" || \
           curl -sL --connect-timeout 30 --retry 5 --retry-delay 10 \
                --retry-max-time 300 -o "${MINICONDA_DEST}" \
                "https://repo.anaconda.com/miniconda/${MINICONDA_FILE}"; then \
            echo "Miniconda 下载成功" && \
            break; \
        else \
            echo "所有镜像下载失败，尝试 $ATTEMPT" && \
            ATTEMPT=$((ATTEMPT + 1)) && \
            if [ $ATTEMPT -le $MAX_TRIES ]; then \
                echo "等待重试..." && \
                sleep 30; \
            fi \
        fi \
    done && \
    if [ ! -f "${MINICONDA_DEST}" ]; then \
        echo "在 $MAX_TRIES 次尝试后下载 Miniconda 失败" && \
        exit 1; \
    fi && \
    chmod +x "${MINICONDA_DEST}" && \
    bash "${MINICONDA_DEST}" -b -p /opt/conda && \
    rm "${MINICONDA_DEST}"

# 将 conda 添加到 PATH
ENV PATH=/opt/conda/bin:${PATH}

# 配置 conda 镜像源（带备用源）
RUN conda config --set remote_read_timeout_secs 600 && \
    # 主要镜像源
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/ && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ && \
    # 备用镜像源
    conda config --append channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/ && \
    conda config --append channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/ && \
    # 额外备用源
    conda config --append channels https://mirrors.bfsu.edu.cn/anaconda/pkgs/main/ && \
    conda config --append channels https://mirrors.bfsu.edu.cn/anaconda/pkgs/free/ && \
    # 原始源作为最后选择
    conda config --append channels defaults && \
    # 显示通道 URL 以便调试
    conda config --set show_channel_urls yes && \
    # 创建 .condarc 配置
    echo "channel_priority: flexible" >> ~/.condarc && \
    echo "remote_max_retries: 5" >> ~/.condarc && \
    echo "remote_connect_timeout_secs: 30" >> ~/.condarc && \
    echo "ssl_verify: false" >> ~/.condarc

# 创建 conda 环境（带重试机制）
RUN for i in {1..3}; do \
    conda create -n spatiallm python=3.11 -y && break || \
    echo "尝试 $i 失败！重试中..." && \
    sleep 10; \
    done && \
    conda init bash && \
    echo "conda activate spatiallm" >> ~/.bashrc

SHELL ["/bin/bash", "--login", "-c"]

# 激活环境并安装基础依赖（带重试机制）
RUN --mount=type=cache,target=/root/.cache/pip \
    for i in {1..3}; do \
    source /opt/conda/etc/profile.d/conda.sh && \
    conda activate spatiallm && \
    # 安装 CUDA 工具包
    conda install -y -c nvidia/label/cuda-12.4.0 cuda-toolkit && \
    conda install -y -c conda-forge sparsehash && \
    # 安装指定版本的 PyTorch
    conda install pytorch=2.1.1 torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia && \
    # 安装 poetry
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple poetry && \
    poetry config virtualenvs.create false --local && \
    # 安装可视化工具
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple rerun-sdk && \
    break || \
    echo "尝试 $i 失败！重试中..." && \
    sleep 10; \
    done

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . /app/

# 创建数据目录
RUN mkdir -p /app/data

# 安装项目依赖（带重试机制）
RUN --mount=type=cache,target=/root/.cache/pip \
    for i in {1..3}; do \
    source /opt/conda/etc/profile.d/conda.sh && \
    conda activate spatiallm && \
    poetry install && \
    break || \
    echo "尝试 $i 失败！重试中..." && \
    sleep 10; \
    done

# 单独安装 torchsparse（带重试机制）
RUN --mount=type=cache,target=/root/.cache/pip \
    for i in {1..3}; do \
    source /opt/conda/etc/profile.d/conda.sh && \
    conda activate spatiallm && \
    poe install-torchsparse && \
    break || \
    echo "尝试 $i 失败！重试中..." && \
    sleep 10; \
    done

# 设置环境变量
ENV PYTHONPATH=/app:${PYTHONPATH}
ENV CONDA_DEFAULT_ENV=spatiallm

# 添加健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD source /opt/conda/etc/profile.d/conda.sh && conda activate spatiallm && python -c "import torch; print(torch.cuda.is_available())" || exit 1

# 设置容器启动命令
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["source /opt/conda/etc/profile.d/conda.sh && conda activate spatiallm && /bin/bash"] 