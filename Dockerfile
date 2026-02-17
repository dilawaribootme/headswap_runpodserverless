# 1. BASE IMAGE: Verified stable version (CUDA 12.1)
FROM runpod/pytorch:2.2.1-py3.10-cuda12.1.1-devel-ubuntu22.04

# Prevent Python buffering
ENV PYTHONUNBUFFERED=1

# 2. SYSTEM DEPENDENCIES
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 3. WORKDIR
WORKDIR /ComfyUI

# 4. CLONE COMFYUI
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git . \
    && rm -rf .git

# 5. DEPENDENCY PREPARATION
COPY requirements_runpod.txt requirements_runpod.txt
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 6. ALIGNED PYTORCH INSTALL (The "No-Fail" Version)
# We use Torch 2.5.1 (Stable, satisfies >2.4 requirement)
# By NOT adding +cu121 to the version string, we prevent the "Not Found" error.
# The --index-url ensures it still gets the CUDA-optimized version.
RUN pip install --no-cache-dir --force-reinstall \
    torch==2.5.1 \
    torchvision==0.20.1 \
    torchaudio==2.5.1 \
    --index-url https://download.pytorch.org/whl/cu121

# 7. COMFYUI & CUSTOM REQUIREMENTS
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r requirements_runpod.txt

# 8. FINAL LIBRARY OVERRIDE (OpenCV Fix)
# We uninstall all possible variants first to clear any conflicts
RUN pip uninstall -y opencv-python opencv-contrib-python opencv-python-headless opencv-contrib-python-headless && \
    pip install --no-cache-dir opencv-contrib-python==4.9.0.80

# 9. CUSTOM NODE SETUP
COPY setup.sh .
RUN sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh

# 10. CONFIGS & HANDLER
COPY extra_model_paths.yaml .
COPY workflow_api.json .
COPY rp_handler.py .
COPY model_setup.py .
COPY start.sh .

# Fix permissions for boot script
RUN sed -i 's/\r$//' start.sh && chmod +x start.sh

# 11. BOOT SEQUENCE
ENTRYPOINT ["/ComfyUI/start.sh"]