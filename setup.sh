#!/bin/bash

# 1. SETUP: Ensure custom_nodes directory exists
mkdir -p /ComfyUI/custom_nodes
cd /ComfyUI/custom_nodes

echo "⬇️ Cloning Verified Custom Nodes..."

# 2. INSTALL QWEN NODES
if [ ! -d "Comfyui-QwenEditUtils" ]; then
    git clone --depth 1 https://github.com/lrzjason/Comfyui-QwenEditUtils.git
    rm -rf Comfyui-QwenEditUtils/.git
fi

# 3. INSTALL LAYERSTYLE
if [ ! -d "ComfyUI_LayerStyle" ]; then
    git clone --depth 1 https://github.com/chflame163/ComfyUI_LayerStyle.git
    rm -rf ComfyUI_LayerStyle/.git
fi

# 4. INSTALL COMFYUI ESSENTIALS
if [ ! -d "ComfyUI_essentials" ]; then
    git clone --depth 1 https://github.com/cubiq/ComfyUI_essentials.git
    rm -rf ComfyUI_essentials/.git
fi

# 5. INSTALL DEPENDENCIES
echo "📦 Installing Custom Node Dependencies..."

# Function to sanitize requirements
sanitize_requirements() {
    local req_file=$1
    if [ -f "$req_file" ]; then
        echo "🛡️ Sanitizing $req_file..."
        # Remove opencv and numpy to prevent conflicts with our global versions
        sed -i '/opencv/d' "$req_file"
        sed -i '/numpy/d' "$req_file"
        # Install the rest
        pip install --no-cache-dir -r "$req_file"
    fi
}

# Run sanitization for all nodes
sanitize_requirements "Comfyui-QwenEditUtils/requirements.txt"
sanitize_requirements "ComfyUI_LayerStyle/requirements.txt"
sanitize_requirements "ComfyUI_essentials/requirements.txt"

echo "✅ Setup Complete"