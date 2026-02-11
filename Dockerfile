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

# --- DEPENDENCY INSTALLATION START ---
# 1. Copy YOUR custom requirements (Make sure you renamed the file locally!)
COPY requirements_runpod.txt requirements_runpod.txt

# 2. Upgrade pip
RUN pip install --upgrade pip --no-cache-dir

# 3. Install OFFICIAL ComfyUI requirements FIRST
# (This fixes the missing frontend, torchsde, av, and aimdo errors)
RUN pip install --no-cache-dir -r requirements.txt

# 4. Install YOUR Custom RunPod requirements SECOND
# (This installs runpod, protobuf, and your specific versions)
RUN pip install --no-cache-dir -r requirements_runpod.txt
# --- DEPENDENCY INSTALLATION END ---

# Install Custom Nodes (using your verified setup.sh)
COPY setup.sh .
RUN sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh

# Copy Configuration and Scripts
COPY extra_model_paths.yaml .
COPY workflow_api.json .
COPY rp_handler.py .
COPY start.sh .
COPY model_setup.py .

# Fix permissions for the start script
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# Start the container

CMD ["./start.sh"]
