# Base image
FROM runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04

# ENV variables
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

# --- DEPENDENCY INSTALLATION ---
COPY requirements_runpod.txt requirements_runpod.txt

# Upgrade pip
RUN pip install --upgrade pip --no-cache-dir

# CRITICAL: Install Torch 2.6.0 (Hardcoded to prevent RunPod build errors)
RUN pip install --no-cache-dir --force-reinstall \
    torch==2.6.0+cu124 \
    torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu124

# Install official ComfyUI requirements
RUN pip install --no-cache-dir -r requirements.txt

# Install your custom RunPod requirements (This now has the fixed accelerate version)
RUN pip install --no-cache-dir -r requirements_runpod.txt

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