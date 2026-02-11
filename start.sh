#!/usr/bin/env bash

set -e  # Fail immediately on ANY error — critical for robustness

echo "🚀 Starting Container..."

# STRICT NETWORK VOLUME CHECK (Can't be faked)
echo "🔍 Verifying persistent Network Volume at /runpod-volume..."
mkdir -p /runpod-volume  # Safe create

# Device ID comparison: Only passes if truly separate mounted filesystem
root_dev=$(stat -c %d / 2>/dev/null || echo 0)
vol_dev=$(stat -c %d /runpod-volume 2>/dev/null || echo 0)

if [ "$root_dev" = "$vol_dev" ] || [ "$vol_dev" = "0" ]; then
    echo "❌ CRITICAL ERROR: No persistent Network Volume mounted!"
    echo "   This endpoint REQUIRES a 100GB+ Network Volume for large models (~30GB)."
    echo "   👉 FIX IN RUNPOD DASHBOARD:"
    echo "      1. Endpoint > Edit"
    echo "      2. Network Volume > Create/attach one"
    echo "      3. Mount Path: EXACTLY /runpod-volume"
    echo "      4. Save & Redeploy"
    exit 1
fi

# Writability check
[ -w "/runpod-volume" ] || { echo "❌ Volume not writable!"; exit 1; }

available_gb=$(df -BG /runpod-volume | tail -1 | awk '{print $4}' | sed 's/G//')
echo "✅ Volume verified: ${available_gb}GB available."
[ "$available_gb" -lt 100 ] && echo "⚠️  WARNING: Low space — recommend 100GB+."

# CREATE MODEL SKELETON
echo "📁 Creating model directories..."
mkdir -p /runpod-volume/models/{checkpoints,clip,clip_vision,configs,controlnet,embeddings,loras,upscale_models,vae,unet}

# LINK HUGGINGFACE CACHE
echo "🔗 Linking cache to volume..."
mkdir -p /runpod-volume/.cache/huggingface
rm -rf /root/.cache/huggingface
mkdir -p /root/.cache
ln -s /runpod-volume/.cache/huggingface /root/.cache/huggingface

# DOWNLOAD MODELS (Will fail hard if issue — thanks to set -e + model_setup fixes)
echo "⏳ Ensuring models are downloaded..."
python model_setup.py

# INPUT/OUTPUT DIRS
mkdir -p /ComfyUI/input /ComfyUI/output

# START COMFYUI
echo "🔄 Starting ComfyUI..."
python main.py --listen 127.0.0.1 --port 8188 &

# HEALTH CHECK
echo "⏳ Waiting for ComfyUI..."
timeout 600s bash -c 'until wget --quiet --spider http://127.0.0.1:8188/history; do sleep 2; done' || {
    echo "❌ ComfyUI failed to start!"
    exit 1
}

echo "✅ ComfyUI ready."

# START HANDLER
echo "⚡ Starting RunPod Handler..."
exec python rp_handler.py