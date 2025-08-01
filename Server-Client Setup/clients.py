import socket
import requests
from datetime import datetime
import os
import json

# Identify system
system_id = socket.gethostname()

# Server settings
SERVER_URL = f"http://PUBLIC-IP/get_data/{system_id}"
API_TOKEN = "ADD YOUR TOKENS HERE"
HEADERS = {"X-Auth-Token": API_TOKEN}

# Timestamp for filename
timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
output_dir = "/tmp/fetched_data"
os.makedirs(output_dir, exist_ok=True)
output_file = f"{output_dir}/{system_id}_{timestamp}.txt"

def write_data_to_file(data, path):
    try:
        with open(path, "w", encoding='utf-8') as f:
            if isinstance(data, (dict, list)):
                json.dump(data, f, indent=2)
            elif isinstance(data, str):
                f.write(data)
            else:
                f.write(str(data))  # fallback
        print(f"✅ Data saved: {path}")
    except Exception as write_err:
        print(f"❌ Write error: {write_err}")

try:
    response = requests.get(SERVER_URL, headers=HEADERS, timeout=10)
    response.raise_for_status()

    # Grab 'data' key from JSON or fallback to entire body
    json_data = response.json()
    data = json_data.get("data", json_data)

    write_data_to_file(data, output_file)

except requests.exceptions.RequestException as req_err:
    print(f"❌ Request failed: {req_err}")
except ValueError as json_err:
    print(f"❌ JSON decoding failed: {json_err}")
except Exception as e:
    print(f"❌ Unexpected error: {e}")
