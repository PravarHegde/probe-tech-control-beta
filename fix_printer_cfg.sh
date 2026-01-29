#!/bin/bash
# fix_printer_cfg.sh
# Fixes empty or broken printer.cfg files

echo "Checking printer.cfg files..."

find ~/*_data/config -name "printer.cfg" | while read cfg; do
    echo "Inspecting $cfg"
    
    # Check if empty
    if [ ! -s "$cfg" ]; then
        echo "  - File is empty! Restoring template..."
        cat <<EOF > "$cfg"
[include probe_tech.cfg]

[mcu]
serial: /dev/serial/by-id/PLEASE_UPDATE_ME

[printer]
kinematics: none
max_velocity: 300
max_accel: 3000

# [virtual_sdcard]
# path: ~/printer_data/gcodes
# on_error_gcode: CANCEL_PRINT
EOF
        # Note: auto-fix relative paths if needed, but for now generic is better than empty
        # Update virtual_sdcard path dynamically
        inst_dir=$(dirname $(dirname "$cfg"))
        inst_name=$(basename "$inst_dir")
        sed -i "s|path: ~/printer_data/gcodes|path: ~/${inst_name}/gcodes|" "$cfg"
        
        echo "  - Restored default config."
    else
        # File not empty, check if [mcu] exists
        if ! grep -q "\[mcu\]" "$cfg"; then
            echo "  - Missing [mcu] section. Appending default..."
             cat <<EOF >> "$cfg"

[mcu]
serial: /dev/serial/by-id/PLEASE_UPDATE_ME
EOF
        fi
        
        # Check if serial is present inside mcu (simple grep)
        # multi-line regex is hard in bash, just check if serial: exists
        if ! grep -q "serial:" "$cfg"; then
             # It might be in an included file, but usually it's in printer.cfg
             # We won't touch it if we are not sure, to avoid breaking includes.
             echo "  - check: 'serial:' keyword not found in $cfg (might be in include)"
        fi
    fi
done

echo "Done."
