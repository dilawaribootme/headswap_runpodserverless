#!/usr/bin/env bash

set -e  # Fail immediately on ANY error

echo "🚀 Starting Container..."

# 1. GPU CHECK (Fail fast if no GPU)
echo "🔍 Checking GPU memory..."
nvidia-smi || { echo "❌ GPU not detected! Check RunPod settings."; exit 1; }

# 2. NETWORK VOLUME CHECK
echo "🔍 Verifying persistent Network Volume at /runpod-volume..."
mkdir -p /runpod-volume

root_dev=$(stat -c %d / 2>/dev/null || echo 0)
vol_dev=$(stat -c %d /runpod-volume 2>/dev/null || echo 0)

if [ "$root_dev" = "$vol_dev" ] || [ "$vol_dev" = "0" ]; then
    echo "❌ CRITICAL ERROR: No persistent Network Volume mounted!"
    exit 1
fi

[ -w "/runpod-volume" ] || { echo "❌ Volume not writable!"; exit 1; }

# 3. SELF-HEALING: CRASH RECOVERY
# If this file exists, it means the previous boot failed before ComfyUI was ready.
if [ -f "/runpod-volume/.crash_flag" ]; then
  echo "🚨 Previous crash detected during startup. Cleaning models to prevent corrupt loops..."
  # We delete the specific model directories to force model_setup.py to re-verify/redownload
  rm -rf /runpod-volume/models/clip/qwen/*
  rm -rf /runpod-volume/models/unet/qwen/*
  rm -f /runpod-volume/.crash_flag
fi

# Set the crash flag NOW. It will only be removed if we reach the end of this script successfully.
touch /runpod-volume/.crash_flag

# 4. SKELETON & CACHE
echo "📁 Creating model directories..."
mkdir -p /runpod-volume/models/{checkpoints,clip,clip_vision,configs,controlnet,embeddings,loras,upscale_models,vae,unet}
mkdir -p /runpod-volume/.cache/huggingface
rm -rf /root/.cache/huggingface
mkdir -p /root/.cache
ln -s /runpod-volume/.cache/huggingface /root/.cache/huggingface

# 5. RUN MODEL SETUP
echo "⏳ Ensuring models are downloaded..."
python -u model_setup.py

# 6. START COMFYUI
echo "🔄 Starting ComfyUI..."
mkdir -p /ComfyUI/input /ComfyUI/output
python -u main.py --listen 127.0.0.1 --port 8188 &

# 7. HEALTH CHECK
echo "⏳ Waiting for ComfyUI..."
timeout 600s bash -c 'until wget --quiet --spider http://127.0.0.1:8188/history; do sleep 2; done' || {
    echo "❌ ComfyUI failed to start!"
    exit 1
}

# 8. REMOVE CRASH FLAG (Boot was successful)
rm -f /runpod-volume/.crash_flag
echo "✅ ComfyUI ready. System Healthy."

# 9. START HANDLER
echo "⚡ Starting RunPod Handler..."
exec python -u rp_handler.py