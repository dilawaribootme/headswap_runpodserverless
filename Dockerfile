# Base image (Updated to CUDA 12.4 to match PyTorch)
FROM runpod/pytorch:2.4.0-py3.10-cuda12.4.1-devel-ubuntu22.04

# ENV variables
ENV PYTHONUNBUFFERED=1

# ARG Defaults (For Build Safety)
ARG INDEX_URL=https://download.pytorch.org/whl/cu124
ARG TORCH_VERSION=2.6.0+cu124

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

# --- DEPENDENCY INSTALLATION ---
COPY requirements_runpod.txt requirements_runpod.txt

# Upgrade pip
RUN pip install --upgrade pip --no-cache-dir

# CRITICAL: Install Torch 2.6.0
RUN pip install --no-cache-dir --force-reinstall \
    torch==${TORCH_VERSION} \
    torchvision torchaudio \
    --index-url ${INDEX_URL}

# Install official ComfyUI requirements
RUN pip install --no-cache-dir -r requirements.txt

# Install your custom RunPod requirements
RUN pip install --no-cache-dir -r requirements_runpod.txt

# ---------------------------------------------------------
# EXTRA SAFETY: FORCE REINSTALL OPENCV
# This ensures that if any previous step installed a conflicting 
# version, we overwrite it with the correct one right at the end.
# ---------------------------------------------------------
RUN pip install --no-cache-dir --force-reinstall opencv-contrib-python==4.9.0.80

# --- CUSTOM SETUP ---
COPY setup.sh .
RUN sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh

# Copy Configuration and Scripts
COPY extra_model_paths.yaml .
COPY workflow_api.json .
COPY rp_handler.py .
COPY model_setup.py .
COPY start.sh .

# Fix permissions
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# Start
ENTRYPOINT ["/ComfyUI/start.sh"]