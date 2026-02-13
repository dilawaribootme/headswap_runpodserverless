import os
import subprocess
import logging
import sys
import shutil
from safetensors import safe_open

# Configure logging
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger("ModelSetup")

VOLUME_ROOT = "/runpod-volume"

# DATA-DRIVEN VALIDATION: Exact expected sizes in bytes
# Updated with VERIFIED exact byte counts to prevent redownload loops.
EXPECTED_SIZES = {
    "qwen_image_vae.safetensors": 253806246,
    "qwen_2.5_vl_7b_fp8_scaled.safetensors": 9384670680,
    "qwen_image_edit_2509_fp8_e4m3fn.safetensors": 20430635136,  # <--- FIXED: Exact Bytes
    # For the LoRA, we use a min_size check in the function below to be safe
    "bfs_head_v3_qwen_image_edit_2509.safetensors": 70000000 
}

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

def check_disk_space():
    """Ensure we have at least 30GB free before starting downloads."""
    try:
        total, used, free = shutil.disk_usage(VOLUME_ROOT)
        # Warn if we are dangerously low (adjusted for your 40GB volume)
        if free < 32 * 1024**3: # Check if we have space for the 30GB models + 2GB buffer
             logger.warning(f"⚠️ LOW DISK SPACE: Only {free / 1024**3:.2f} GB free. Recommend 60GB+ volume.")
        
        if free < 5 * 1024**3: # Hard stop if less than 5GB
            logger.error(f"❌ CRITICAL: Not enough disk space! Free: {free / 1024**3:.2f} GB")
            return False
        return True
    except Exception as e:
        logger.warning(f"⚠️ Could not check disk space: {e}")
        return True

def verify_safetensors(file_path):
    """Lightweight header validation + Size tolerance check."""
    filename = os.path.basename(file_path).replace(".tmp", "")
    
    if filename in EXPECTED_SIZES:
        actual_size = os.path.getsize(file_path)
        expected = EXPECTED_SIZES[filename]
        
        # SPECIAL HANDLING FOR BFS LORA (Allow variance)
        if "bfs_head" in filename:
            if actual_size < expected: # Just check it's not empty/tiny
                logger.warning(f"⚠️ LoRA size suspicious: {actual_size}")
                return False
        else:
            # STRICT CHECK for Large Models
            if abs(actual_size - expected) > 1024:
                logger.warning(f"⚠️ Size mismatch for {filename}: Expected {expected}, got {actual_size}")
                return False

    try:
        with safe_open(file_path, framework="pt", device="cpu") as f:
            _ = f.metadata()
        return True
    except Exception as e:
        logger.warning(f"⚠️ Header verification failed for {file_path}: {e}")
        return False

def download_with_wget(url, file_path):
    """Atomic download with increased timeout reliability."""
    try:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        temp_path = file_path + ".tmp"
        receipt_path = f"{file_path}.done"

        if os.path.exists(temp_path):
            os.remove(temp_path)

        logger.info(f"⬇️ Downloading fresh: {os.path.basename(file_path)}...")

        # Removed --no-check-certificate for better security
        result = subprocess.run([
            "wget", "--quiet", "--tries=10", "--timeout=600",
            url, "-O", temp_path
        ], check=True)

        if not verify_safetensors(temp_path):
            raise Exception("Integrity check failed after download.")

        os.rename(temp_path, file_path)
        open(receipt_path, 'a').close()

        logger.info(f"✅ Verified & Ready: {os.path.basename(file_path)}")
        return True

    except Exception as e:
        logger.error(f"❌ Download failed: {e}")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return False

def ensure_models_exist():
    if not os.path.exists(VOLUME_ROOT):
        logger.error(f"❌ CRITICAL ERROR: Network Volume missing at {VOLUME_ROOT}!")
        return False

    if not check_disk_space():
        return False
    
    logger.info(f"🔍 Verifying model integrity in {VOLUME_ROOT}...")
    all_success = True

    for file_path, url in MODEL_MAP.items():
        receipt_path = f"{file_path}.done"
        
        if os.path.exists(file_path) and os.path.exists(receipt_path):
            if verify_safetensors(file_path):
                logger.info(f"✅ Verified: {os.path.basename(file_path)} (Skipping)")
                continue
            else:
                os.remove(file_path)
                os.remove(receipt_path)

        if not download_with_wget(url, file_path):
            all_success = False
    
    return all_success

if __name__ == "__main__":
    if not ensure_models_exist():
        sys.exit(1)
    logger.info("✅ Model setup successful.")
    sys.exit(0)