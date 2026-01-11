import os
import json

def replace_mainsail(data):
    if isinstance(data, dict):
        return {k: replace_mainsail(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [replace_mainsail(i) for i in data]
    elif isinstance(data, str):
        return data.replace("Mainsail", "Probe Tech Control")
    else:
        return data

locales_dir = "/home/pravar/anti gravity/2 Probe-tech-control/1 ptc/src/locales"
for filename in os.listdir(locales_dir):
    if filename.endswith(".json"):
        filepath = os.path.join(locales_dir, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
                updated_data = replace_mainsail(data)
                with open(filepath, "w", encoding="utf-8") as f_out:
                    json.dump(updated_data, f_out, indent=4, ensure_ascii=False)
                print(f"Updated {filename}")
            except Exception as e:
                print(f"Error processing {filename}: {e}")
