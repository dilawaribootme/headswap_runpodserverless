import json
import base64
import time
import runpod
import requests
import os
import uuid
import logging

# Configure Logging
logging.basicConfig(level=logging.INFO)

# Load Workflow Template
try:
    with open("workflow_api.json", "r") as f:
        WORKFLOW_TEMPLATE = json.load(f)
    logging.info("✅ Workflow template loaded successfully.")
except Exception as e:
    logging.error(f"❌ Failed to load workflow_api.json: {e}")
    raise

def save_base64_image(b64_string: str, save_path: str):
    try:
        if "," in b64_string:
            b64_string = b64_string.split(",", 1)[1]
        with open(save_path, "wb") as f:
            f.write(base64.b64decode(b64_string))
    except Exception as e:
        raise Exception(f"Failed to decode base64 image: {str(e)}")

def find_node_by_title(workflow: dict, title: str) -> str:
    for node_id, node in workflow.items():
        if node.get("_meta", {}).get("title") == title:
            return node_id
    raise ValueError(f"Node with title '{title}' not found in workflow.")

def handler(job):
    job_input = job.get("input", {})
    job_id = str(uuid.uuid4())
    
    input_dir = "/ComfyUI/input"
    output_dir = "/ComfyUI/output"
    os.makedirs(input_dir, exist_ok=True)
    os.makedirs(output_dir, exist_ok=True)
    
    head_filename = f"head_{job_id}.png"
    body_filename = f"body_{job_id}.png"
    head_path = os.path.join(input_dir, head_filename)
    body_path = os.path.join(input_dir, body_filename)
    files_to_delete = [head_path, body_path]

    try:
        head_b64 = job_input.get("head_image")
        body_b64 = job_input.get("body_image")
        
        if not head_b64 or not body_b64:
            return {"error": "Missing head_image or body_image"}

        save_base64_image(head_b64, head_path)
        save_base64_image(body_b64, body_path)

        workflow = json.loads(json.dumps(WORKFLOW_TEMPLATE))
        
        try:
            head_node_id = find_node_by_title(workflow, "HEAD_IMAGE")
            body_node_id = find_node_by_title(workflow, "BODY_IMAGE")
            save_node_id = find_node_by_title(workflow, "SAVE_OUTPUT")
        except ValueError as ve:
            return {"error": f"Workflow Metadata Error: {str(ve)}"}

        workflow[head_node_id]["inputs"]["image"] = head_filename
        workflow[body_node_id]["inputs"]["image"] = body_filename
        
        prompt_id = None
        for attempt in range(3):
            try:
                prompt_req = requests.post(
                    "http://127.0.0.1:8188/prompt", 
                    json={"prompt": workflow}, 
                    timeout=10
                )
                prompt_req.raise_for_status()
                prompt_id = prompt_req.json().get("prompt_id")
                if prompt_id:
                    break
            except Exception as err:
                logging.warning(f"⚠️ ComfyUI Prompt Retry {attempt+1}: {err}")
                time.sleep(2)
        
        if not prompt_id:
            return {"error": "Failed to queue prompt after 3 retries"}

        timeout = 400 
        start_time = time.time()
        connection_error_count = 0
        
        while time.time() - start_time < timeout:
            time.sleep(2)
            try:
                history_req = requests.get(f"http://127.0.0.1:8188/history/{prompt_id}", timeout=5)
                history_req.raise_for_status()
                history = history_req.json()
                connection_error_count = 0 
            except Exception:
                connection_error_count += 1
                if connection_error_count > 5:
                     logging.error("CRITICAL: ComfyUI crashed or is unresponsive.")
                     return {"error": "CRITICAL: ComfyUI crashed. Check Server RAM/VRAM."}
                continue
            
            if prompt_id in history:
                outputs = history[prompt_id].get("outputs", {})
                if save_node_id in outputs and "images" in outputs[save_node_id]:
                    img_info = outputs[save_node_id]["images"][0]
                    out_filename = img_info['filename']
                    out_path = os.path.join(output_dir, out_filename)
                    files_to_delete.append(out_path)
                    
                    if os.path.exists(out_path):
                        with open(out_path, "rb") as f:
                            b64_result = base64.b64encode(f.read()).decode("utf-8")
                        return {"result": b64_result}
        
        return {"error": "Timeout: Generation exceeded 400 seconds"}
    
    except Exception as e:
        return {"error": f"Handler Crash: {str(e)}"}
    
    finally:
        for f in files_to_delete:
            if os.path.exists(f):
                try: os.remove(f)
                except: pass

runpod.serverless.start({"handler": handler})