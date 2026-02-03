import os
import requests
import logging
import sys

# Configure logging to show up in RunPod Dashboard
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger("ModelSetup")

# CONFIGURATION
# This path MUST match the 'Mount Path' in RunPod Settings
VOLUME_ROOT = "/runpod-volume"

# The Exact Map: [Volume Path] -> [Hugging Face URL]
# We map these to the exact subfolders your Workflow expects.
MODEL_MAP = {
    # 1. VAE
    f"{VOLUME_ROOT}/models/vae/qwen_image_vae.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors",
    
    # 2. CLIP (Must be inside 'qwen' folder)
    f"{VOLUME_ROOT}/models/clip/qwen/qwen_2.5_vl_7b_fp8_scaled.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",
    
    # 3. UNET (Must be inside 'qwen' folder) - 20GB+
    f"{VOLUME_ROOT}/models/unet/qwen/qwen_image_edit_2509_fp8_e4m3fn.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors",
    
    # 4. LoRA (Must be inside 'qwen' folder)
    f"{VOLUME_ROOT}/models/loras/qwen/bfs_head_v3_qwen_image_edit_2509.safetensors": 
        "https://huggingface.co/Alissonerdx/BFS-Best-Face-Swap/resolve/main/bfs_head_v3_qwen_image_edit_2509.safetensors"
}

def ensure_models_exist():
    """
    Checks the Network Volume for required models.
    If missing, streams them directly from Hugging Face.
    """
    # Safety Check: Is volume mounted?
    if not os.path.exists(VOLUME_ROOT):
        logger.error(f"❌ CRITICAL ERROR: Volume not found at {VOLUME_ROOT}. Did you set the Mount Path?")
        # We allow it to continue, but ComfyUI will likely fail later.
        return

    logger.info("🔍 [Auto-Downloader] Verifying Model Files...")
    
    for file_path, url in MODEL_MAP.items():
        if os.path.exists(file_path):
            logger.info(f"✅ Found: {os.path.basename(file_path)}")
        else:
            logger.info(f"⬇️ Downloading missing file: {os.path.basename(file_path)}...")
            try:
                # Create directory (Redundant check to be safe)
                os.makedirs(os.path.dirname(file_path), exist_ok=True)
                
                # Stream the download (1MB chunks) to prevent RAM issues
                with requests.get(url, stream=True) as r:
                    r.raise_for_status()
                    with open(file_path, 'wb') as f:
                        for chunk in r.iter_content(chunk_size=1024 * 1024): 
                            if chunk:
                                f.write(chunk)
                logger.info(f"🎉 Download Complete: {os.path.basename(file_path)}")
            except Exception as e:
                logger.error(f"❌ Failed to download {file_path}: {e}")
                # Clean up partial files so we don't load corrupt models later
                if os.path.exists(file_path):
                    os.remove(file_path)

if __name__ == "__main__":
    ensure_models_exist()