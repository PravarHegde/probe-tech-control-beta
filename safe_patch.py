import os
import re

def main():
    base_dir = "/home/pravar/anti gravity/2 Probe-tech-control/1 ptc/dist"
    # Word boundary regex for "Mainsail"
    pattern = re.compile(r'\bMainsail\b')
    replacement = "Probe Tech Control"

    # Walk through dist
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith(('.js', '.json', '.html', '.webmanifest')):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    if pattern.search(content):
                        new_content = pattern.sub(replacement, content)
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        print(f"Patched: {file}")
                except Exception as e:
                    print(f"Skipped {file}: {e}")

if __name__ == "__main__":
    main()
