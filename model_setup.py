import os
import subprocess
import logging
import sys

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger("ModelSetup")

VOLUME_ROOT = "/runpod-volume"

MODEL_MAP = {
    f"{VOLUME_ROOT}/models/vae/qwen_image_vae.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors",
    
    f"{VOLUME_ROOT}/models/clip/qwen/qwen_2.5_vl_7b_fp8_scaled.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",
    
    f"{VOLUME_ROOT}/models/unet/qwen/qwen_image_edit_2509_fp8_e4m3fn.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors",
    
    f"{VOLUME_ROOT}/models/loras/qwen/bfs_head_v3_qwen_image_edit_2509.safetensors": 
        "https://huggingface.co/Alissonerdx/BFS-Best-Face-Swap/resolve/main/bfs_head_v3_qwen_image_edit_2509.safetensors"
}

def download_with_wget(url, file_path):
    try:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        logger.info(f"⬇️ Downloading/Resuming: {os.path.basename(file_path)}")
        subprocess.run(["wget", "-c", "--progress=bar:force:noscroll", url, "-O", file_path], check=True)
        logger.info(f"✅ Complete: {os.path.basename(file_path)}")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"❌ Download failed: {os.path.basename(file_path)} | {e}")
        return False

def ensure_models_exist():
    if not os.path.exists(VOLUME_ROOT):
        logger.error(f"❌ CRITICAL: Volume missing at {VOLUME_ROOT}!")
        return False
    
    logger.info("🔍 Processing models...")
    for file_path, url in MODEL_MAP.items():
        if not download_with_wget(url, file_path):
            logger.error(f"⚠️ Failed: {os.path.basename(file_path)} — aborting.")
            return False
    
    logger.info("🎉 All models ready!")
    return True

if __name__ == "__main__":
    if not ensure_models_exist():
        logger.error("❌ Model setup FAILED — stopping container.")
        sys.exit(1)  # Forces start.sh to crash
    logger.info("✅ Model setup successful.")
    sys.exit(0)