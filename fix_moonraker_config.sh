#!/bin/bash
# fix_moonraker_config.sh
# Fixes Moonraker configuration for Probe Tech Control

echo "Searching for moonraker.conf files..."

# Find all moonraker.conf in typical locations
find ~/printer_data/config ~/*_data/config -name "moonraker.conf" 2>/dev/null | while read conf; do
    echo "Processing $conf"
    
    # 1. Fix Section Header: [update_manager client probe_tech] -> [update_manager probe_tech]
    if grep -q "\[update_manager client probe_tech\]" "$conf"; then
        echo "  - Correcting section header..."
        sed -i 's/\[update_manager client probe_tech\]/[update_manager probe_tech]/' "$conf"
    fi

    # 2. Check for invalid path usage
    if grep -q "path: ~/probe-tech-control" "$conf"; then
        # Check if the directory exists
        if [ ! -d "${HOME}/probe-tech-control" ]; then
             echo "  - WARNING: Config points to ~/probe-tech-control which does NOT exist."
             echo "  - Commenting out the invalid section to prevent startup errors."
             
             # Comment out the section lines
             # This is a bit tricky with sed, simpler to just warn or maybe delete the lines?
             # Let's use a simple python snippet to comment out the block if path is missing
             python3 -c "
import sys
import re

conf_file = '$conf'
with open(conf_file, 'r') as f:
    lines = f.readlines()

new_lines = []
in_section = False
for line in lines:
    if line.strip() == '[update_manager probe_tech]':
        in_section = True
        new_lines.append('# ' + line)
    elif in_section and line.strip().startswith('['):
        in_section = False
        new_lines.append(line)
    elif in_section:
        new_lines.append('# ' + line)
    else:
        new_lines.append(line)

with open(conf_file, 'w') as f:
    f.writelines(new_lines)
"
             echo "  - Section commented out."
        fi
    fi
done

echo "Fix complete. Please restart Moonraker."
