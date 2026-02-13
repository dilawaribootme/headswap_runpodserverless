# ==============================================================
# 1. BASE IMAGE: Verified stable version (CUDA 12.1)
# ==============================================================

FROM runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04

# Prevent Python buffering
ENV PYTHONUNBUFFERED=1

# ==============================================================
# 2. SYSTEM DEPENDENCIES
# ==============================================================

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================
# 3. WORKDIR
# ==============================================================

WORKDIR /ComfyUI

# ==============================================================
# 4. CLONE COMFYUI
# ==============================================================

RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git . \
    && rm -rf .git

# ==============================================================
# 5. COPY REQUIREMENTS
# ==============================================================

COPY requirements_runpod.txt requirements_runpod.txt

# Upgrade pip first
RUN pip install --upgrade pip --no-cache-dir

# ==============================================================
# 6. PYTORCH + CUDA ALIGNMENT (Safe Version)
# Install a PyTorch version compatible with CUDA 12.1 in the base image
RUN pip install --no-cache-dir --upgrade torch torchvision torchaudio


# ==============================================================
# 7. COMFYUI & CUSTOM REQUIREMENTS
# ==============================================================

# ComfyUI main requirements
RUN pip install --no-cache-dir -r requirements.txt

# RunPod-specific requirements
RUN pip install --no-cache-dir -r requirements_runpod.txt

# ==============================================================
# 8. FINAL LIBRARY OVERRIDE
# ==============================================================

# Ensures OpenCV is compatible with LayerStyle / custom nodes
RUN pip install --no-cache-dir --force-reinstall opencv-contrib-python==4.9.0.80

# ==============================================================
# 9. CUSTOM NODE SETUP
# ==============================================================

COPY setup.sh . 
RUN sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh

# ==============================================================
# 10. COPY CONFIGS & HANDLER
# ==============================================================

COPY extra_model_paths.yaml .
COPY workflow_api.json .
COPY rp_handler.py .
COPY model_setup.py .
COPY start.sh .

# Fix permissions for start script
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# ==============================================================
# 11. ENTRYPOINT
# ==============================================================

ENTRYPOINT ["/ComfyUI/start.sh"]

