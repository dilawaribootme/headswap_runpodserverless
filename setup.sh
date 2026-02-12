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

# 4. INSTALL COMFYUI ESSENTIALS (Required for CFGNorm)
# This prevents the "Unknown Node: CFGNorm" crash in your workflow
if [ ! -d "ComfyUI_essentials" ]; then
    echo "⬇️ Cloning ComfyUI_essentials..."
    git clone --depth 1 https://github.com/cubiq/ComfyUI_essentials.git
    rm -rf ComfyUI_essentials/.git
fi

# 5. INSTALL DEPENDENCIES
echo "📦 Installing Custom Node Dependencies..."

if [ -f "Comfyui-QwenEditUtils/requirements.txt" ]; then
    pip install --no-cache-dir -r Comfyui-QwenEditUtils/requirements.txt
fi

if [ -f "ComfyUI_LayerStyle/requirements.txt" ]; then
    echo "🛡️ Sanitizing LayerStyle requirements..."
    
    # 1. AGGRESSIVE FIX: Remove ANY line with 'opencv' to prevent conflicts
    # This deletes 'opencv-python', 'opencv-contrib-python', etc.
    sed -i '/opencv/d' ComfyUI_LayerStyle/requirements.txt
    
    # 2. PRO ACTIVE FIX: Install the HEADLESS Contrib version (Safe for servers)
    # This gives LayerStyle the features it needs without the GUI crash
    pip install --no-cache-dir "opencv-contrib-python-headless==4.9.0.80"
    
    # Install the rest of the requirements
    pip install --no-cache-dir -r ComfyUI_LayerStyle/requirements.txt
fi

if [ -f "ComfyUI_essentials/requirements.txt" ]; then
    pip install --no-cache-dir -r ComfyUI_essentials/requirements.txt
fi

# 🚨 CRITICAL FIX: Force Numpy back to 1.26.4
# (LayerStyle tries to upgrade it to 2.0+, which breaks ComfyUI)
echo "🛡️ Enforcing Numpy 1.26.4 Compatibility..."
pip install --no-cache-dir "numpy==1.26.4"

echo "✅ Setup Complete"