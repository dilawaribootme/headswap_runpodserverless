#!/bin/bash

# 1. SETUP: Ensure custom_nodes directory exists
mkdir -p /ComfyUI/custom_nodes
cd /ComfyUI/custom_nodes

echo "⬇️ Cloning Verified Custom Nodes..."

# 2. INSTALL QWEN NODES (Corrected Link)
# We use lrzjason's repo because it contains 'TextEncodeQwenImageEditPlus'
if [ ! -d "Comfyui-QwenEditUtils" ]; then
    git clone --depth 1 https://github.com/lrzjason/Comfyui-QwenEditUtils.git
    rm -rf Comfyui-QwenEditUtils/.git
fi

# 3. INSTALL FLUX KONTEXT (via LayerStyle)
if [ ! -d "ComfyUI_LayerStyle" ]; then
    git clone --depth 1 https://github.com/chflame163/ComfyUI_LayerStyle.git
    rm -rf ComfyUI_LayerStyle/.git
fi

# 4. INSTALL DEPENDENCIES
echo "📦 Installing Custom Node Dependencies..."

if [ -f "Comfyui-QwenEditUtils/requirements.txt" ]; then
    pip install --no-cache-dir -r Comfyui-QwenEditUtils/requirements.txt
fi

if [ -f "ComfyUI_LayerStyle/requirements.txt" ]; then
    pip install --no-cache-dir -r ComfyUI_LayerStyle/requirements.txt
fi

# 🚨 CRITICAL FIX: Force Numpy back to 1.26.4
# (LayerStyle tries to upgrade it to 2.0+, which breaks ComfyUI)
echo "🛡️ Enforcing Numpy 1.26.4 Compatibility..."
pip install --no-cache-dir "numpy==1.26.4"

echo "✅ Setup Complete"