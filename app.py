import os
import shutil
import subprocess
import time
import requests
import threading
import signal
import sys
import antigravity
import google.generativeai as genai
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app) # Allow React frontend to access

# --- CONFIG ---
R_PORT = 8000
PY_PORT = 5000
R_API_URL = f"http://127.0.0.1:{R_PORT}"

# Configure Gemini
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
if GOOGLE_API_KEY:
    genai.configure(api_key=GOOGLE_API_KEY)

# --- SUBPROCESS MANAGEMENT ---
r_process = None

def find_rscript():
    """Attempts to locate Rscript.exe on Windows"""
    # Check PATH first
    if shutil.which('Rscript'):
        return 'Rscript'
        
    # Check common locations
    common_paths = [
        r"C:\Program Files\R\R-4.4.1\bin\x64\Rscript.exe",
        r"C:\Program Files\R\R-4.4.0\bin\x64\Rscript.exe",
        r"C:\Program Files\R\R-4.3.3\bin\x64\Rscript.exe",
        r"C:\Program Files\R\R-4.5.2\bin\x64\Rscript.exe", # Found in user system
    ]
    
    # Search Program Files for any R version
    try:
        if os.path.exists(r"C:\Program Files\R"):
            for entry in os.scandir(r"C:\Program Files\R"):
                if entry.is_dir() and entry.name.startswith("R-"):
                    potential = os.path.join(entry.path, "bin", "x64", "Rscript.exe")
                    if os.path.exists(potential):
                        return potential
    except Exception:
        pass

    return None

def start_r_server():
    """Starts the R Plumber server as a subprocess."""
    global r_process
    print("🚀 Starting R Plumber API...")
    
    r_exec = find_rscript()
    if not r_exec:
        print("❌ CRITICAL ERROR: 'Rscript' not found in PATH or standard locations.")
        print("   Please install R or add it to your PATH.")
        return

    print(f"   Using R executable: {r_exec}")

    # Point to local R_libs
    r_libs_path = os.path.join(os.getcwd(), "R_libs")
    
    # Copy current env and add R_LIBS
    env = os.environ.copy()
    # If R_LIBS exists, append, otherwise set.
    # We prepend our local lib to ensure priority.
    if 'R_LIBS' in env:
        env['R_LIBS'] = f"{r_libs_path};{env['R_LIBS']}"
    else:
        env['R_LIBS'] = r_libs_path

    # The command runs the plumber router on port 8000.
    # We also explicitly add .libPaths() in the command just in case env propagation is tricky on some Windows setups
    r_cmd_str = f"lib_path <- '{r_libs_path.replace(os.sep, '/')}'; .libPaths(c(lib_path, .libPaths())); library(plumber); pr <- plumb('api.R'); pr$run(port={R_PORT})"
    cmd = [r_exec, '-e', r_cmd_str]
    
    try:
        r_process = subprocess.Popen(cmd, cwd=os.getcwd(), env=env, stdout=sys.stdout, stderr=sys.stderr)
        # Give it a moment to spin up
        time.sleep(3)
        if r_process.poll() is not None:
             print("❌ R Server failed to start instantly.")
        else:
             print(f"✅ R Server started on port {R_PORT}")
    except Exception as e:
         print(f"❌ Failed to start R subprocess: {e}")

def stop_r_server():
    """Stops the R backend."""
    global r_process
    if r_process:
        print("🛑 Stopping R Server...")
        r_process.terminate()
        r_process = None

# Handle graceful shutdown
def signal_handler(sig, frame):
    print('Exiting...')
    stop_r_server()
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

# --- ROUTES ---

@app.route('/health', methods=['GET'])
def health():
    """Check if both Py and R are alive"""
    r_status = "unknown"
    try:
        # Just check if we can connect to R
        # Plumber doesn't have a default health check unless we defined it, 
        # but connecting to /plot (GET) should work if we updated it to generic. 
        # Actually api.R /plot is legacy. Let's assume if connection works it's up.
        requests.get(f"{R_API_URL}/plot", timeout=1) 
        r_status = "alive"
    except:
        r_status = "unreachable"
        
    return jsonify({"python": "alive", "r_backend": r_status})

@app.route('/upload', methods=['POST'])
def upload_proxy():
    """
    Receives file from React, forwards to R, 
    Gets Plots from R, 
    Calls Gemini for Insights (optional),
    Returns combined result.
    """
    if 'dataset' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    
    file = request.files['dataset']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Function to forward to R
    try:
        # Read file into memory to ensure we have the content
        file_content = file.read()
        print(f"📥 Received file: {file.filename} ({len(file_content)} bytes)")
        
        # Prepare file for forwarding
        files = {'dataset': (file.filename, file_content, file.content_type)}
        
        # Call R API
        print(f"📤 Forwarding {file.filename} to R Backend at {R_API_URL}/upload...")
        r_response = requests.post(f"{R_API_URL}/upload", files=files)
        
        print(f"⬅️ R Backend responded: {r_response.status_code}")
        
        if r_response.status_code != 200:
            print(f"❌ R Error detected: {r_response.text}")
            return jsonify({'error': f"R Backend failed: {r_response.text}"}), 500
            
        r_data = r_response.json()
        
        # If R reported an error inside JSON
        if 'error' in r_data:
             print(f"⚠️ R Logic Error: {r_data['error']}")
             return jsonify(r_data), 400

        # --- GEMINI INTEGRATION ---
        # If we have an API Key, generate insights based on the summary R returned
        ai_insights = "Gemini API Key not configured."
        if GOOGLE_API_KEY:
             try:
                model = genai.GenerativeModel('gemini-1.5-flash')
                # We assume R returns 'summary' text or we just say "Analyze this dataset structure..."
                # Previous api.R edit returned 'summary'.
                context = r_data.get('summary', 'No summary provided.')
                prompt = f"Role: Data Analyst. Task: Provide 3 short, punchy insights about this dataset summary. Data Summary: {context}"
                
                ai_resp = model.generate_content(prompt)
                ai_insights = ai_resp.text
             except Exception as e:
                ai_insights = f"AI Insight Generation Failed: {str(e)}"
        
        # Merge results
        r_data['ai_insights'] = ai_insights
        
        return jsonify(r_data)

    except requests.exceptions.ConnectionError:
        return jsonify({'error': 'Could not connect to R Analysis Backend. Is R installed?'}), 503
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/ask-ai', methods=['POST'])
def ask_ai():
    """Direct chat with Gemini"""
    if not GOOGLE_API_KEY:
        return jsonify({'error': 'API Key not set'}), 403
        
    data = request.json
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        response = model.generate_content(data.get('prompt', 'Hello'))
        return jsonify({'response': response.text})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Start R in background
    start_r_server()
    
    print(f"🐍 Python Backend running on http://127.0.0.1:{PY_PORT}")
    app.run(debug=True, port=PY_PORT, use_reloader=False) # No reloader to avoid double R process
