# Base image
FROM runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04

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

# Dependencies
COPY requirements.txt requirements_custom.txt

RUN sed -i '/torch/d' requirements.txt && \
    sed -i '/opencv/d' requirements.txt && \
    pip install --upgrade pip --no-cache-dir && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r requirements_custom.txt

# Install Custom Nodes
COPY setup.sh .
RUN sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh

# Copy Configuration and Scripts
COPY extra_model_paths.yaml .
COPY workflow_api.json .
COPY rp_handler.py .
COPY start.sh .
COPY model_setup.py .  

# Fix permissions
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

CMD ["./start.sh"]