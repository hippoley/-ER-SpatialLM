FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

# Set non-interactive mode and environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
# Set longer timeout for conda
ENV CONDA_TIMEOUT=600

# Install basic dependencies and build tools
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

# Update certificates and configure wget
RUN update-ca-certificates && \
    echo "check_certificate = off" >> ~/.wgetrc

# Install Miniconda with enhanced retry mechanism
RUN set -x && \
    MINICONDA_FILE="Miniconda3-latest-Linux-x86_64.sh" && \
    MINICONDA_DEST="/root/${MINICONDA_FILE}" && \
    MAX_TRIES=5 && \
    ATTEMPT=1 && \
    while [ $ATTEMPT -le $MAX_TRIES ]; do \
        echo "Download attempt $ATTEMPT of $MAX_TRIES" && \
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
            echo "Successfully downloaded Miniconda" && \
            break; \
        else \
            echo "All mirrors failed on attempt $ATTEMPT" && \
            ATTEMPT=$((ATTEMPT + 1)) && \
            if [ $ATTEMPT -le $MAX_TRIES ]; then \
                echo "Waiting before retry..." && \
                sleep 30; \
            fi \
        fi \
    done && \
    if [ ! -f "${MINICONDA_DEST}" ]; then \
        echo "Failed to download Miniconda after $MAX_TRIES attempts" && \
        exit 1; \
    fi && \
    chmod +x "${MINICONDA_DEST}" && \
    bash "${MINICONDA_DEST}" -b -p /opt/conda && \
    rm "${MINICONDA_DEST}"

# Add conda to PATH
ENV PATH=/opt/conda/bin:${PATH}

# Configure multiple conda channels with fallback
RUN conda config --set remote_read_timeout_secs 600 && \
    # Primary mirrors
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/ && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ && \
    # Backup mirrors
    conda config --append channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/ && \
    conda config --append channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/ && \
    # Additional backup
    conda config --append channels https://mirrors.bfsu.edu.cn/anaconda/pkgs/main/ && \
    conda config --append channels https://mirrors.bfsu.edu.cn/anaconda/pkgs/free/ && \
    # Original source as last resort
    conda config --append channels defaults && \
    # Show channel URLs for debugging
    conda config --set show_channel_urls yes && \
    # Create .condarc for channel priority
    echo "channel_priority: flexible" >> ~/.condarc && \
    # Add retry attempts
    echo "remote_max_retries: 5" >> ~/.condarc && \
    # Add connect timeout
    echo "remote_connect_timeout_secs: 30" >> ~/.condarc && \
    # SSL verification settings
    echo "ssl_verify: false" >> ~/.condarc

# Create conda environment with retry mechanism
RUN for i in {1..3}; do \
    conda create -n spatiallm python=3.11 -y && break || \
    echo "Attempt $i failed! Retrying..." && \
    sleep 10; \
    done && \
    conda init bash && \
    echo "conda activate spatiallm" >> ~/.bashrc

SHELL ["/bin/bash", "--login", "-c"]

# Activate environment and install dependencies with retry mechanism
RUN for i in {1..3}; do \
    conda activate spatiallm && \
    # Install CUDA toolkit
    conda install -y -c nvidia/label/cuda-12.4.0 cuda-toolkit && \
    conda install -y -c conda-forge sparsehash && \
    # Install specific version of PyTorch
    conda install pytorch=2.4.1 torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia && \
    # Install poetry
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple poetry && \
    poetry config virtualenvs.create false --local && \
    # Install rerun visualization tool
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple rerun-sdk && \
    break || \
    echo "Attempt $i failed! Retrying..." && \
    sleep 10; \
    done

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app/

# Create data directory
RUN mkdir -p /app/data

# Install project dependencies with retry mechanism
RUN for i in {1..3}; do \
    conda activate spatiallm && \
    poetry install && \
    poe install-torchsparse && \
    break || \
    echo "Attempt $i failed! Retrying..." && \
    sleep 10; \
    done

# Set environment variables
ENV PYTHONPATH=/app:${PYTHONPATH}
ENV CONDA_DEFAULT_ENV=spatiallm

# Add health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD conda run -n spatiallm python -c "import torch; print(torch.cuda.is_available())" || exit 1

# Set container startup command
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "spatiallm"]
CMD ["/bin/bash"] 