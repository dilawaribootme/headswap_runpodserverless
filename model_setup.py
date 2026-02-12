import os
import subprocess
import logging
import sys

# Configure logging
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger("ModelSetup")

VOLUME_ROOT = "/runpod-volume"

# Define the models
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
    """Downloads a file and creates a .done receipt only upon success."""
    try:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        # Define the receipt file path
        receipt_path = f"{file_path}.done"

        logger.info(f"⬇️ Downloading: {os.path.basename(file_path)}...")
        
        # -c allows resuming if the file exists but is incomplete
        subprocess.run(["wget", "-c", "--progress=bar:force:noscroll", url, "-O", file_path], check=True)
        
        # SUCCESS! Create the receipt file
        with open(receipt_path, 'w') as f:
            f.write("completed")
            
        logger.info(f"✅ Download Complete & Verified: {os.path.basename(file_path)}")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"❌ Download Failed: {os.path.basename(file_path)} | Error: {e}")
        # If download failed, ensure no receipt exists so we try again next time
        if os.path.exists(receipt_path):
            os.remove(receipt_path)
        return False

def ensure_models_exist():
    """Checks for .done receipts. If missing, downloads the model."""
    
    if not os.path.exists(VOLUME_ROOT):
        logger.error(f"❌ CRITICAL ERROR: Network Volume missing at {VOLUME_ROOT}!")
        return False
    
    logger.info(f"🔍 Verifying model integrity in {VOLUME_ROOT}...")
    all_success = True

    for file_path, url in MODEL_MAP.items():
        receipt_path = f"{file_path}.done"
        
        # 1. THE FIX: Check for the RECEIPT, not just the file.
        # If model exists AND receipt exists -> It is 100% complete.
        if os.path.exists(file_path) and os.path.exists(receipt_path):
            logger.info(f"✅ Verified: {os.path.basename(file_path)} (Skipping download)")
            continue

        # 2. If we are here, either the file is missing OR it's partial (no receipt).
        if os.path.exists(file_path) and not os.path.exists(receipt_path):
             logger.warning(f"⚠️  Partial/Corrupt file found: {os.path.basename(file_path)}. Resuming download...")

        # 3. Download (Wget will resume from where it left off)
        if not download_with_wget(url, file_path):
            all_success = False
    
    if all_success:
        logger.info("🎉 All models verified and ready!")
        return True
    else:
        logger.error("⚠️ Some models failed to download.")
        return False

if __name__ == "__main__":
    if not ensure_models_exist():
        sys.exit(1)
    
    logger.info("✅ Model setup successful.")
    sys.exit(0)