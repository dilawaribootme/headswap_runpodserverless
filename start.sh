#!/bin/bash

echo "🚀 Starting Container..."

# 1. MOUNT CHECK & SKELETON CREATION
if [ -d "/runpod-volume" ]; then
    echo "✅ Volume mounted. creating directory skeleton..."
    
    # Create the base
    mkdir -p /runpod-volume/models
    
    # Create the EXACT subfolders required by your extra_model_paths.yaml
    mkdir -p /runpod-volume/models/checkpoints
    mkdir -p /runpod-volume/models/clip
    mkdir -p /runpod-volume/models/clip_vision
    mkdir -p /runpod-volume/models/configs
    mkdir -p /runpod-volume/models/controlnet
    mkdir -p /runpod-volume/models/embeddings
    mkdir -p /runpod-volume/models/loras
    mkdir -p /runpod-volume/models/upscale_models
    mkdir -p /runpod-volume/models/vae
    mkdir -p /runpod-volume/models/unet
    
else
    echo "❌ CRITICAL: /runpod-volume is NOT mounted."
    echo "👉 Go to RunPod > Edit Template > Advanced > Volume Mount Path: /runpod-volume"
    exit 1
fi

# 2. AUTO-DOWNLOADER (The Fix: Run BEFORE ComfyUI starts)
echo "⏳ Checking/Downloading Models..."
python model_setup.py

# 3. SELECTIVE CACHE STRATEGY
echo "🔗 Linking HuggingFace Cache to Volume..."
mkdir -p /runpod-volume/.cache/huggingface
rm -rf /root/.cache/huggingface
mkdir -p /root/.cache
ln -s /runpod-volume/.cache/huggingface /root/.cache/huggingface

# 4. Create Input/Output directories
mkdir -p /ComfyUI/input /ComfyUI/output

# 5. Start ComfyUI (Background Process)
echo "🔄 Starting ComfyUI..."
python main.py --listen 127.0.0.1 --port 8188 &

# 6. Health Check
echo "⏳ Waiting for ComfyUI API..."
timeout 600s bash -c 'until wget --quiet --spider http://127.0.0.1:8188/history; do sleep 2; done'
if [ $? -ne 0 ]; then
    echo "❌ ComfyUI failed to start within 10 minutes."
    exit 1
fi

# 7. Start Handler
echo "⚡ Starting RunPod Handler..."
exec python rp_handler.py