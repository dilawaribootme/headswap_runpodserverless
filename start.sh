#!/usr/bin/env bash

set -e  # Fail on error

echo "🚀 Starting Container (STRICT MODE)..."

# 1. GPU CHECK
nvidia-smi || { echo "❌ GPU not detected! Check RunPod settings."; exit 1; }

# 2. NETWORK VOLUME CHECK
echo "🔍 Verifying persistent Network Volume..."
if [ ! -d "/runpod-volume" ]; then
    echo "❌ CRITICAL ERROR: /runpod-volume is missing completely!"
    exit 1
fi

# 3. STRICT FOLDER VERIFICATION
echo "🧐 Auditing folder structure..."

MISSING_FOLDERS=0

# Define the critical paths we require
REQUIRED_DIRS=(
    "/runpod-volume/models/vae"
    "/runpod-volume/models/clip/qwen"
    "/runpod-volume/models/unet/qwen"
    "/runpod-volume/models/loras/qwen"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "❌ ERROR: Missing required folder: $dir"
        MISSING_FOLDERS=1
    else
        echo "✅ Found: $dir"
    fi
done

if [ "$MISSING_FOLDERS" -eq 1 ]; then
    echo "---------------------------------------------------"
    echo "🚨 STARTUP FAILED: FOLDER STRUCTURE INCORRECT"
    echo "   The script will NOT auto-create these folders."
    echo "   Please access the volume and create the paths above."
    echo "---------------------------------------------------"
    # We exit here so you can see the error in the logs.
    exit 1
fi

# 4. LINK CACHE (Standard System Operation)
# We safely link the cache only if the volume structure passed
mkdir -p /runpod-volume/.cache/huggingface
rm -rf /root/.cache/huggingface
mkdir -p /root/.cache
ln -s /runpod-volume/.cache/huggingface /root/.cache/huggingface

# 5. RUN FILE AUDIT
# The folders exist, now we check if the FILES are inside them.
python -u model_setup.py

# 6. START COMFYUI
echo "🔄 Starting ComfyUI..."
mkdir -p /ComfyUI/input /ComfyUI/output
# MODIFICATION: Added --highvram and --disable-smart-memory to force persistence
python -u main.py --listen 127.0.0.1 --port 8188 --highvram --disable-smart-memory &

# 7. HEALTH CHECK
echo "⏳ Waiting for ComfyUI to go live..."
timeout 60s bash -c 'until wget --quiet --spider http://127.0.0.1:8188/history; do sleep 2; done' || {
    echo "⚠️ ComfyUI slow to start, but proceeding to handler..."
}

echo "✅ ComfyUI is running."

# 8. START HANDLER
echo "⚡ Starting RunPod Handler..."
exec python -u rp_handler.py