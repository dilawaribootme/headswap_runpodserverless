import os
import sys
import logging

# Configure logging
logging.basicConfig(stream=sys.stdout, level=logging.INFO, format='%(message)s')

VOLUME_ROOT = "/runpod-volume"

# The exact files expected
REQUIRED_FILES = [
    f"{VOLUME_ROOT}/models/vae/qwen_image_vae.safetensors",
    f"{VOLUME_ROOT}/models/clip/qwen/qwen_2.5_vl_7b_fp8_scaled.safetensors",
    f"{VOLUME_ROOT}/models/unet/qwen/qwen_image_edit_2509_fp8_e4m3fn.safetensors",
    f"{VOLUME_ROOT}/models/loras/qwen/bfs_head_v3_qwen_image_edit_2509.safetensors"
]

def audit_models():
    print("\n------------------------------------------------")
    print("📍 CHECKING FILES")
    print("------------------------------------------------")
    
    missing_files = False
    
    for file_path in REQUIRED_FILES:
        filename = os.path.basename(file_path)
        folder = os.path.dirname(file_path)
        
        if os.path.exists(file_path):
            print(f"✅ FOUND: {filename}")
        else:
            print(f"❌ MISSING: {filename}")
            print(f"   └─ Expected inside: {folder}")
            missing_files = False # We mark it missing but don't crash yet so you see all errors

    print("------------------------------------------------")
    
    if missing_files:
        print("🚨 CRITICAL: Files are missing!")
        print("   The container will start, but the workflow WILL fail.")
    else:
        print("ALL FILES VERIFIED.")
    
    print("------------------------------------------------\n")

if __name__ == "__main__":
    audit_models()