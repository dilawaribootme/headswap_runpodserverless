#!/bin/bash

# SAFETY: Ensure custom_nodes directory exists
mkdir -p /ComfyUI/custom_nodes
cd /ComfyUI/custom_nodes

echo "⬇️ Cloning Mandatory Custom Nodes (Slim Mode)..."

# Clone Qwen Image Edit
git clone --depth 1 https://github.com/Comfy-Org/Qwen-Image-Edit_ComfyUI.git
rm -rf Qwen-Image-Edit_ComfyUI/.git

# Clone AuraFlow
git clone --depth 1 https://github.com/huchenlei/ComfyUI-AuraFlow.git
rm -rf ComfyUI-AuraFlow/.git

# Clone Flux Kontext
git clone --depth 1 https://github.com/pamparamm/ComfyUI-Flux-Kontext-Image-Scale.git
rm -rf ComfyUI-Flux-Kontext-Image-Scale/.git

# CRITICAL FIX: Install dependencies for all cloned nodes
# This ensures nodes like AuraFlow don't crash due to missing libraries.
echo "📦 Installing Custom Node Dependencies..."
find /ComfyUI/custom_nodes -name "requirements.txt" -exec pip install --no-cache-dir -r {} \;

echo "✅ Setup Complete (Nodes + Dependencies Installed)"