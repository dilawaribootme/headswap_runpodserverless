# Base image (keep yours – we'll override torch)
FROM runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04

# Declare bake args so they can be passed
ARG RELEASE
ARG CUDA_VERSION
ARG INDEX_URL
ARG TORCH_VERSION

ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /ComfyUI

# Clone ComfyUI
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git . \
    && rm -rf .git

# --- DEPENDENCY INSTALLATION START ---
COPY requirements_runpod.txt requirements_runpod.txt

# Upgrade pip
RUN pip install --upgrade pip --no-cache-dir

# CRITICAL: Install your target PyTorch (overrides base image's old 2.2.1)
RUN pip install --no-cache-dir --force-reinstall \
    torch==${TORCH_VERSION} \
    torchvision torchaudio \
    --index-url ${INDEX_URL}

# Install official ComfyUI requirements
RUN pip install --no-cache-dir -r requirements.txt

# Install your custom RunPod requirements
RUN pip install --no-cache-dir -r requirements_runpod.txt
# --- DEPENDENCY INSTALLATION END ---

# Install Custom Nodes
COPY setup.sh .
RUN sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh

# Copy files
COPY extra_model_paths.yaml .
COPY workflow_api.json .
COPY rp_handler.py .
COPY start.sh .
COPY model_setup.py .

# Permissions
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

ENTRYPOINT ["/ComfyUI/start.sh"]