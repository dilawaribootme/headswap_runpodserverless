import os
import subprocess
import logging
import sys

# Configure logging to show up in RunPod Dashboard
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger("ModelSetup")

# CONFIGURATION
# This path MUST match the 'Mount Path' in RunPod Settings
VOLUME_ROOT = "/runpod-volume"

# The Exact Map: [Volume Path] -> [Hugging Face URL]
# Updated for the Qwen/BFS "Universal Head Swapper" Workflow
MODEL_MAP = {
    # 1. VAE (Found in Qwen-Image_ComfyUI repo)
    # CORRECTION: Removed "-Edit" from the URL
    f"{VOLUME_ROOT}/models/vae/qwen_image_vae.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors",
    
    # 2. CLIP (Qwen 2.5 VL) (Found in Qwen-Image_ComfyUI repo)
    # CORRECTION: Removed "-Edit" from the URL
    f"{VOLUME_ROOT}/models/clip/qwen/qwen_2.5_vl_7b_fp8_scaled.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors",
    
    # 3. UNET (The 20GB Giant) (Found in Qwen-Image-Edit_ComfyUI repo)
    # NOTE: This one stays as "-Edit" because the UNET is specific to the Edit model
    f"{VOLUME_ROOT}/models/unet/qwen/qwen_image_edit_2509_fp8_e4m3fn.safetensors": 
        "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors",
    
    # 4. LoRA (BFS Best Face Swap)
    f"{VOLUME_ROOT}/models/loras/qwen/bfs_head_v3_qwen_image_edit_2509.safetensors": 
        "https://huggingface.co/Alissonerdx/BFS-Best-Face-Swap/resolve/main/bfs_head_v3_qwen_image_edit_2509.safetensors"
}

def download_with_wget(url, file_path):
    """
    Uses the system 'wget' command to download.
    Provides a visual progress bar and resume capability (-c).
    """
    try:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        logger.info(f"⬇️  Starting Download: {os.path.basename(file_path)}")
        
        # The Magic Command:
        # -c : Continue getting a partially-downloaded file (Resume)
        # -O : Save it with this specific filename
        # --progress=bar:force : Force the progress bar to show in logs
        command = ["wget", "-c", url, "-O", file_path, "--progress=bar:force:noscroll"]
        
        # Run the command and wait for it to finish
        subprocess.run(command, check=True)
        
        logger.info(f"✅ Download Complete: {os.path.basename(file_path)}")
        return True
        
    except subprocess.CalledProcessError as e:
        logger.error(f"❌ Download Failed for {file_path}. Error: {e}")
        return False

def ensure_models_exist():
    """
    Main Logic: Iterates through the map and downloads missing files.
    """
    if not os.path.exists(VOLUME_ROOT):
        logger.error(f"❌ CRITICAL ERROR: Volume not found at {VOLUME_ROOT}. Did you set the Mount Path?")
        return

    logger.info("🔍 [Hybrid-Downloader] Checking Model Files...")
    
    for file_path, url in MODEL_MAP.items():
        if os.path.exists(file_path):
            # OPTIONAL: Check file size here if you want to be extra safe
            logger.info(f"✅ Found: {os.path.basename(file_path)}")
        else:
            # File is missing -> Call the Wget function
            success = download_with_wget(url, file_path)
            if not success:
                logger.error("⚠️ Stopping setup due to download failure.")
                return

if __name__ == "__main__":
    ensure_models_exist()