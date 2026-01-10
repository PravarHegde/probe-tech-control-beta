#!/bin/bash

# Probe Tech Control Advanced Installer and Manager
# Version 11: The Factory Production Suite (Auto-Port, Batch Mode, Auto-Sanitize)

# --- VARIABLES ---
HOME_DIR="${HOME}"
USER=$(whoami)
SERVICE_TEMPLATE="probe-tech.service"
BACKUP_DIR="${HOME}/probe_tech_backups"
# Get script directory to find cfg files reliably
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Colors (Blue, Silver/White, Gold)
BLUE='\033[1;34m'
SILVER='\033[1;37m'
GOLD='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Global to track created instance path
CREATED_CONF_DIR=""

# --- UTILS ---

print_box() {
    local text="$1"
    local color="$2"
    echo -e "${BLUE}=====================================================================${NC}"
    echo -e "${color}      $text      ${NC}"
    echo -e "${BLUE}=====================================================================${NC}"
}

get_ip() {
    hostname -I | awk '{print $1}'
}

# Improved Instance Detection: Looks DEEPER for printer.cfg (maxdepth 4)
get_instances() {
    find "${HOME}" -maxdepth 4 -name "printer.cfg" -print0 | xargs -0 -I {} dirname {} | sort | uniq
}

# Scan existing configs to find the highest used port
get_next_port() {
    local max_port=7124
    
    # Get all config directories
    mapfile -t instances < <(get_instances)
    
    for inst in "${instances[@]}"; do
        local mconf="${inst}/moonraker.conf"
        if [ -f "$mconf" ]; then
            # Extract port number. Matches "port: 7125" or "port:7125"
            local p=$(grep -E "^\s*port:\s*[0-9]+" "$mconf" | awk -F: '{print $2}' | tr -d ' ')
            if [[ "$p" =~ ^[0-9]+$ ]]; then
                if [ "$p" -gt "$max_port" ]; then
                    max_port=$p
                fi
            fi
        fi
    done
    
    echo $((max_port + 1))
}


# Shows a list of valid config directories to pick from
select_instance() {
    echo -e "${GOLD}Select Klipper Instance (Config Folder):${NC}"
    
    # Capture output of get_instances into array
    mapfile -t instances < <(get_instances)
    
    if [ ${#instances[@]} -eq 0 ]; then
        echo -e "${RED}No Klipper configurations found! (Checked for printer.cfg in ~/*)${NC}"
        echo -e "${SILVER}Creating default: ~/printer_data/config${NC}"
        mkdir -p "${HOME}/printer_data/config"
        touch "${HOME}/printer_data/config/printer.cfg"
        instances=("${HOME}/printer_data/config")
    fi

    i=1
    for inst in "${instances[@]}"; do
        # Show path relative to home for clarity
        rel_path="${inst/#$HOME/\~}"
        echo "$i) $rel_path"
        ((i++))
    done
    
    read -p "Enter number: " sel
    
    if [[ ! "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt ${#instances[@]} ]; then
        echo -e "${RED}Invalid selection.${NC}"
        return 1
    fi
    
    SELECTED_CONF_DIR="${instances[$((sel-1))]}"
    SELECTED_INSTANCE="$(dirname "$SELECTED_CONF_DIR")"
    
    echo -e "Selected Config: ${GREEN}${SELECTED_CONF_DIR}${NC}"
    return 0
}

check_status() {
    print_box "PROBE TECH CONTROL - ADVANCED MANAGER" "${BLUE}"
    
    # Check Probe Tech Config
    local installed=0
    mapfile -t instances < <(get_instances)
    for inst in "${instances[@]}"; do
        if [ -f "$inst/probe_tech.cfg" ]; then
            installed=1
            break
        fi
    done

    if [ $installed -eq 1 ]; then
         echo -e "Probe Tech Control: ${GREEN}Installed${NC}"
    else
         echo -e "Probe Tech Control: ${SILVER}Not Detected (Need Config)${NC}"
    fi

    # Check Moonraker
    if [ -d "${HOME}/moonraker" ]; then
        echo -e "Moonraker:          ${GREEN}Installed${NC}"
    else
        echo -e "Moonraker:          ${SILVER}Not Installed${NC}"
    fi

    # Check Klipper
    if [ -d "${HOME}/klipper" ]; then
        echo -e "Klipper:            ${GREEN}Installed${NC}"
    else
        echo -e "Klipper:            ${SILVER}Not Installed${NC}"
    fi
    
    # Check Service
    if systemctl is-active --quiet probe-tech; then
        echo -e "Service:            ${GREEN}Running${NC}"
    else
        echo -e "Service:            ${RED}Stopped${NC}"
    fi
    
    echo ""
    MY_IP=$(get_ip)
    echo -e "Web Interface:      ${GOLD}http://${MY_IP}:8080${NC}"
    echo -e "${BLUE}=====================================================================${NC}"
    echo ""
}

# --- WIFI MODULE ---

wifi_status() {
    echo -e "${GOLD}--- Network Status ---${NC}"
    nmcli -p device show wlan0 2>/dev/null | grep -E "IP4.ADDRESS|GENERAL.CONNECTION" | cat
    echo ""
}

connect_wifi() {
    echo -e "${BLUE}Scanning for networks... (Please wait)${NC}"
    mapfile -t networks < <(nmcli -f SSID,BARS,SIGNAL device wifi list | tail -n +2 | grep -v "^--" | awk '{$1=$1};1' | uniq | head -n 15)
    
    if [ ${#networks[@]} -eq 0 ]; then
        echo -e "${RED}No networks found.${NC}"
        return
    fi
    
    i=1
    for net in "${networks[@]}"; do
        echo "$i) $net"
        ((i++))
    done
    
    echo ""
    read -p "Select Network Number: " net_sel
    
    if [[ ! "$net_sel" =~ ^[0-9]+$ ]] || [ "$net_sel" -lt 1 ] || [ "$net_sel" -gt ${#networks[@]} ]; then
        echo -e "${RED}Invalid selection.${NC}"
        return
    fi
    
    RAW_LINE="${networks[$((net_sel-1))]}"
    echo -e "${YELLOW}Selected: $RAW_LINE${NC}"
    read -p "Enter SSID Name (Type exact name from above): " ssid_name
    read -s -p "Enter Password: " wifi_pass
    echo ""
    
    echo -e "${BLUE}Connecting to $ssid_name...${NC}"
    sudo nmcli device wifi connect "$ssid_name" password "$wifi_pass"
    read -p "Press Enter to continue..."
}

create_hotspot() {
    echo -e "${BLUE}=== CREATE HOTSPOT ===${NC}"
    read -p "Enter Hotspot SSID Name: " hs_ssid
    read -s -p "Enter Hotspot Password (min 8 chars): " hs_pass
    echo ""
    read -p "Select Security (1=WPA2, 2=Open): " sec
    
    if [ "$sec" == "2" ]; then
         echo -e "${YELLOW}Creating Open Hotspot...${NC}"
         sudo nmcli device wifi hotspot ifname wlan0 ssid "$hs_ssid"
    else
         echo -e "${YELLOW}Creating Secured Hotspot...${NC}"
         sudo nmcli device wifi hotspot ifname wlan0 ssid "$hs_ssid" password "$hs_pass"
    fi
    
    echo -e "${GREEN}Hotspot Created. Verify with Status option.${NC}"
    read -p "Press Enter..."
}

menu_wifi() {
    while true; do
        clear
        print_box "WIFI CONFIGURATION" "${GOLD}"
        wifi_status
        echo "1) Connect to WiFi Network (Scan & Select)"
        echo "2) Create Hotspot"
        echo "3) Show Network Info (LAN/Current)"
        echo "4) Back to Main Menu"
        echo ""
        read -p "Select: " c
        case $c in
            1) connect_wifi ;;
            2) create_hotspot ;;
            3)
                ip addr show | cat
                read -p "Press Enter..."
                ;;
            4) return ;;
        esac
    done
}

# --- INSTALL ACTIONS ---

install_klipper() {
    echo -e "${GOLD}Installing Klipper...${NC}"
    if [ ! -d "${HOME}/klipper" ]; then
        cd "${HOME}"
        git clone https://github.com/Klipper3d/klipper.git
        if [ -f "${HOME}/klipper/scripts/install-octopi.sh" ]; then
             ${HOME}/klipper/scripts/install-octopi.sh
        fi
    else
        echo -e "${GREEN}Klipper already present.${NC}"
    fi
    sudo usermod -a -G tty,dialout $USER
}

install_moonraker() {
    echo -e "${GOLD}Installing Moonraker...${NC}"
    if [ ! -d "${HOME}/moonraker" ]; then
        cd "${HOME}"
        git clone https://github.com/Arksine/moonraker.git
        if [ -f "${HOME}/moonraker/scripts/install-moonraker.sh" ]; then
             ${HOME}/moonraker/scripts/install-moonraker.sh
        fi
    else
         echo -e "${GREEN}Moonraker already present.${NC}"
    fi
}

install_probe_tech() {
    local target_dir="$1"
    
    # --- WEB INTERFACE DEPLOYMENT (NEW) ---
    echo -e "${GOLD}Deploying Web Interface...${NC}"
    WEB_DIR="${HOME}/probe-tech-control"
    
    # Check if we have a release zip in the script directory
    if [ -f "${SCRIPT_DIR}/probe-tech-control.zip" ]; then
        echo -e "${BLUE}Found probe-tech-control.zip, extracting...${NC}"
        
        # Create directory if missing
        mkdir -p "$WEB_DIR"
        
        # Clear old files (safety check: make sure we are not deleting root)
        if [ "$WEB_DIR" != "/" ]; then
            rm -rf "${WEB_DIR:?}/"*
        fi
        
        # Unzip
        unzip -o -q "${SCRIPT_DIR}/probe-tech-control.zip" -d "$WEB_DIR"
        
        # Check if unzip succeeded
        if [ -f "${WEB_DIR}/index.html" ]; then
             echo -e "${GREEN}✓ Web Interface Installed to ${WEB_DIR}${NC}"
        else
             echo -e "${RED}Extraction failed or index.html missing.${NC}"
        fi
    else
        echo -e "${SILVER}No probe-tech-control.zip found. Skipping web file deployment.${NC}"
        echo -e "${SILVER}(If developing, ensure files are in $WEB_DIR)${NC}"
    fi

    if [ -n "$target_dir" ]; then
        SELECTED_CONF_DIR="$target_dir"
        echo -e "${GOLD}Auto-configuring instance at: $SELECTED_CONF_DIR${NC}"
    else
        if ! select_instance; then return; fi
    fi
    
    PROBE_CFG="${SELECTED_CONF_DIR}/probe_tech.cfg"
    PRINTER_CFG="${SELECTED_CONF_DIR}/printer.cfg"
    MOONRAKER_CONF="${SELECTED_CONF_DIR}/moonraker.conf"
    
    # Use SCRIPT_DIR to find the cfg, ignoring CWD
    if [ -f "${SCRIPT_DIR}/probe_tech.cfg" ]; then
        cp "${SCRIPT_DIR}/probe_tech.cfg" "$PROBE_CFG"
        echo -e "${GREEN}✓ probe_tech.cfg copied${NC}"
    else
        echo -e "${RED}Error: probe_tech.cfg source missing in script directory.${NC}"
    fi

    if [ -f "$PRINTER_CFG" ]; then
        if ! grep -q "include probe_tech.cfg" "$PRINTER_CFG"; then
            sed -i '1s/^/[include probe_tech.cfg]\n/' "$PRINTER_CFG"
            echo -e "${GREEN}✓ Linked in printer.cfg${NC}"
        else
            echo -e "${SILVER}Link already exists.${NC}"
        fi
    else
        echo -e "${RED}Warning: printer.cfg not found in ${SELECTED_CONF_DIR}${NC}"
    fi

    if [ -f "$MOONRAKER_CONF" ]; then
        # Check if update_manager exists, if not add it
        if ! grep -q "\[update_manager\]" "$MOONRAKER_CONF"; then
            echo -e "\n[update_manager]" >> "$MOONRAKER_CONF"
        fi

        if ! grep -q "\[update_manager client probe_tech\]" "$MOONRAKER_CONF"; then
             cat <<EOF >> "$MOONRAKER_CONF"

[update_manager client probe_tech]
type: web
channel: stable
repo: PravarHegde/probe-tech-control
path: ~/probe-tech-control
EOF
             echo -e "${GREEN}✓ Moonraker Update Manager added${NC}"
        fi

        # --- NEW: UNBLOCK CONNECTIVITY (CORS) ---
        echo -e "${GOLD}Checking Moonraker CORs settings...${NC}"
        # Ensure [authorization] section exists
        if ! grep -q "\[authorization\]" "$MOONRAKER_CONF"; then
            echo -e "\n[authorization]" >> "$MOONRAKER_CONF"
        fi
        
        # Add cors_domains if missing, or add * to it
        if ! grep -q "cors_domains:" "$MOONRAKER_CONF"; then
            echo -e "cors_domains:\n    *\n    *.lan\n    *.local" >> "$MOONRAKER_CONF"
             echo -e "${GREEN}✓ Added CORS domains to moonraker.conf${NC}"
        elif ! grep -E "^\s+\*$" "$MOONRAKER_CONF" > /dev/null; then
            # Use sed to add * under cors_domains:
            sed -i "/cors_domains:/a \    *" "$MOONRAKER_CONF"
            echo -e "${GREEN}✓ Enabled wildcard CORS in moonraker.conf${NC}"
        fi

        # Add trusted_clients if missing
        if ! grep -q "trusted_clients:" "$MOONRAKER_CONF"; then
             cat <<EOF >> "$MOONRAKER_CONF"
trusted_clients:
    127.0.0.1
    10.0.0.0/8
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.168.0.0/16
    FE80::/10
    ::1/128
EOF
             echo -e "${GREEN}✓ Added trusted_clients to moonraker.conf${NC}"
        fi

        # --- NEW: UNBLOCK CONNECTIVITY (UDS) ---
        if ! grep -q "klippy_uds_address:" "$MOONRAKER_CONF"; then
             # Try to find the comms dir
             COMMS_DIR="$(dirname "$SELECTED_CONF_DIR")/comms"
             if [ -d "$COMMS_DIR" ]; then
                 UDS_PATH="${COMMS_DIR}/klippy.sock"
                 # Add klippy_uds_address under [server]
                 sed -i "/\[server\]/a klippy_uds_address: ${UDS_PATH}" "$MOONRAKER_CONF"
                 echo -e "${GREEN}✓ Set klippy_uds_address in moonraker.conf${NC}"
             fi
        fi
    else
        echo -e "${RED}Warning: moonraker.conf not found.${NC}"
    fi

    echo -e "${GOLD}Setting up Service...${NC}"
    # Use SCRIPT_DIR for service template too
    if [ -f "${SCRIPT_DIR}/probe-tech.service" ]; then
         sed "s/{USER}/${USER}/g" "${SCRIPT_DIR}/probe-tech.service" > /tmp/probe-tech.service
         sudo mv /tmp/probe-tech.service "/etc/systemd/system/probe-tech.service"
         sudo systemctl daemon-reload
         sudo systemctl enable probe-tech.service
         sudo systemctl start probe-tech.service
         echo -e "${GREEN}✓ Service Started & Enabled${NC}"
    fi
}

# --- MULTI-INSTANCE CREATOR ---

create_instance() {
    # Takes optional argument name for batch mode
    local batch_name="$1"
    
    CREATED_CONF_DIR=""
    inst_name=""

    if [ -n "$batch_name" ]; then
        inst_name="$batch_name"
    else
        print_box "CREATE NEW PRINTER INSTANCE" "${BLUE}"
        echo -e "${SILVER}This will create a new configuration folder and clone systemd services.${NC}"
        read -p "Enter Instance Name (e.g. printer_2): " raw_name
        # Sanitize spaces -> underscores
        inst_name="${raw_name// /_}"
        echo -e "${SILVER}Sanitized name: ${inst_name}${NC}"
    fi
    
    if [ -z "$inst_name" ]; then echo "Name cannot be empty."; return; fi
    
    # Paths
    INST_DIR="${HOME}/${inst_name}_data"
    CONF_DIR="${INST_DIR}/config"
    LOG_DIR="${INST_DIR}/logs"
    GCODE_DIR="${INST_DIR}/gcodes"
    SYS_DIR="${INST_DIR}/systemd"
    COMMS_DIR="${INST_DIR}/comms"
    
    echo -e "${GOLD}Creating folders in $INST_DIR...${NC}"
    mkdir -p "$CONF_DIR" "$LOG_DIR" "$GCODE_DIR" "$SYS_DIR" "$COMMS_DIR"
    
    # Klipper/Moonraker Envs
    cat <<EOF > "${SYS_DIR}/klipper.env"
KLIPPER_ARGS="${HOME}/klipper/klippy/klippy.py ${CONF_DIR}/printer.cfg -I ${COMMS_DIR}/klippy.serial -l ${LOG_DIR}/klippy.log -a ${COMMS_DIR}/klippy.sock"
EOF

    cat <<EOF > "${SYS_DIR}/moonraker.env"
MOONRAKER_ARGS="${HOME}/moonraker/moonraker/moonraker.py -d ${INST_DIR}"
EOF
    
    # Create Basic Configs
    if [ ! -f "${CONF_DIR}/printer.cfg" ]; then
        echo "[include probe_tech.cfg]" > "${CONF_DIR}/printer.cfg"
        echo -e "${GREEN}✓ Created printer.cfg${NC}"
    fi
    
    if [ ! -f "${CONF_DIR}/moonraker.conf" ]; then
        # AUTO PORT LOGIC
        NEXT_PORT=$(get_next_port)
        cat <<EOF > "${CONF_DIR}/moonraker.conf"
[server]
host: 0.0.0.0
port: ${NEXT_PORT}
klippy_uds_address: ${COMMS_DIR}/klippy.sock

[authorization]
cors_domains:
    *
    *.lan
    *.local
trusted_clients:
    127.0.0.1
    10.0.0.0/8
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.168.0.0/16
    FE80::/10
    ::1/128

[update_manager]

[update_manager client probe_tech]
type: web
channel: stable
repo: PravarHegde/probe-tech-control
path: ~/probe-tech-control
EOF
        echo -e "${GREEN}✓ Created moonraker.conf (Auto-Assigned Port: ${CYAN}${NEXT_PORT}${GREEN})${NC}"
    fi

    echo -e "${GOLD}Creating Systemd Services...${NC}"
    
    # Use quotes for filenames to handle spaces (though we sanitized above)
    cat <<EOF > "/tmp/klipper-${inst_name}.service"
[Unit]
Description=Klipper for ${inst_name}
Documentation=https://www.klipper3d.org/
After=network-online.target
Wants=udev.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
User=${USER}
RemainAfterExit=yes
WorkingDirectory=${HOME}/klipper
EnvironmentFile=${SYS_DIR}/klipper.env
ExecStart=${HOME}/klippy-env/bin/python \$KLIPPER_ARGS
Restart=always
RestartSec=10
EOF
    sudo mv "/tmp/klipper-${inst_name}.service" "/etc/systemd/system/klipper-${inst_name}.service"

    cat <<EOF > "/tmp/moonraker-${inst_name}.service"
[Unit]
Description=Moonraker for ${inst_name}
Documentation=https://moonraker.readthedocs.io/
Requires=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
User=${USER}
SupplementaryGroups=moonraker-admin
RemainAfterExit=yes
WorkingDirectory=${HOME}/moonraker
EnvironmentFile=${SYS_DIR}/moonraker.env
ExecStart=${HOME}/moonraker-env/bin/python \$MOONRAKER_ARGS
Restart=always
RestartSec=10
EOF
    sudo mv "/tmp/moonraker-${inst_name}.service" "/etc/systemd/system/moonraker-${inst_name}.service"

    sudo systemctl daemon-reload
    sudo systemctl enable "klipper-${inst_name}"
    sudo systemctl enable "moonraker-${inst_name}"
    sudo systemctl start "klipper-${inst_name}"
    sudo systemctl start "moonraker-${inst_name}"
    
    echo -e "${GREEN}✓ Instance Created & Services Started!${NC}"
    
    CREATED_CONF_DIR="$CONF_DIR"
    
    # Pause only if interactive
    if [ -z "$batch_name" ]; then
        read -p "Press Enter..."
    fi
}

auto_install_batch() {
    print_box "BATCH MULTI-INSTANCE INSTALLER" "${MAGENTA}"
    echo -e "${SILVER}This tool will set up multiple printers at once.${NC}"
    echo -e "${SILVER}Note: Spaces in names will be converted to underscores (e.g. 'Ender 3' -> 'Ender_3').${NC}"
    echo ""
    read -p "How many new instances do you want to create? " count
    
    if [[ ! "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ]; then
        echo "Invalid number."
        read -p "Press Enter..."
        return
    fi
    
    declare -a names
    echo ""
    echo -e "${GOLD}--- ENTER NAMES ---${NC}"
    echo "Type 'SKIP' at any prompt to stop adding more."
    
    for (( i=1; i<=count; i++ )); do
        read -p "Name for Instance #$i: " name
        if [ "$name" == "SKIP" ] || [ -z "$name" ]; then
            break
        fi
        # Sanitize immediately
        safe_name="${name// /_}"
        names+=("$safe_name")
    done
    
    if [ ${#names[@]} -eq 0 ]; then
        echo "No instances defined."
        return
    fi
    
    echo ""
    echo -e "${BLUE}--- STARTING INSTALLATION ---${NC}"
    
    # 1. Install Binaries Once
    install_klipper
    install_moonraker
    
    # 2. Loop through instances
    for inst in "${names[@]}"; do
        print_box "Installing: $inst" "${GOLD}"
        
        create_instance "$inst"
        
        if [ -n "$CREATED_CONF_DIR" ]; then
             install_probe_tech "$CREATED_CONF_DIR"
             echo -e "${GREEN}✓ $inst Ready${NC}"
        else
             echo -e "${RED}Failed to create $inst${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}=== Batch Installation Complete! ===${NC}"
    read -p "Press Enter to continue..."
}

install_all() {
    echo -e "${BLUE}=== AUTO-INSTALL ALL ===${NC}"
    install_klipper
    install_moonraker
    install_probe_tech
    
    echo -e "${GREEN}Installation Complete!${NC}"
    read -p "Press Enter..."
}

# --- BACKUP & RESTORE ---

backup_config() {
    if select_instance; then
        mkdir -p "$BACKUP_DIR"
        name=$(basename "$SELECTED_INSTANCE") # e.g. printer_data
        ts=$(date +%Y%m%d_%H%M%S)
        tar -czf "${BACKUP_DIR}/${name}_${ts}.tar.gz" -C "$(dirname "$SELECTED_INSTANCE")" "$name"
        echo -e "${GREEN}Backup saved to ${BACKUP_DIR}/${name}_${ts}.tar.gz${NC}"
        read -p "Press Enter..."
    fi
}

restore_backup() {
    echo -e "${GOLD}--- RESTORE BACKUP ---${NC}"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}No backup directory found at $BACKUP_DIR${NC}"
        read -p "Press Enter..."
        return
    fi

    # List files
    mapfile -t backups < <(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null)
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${RED}No backup files found.${NC}"
        read -p "Press Enter..."
        return
    fi
    
    i=1
    for bk in "${backups[@]}"; do
        echo "$i) $(basename "$bk")"
        ((i++))
    done
    
    read -p "Select Backup File: " bsel
    if [[ ! "$bsel" =~ ^[0-9]+$ ]] || [ "$bsel" -lt 1 ] || [ "$bsel" -gt ${#backups[@]} ]; then
        echo "Invalid selection."
        return
    fi
    SELECTED_BACKUP="${backups[$((bsel-1))]}"
    
    echo -e "${BLUE}Where to restore? (Warning: Overwrites)${NC}"
    echo "1) Restore to Original Folder (Auto-detect)"
    echo "2) Cancel"
    read -p "Select: " rsel
    
    if [ "$rsel" == "1" ]; then
        # Restore to HOME
        echo -e "${YELLOW}Restoring to $HOME...${NC}"
        tar -xzf "$SELECTED_BACKUP" -C "$HOME"
        echo -e "${GREEN}Restore Complete.${NC}"
    fi
    read -p "Press Enter..."
}

menu_backup() {
    while true; do
        clear
        print_box "BACKUP & RESTORE" "${BLUE}"
        echo "1) Backup Instance Configuration"
        echo "2) Restore Configuration"
        echo "3) Back to Main Menu"
        echo ""
        read -p "Select: " c
        case $c in
            1) backup_config ;;
            2) restore_backup ;;
            3) return ;;
        esac
    done
}

# --- REMOVAL ACTIONS ---

do_remove_probe() {
    if select_instance; then
        rm -f "${SELECTED_CONF_DIR}/probe_tech.cfg"
        sed -i '/\[include probe_tech.cfg\]/d' "${SELECTED_CONF_DIR}/printer.cfg" 2>/dev/null
        echo -e "${GREEN}Removed config links.${NC}"
    fi
}

do_remove_moonraker() {
    read -p "Uninstall Moonraker? (y/n): " y
    if [ "$y" = "y" ]; then
        sudo systemctl stop moonraker 2>/dev/null
        rm -rf "${HOME}/moonraker"
        echo "Moonraker removed."
    fi
}

do_remove_klipper() {
    read -p "Uninstall Klipper? (y/n): " y
    if [ "$y" = "y" ]; then
        sudo systemctl stop klipper 2>/dev/null
        rm -rf "${HOME}/klipper"
        echo "Klipper removed."
    fi
}

do_remove_all() {
    echo -e "${RED}WARNING: This will remove ALL components!${NC}"
    read -p "Are you sure? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        echo -e "${GOLD}Removing Probe Tech Config...${NC}"
        do_remove_moonraker
        do_remove_klipper
         sudo systemctl stop probe-tech 2>/dev/null
         sudo systemctl disable probe-tech 2>/dev/null
         rm -rf "${HOME}/probe-tech-control"
         echo "Probe Tech Control removed."
         echo -e "${GREEN}Complete Uninstallation Finished.${NC}"
    fi
    read -p "Press Enter..."
}

menu_remove() {
    while true; do
        clear
        print_box "REMOVE COMPONENTS" "${RED}"
        echo "1) Uninstall EVERYTHING (Probe Tech + Moonraker + Klipper)"
        echo "2) Remove Probe Tech Control (Complete)"
        echo "3) Uninstall Moonraker (Destructive)"
        echo "4) Uninstall Klipper (Destructive)"
        echo "5) Back"
        echo ""
        read -p "Select: " c
        case $c in
            1) do_remove_all ;;
            2) do_remove_probe; read -p "Press Enter..." ;;
            3) do_remove_moonraker; read -p "Press Enter..." ;;
            4) do_remove_klipper; read -p "Press Enter..." ;;
            5) return ;;
        esac
    done
}

menu_service() {
    while true; do
        clear
        print_box "SERVICE CONTROL" "${BLUE}"
        echo "1) Start"
        echo "2) Stop"
        echo "3) Restart"
        echo "4) Enable on Boot"
        echo "5) Disable on Boot"
        echo "6) Back"
        echo ""
        read -p "Select: " c
        case $c in
            1) sudo systemctl start probe-tech ;;
            2) sudo systemctl stop probe-tech ;;
            3) sudo systemctl restart probe-tech ;;
            4) sudo systemctl enable probe-tech ;;
            5) sudo systemctl disable probe-tech ;;
            6) return ;;
        esac
    done
}

manual_install_menu() {
    while true; do
        clear
        print_box "MANUAL INSTALLATION" "${BLUE}"
        echo "1) Install Probe Tech Control (Config & Service)"
        echo "2) Install Moonraker"
        echo "3) Install Klipper"
        echo "4) Create New Printer Instance (Multi-Instance)"
        echo "5) Back"
        echo ""
        read -p "Select: " c
        case $c in
            1) install_probe_tech; read -p "Press Enter..." ;;
            2) install_moonraker ;;
            3) install_klipper ;;
            4) create_instance ;;
            5) return ;;
        esac
    done
}

# --- MAIN LOOP ---

while true; do
    clear
    check_status
    
    echo "1) Auto-Install All (Probe Tech Control, Moonraker, Klipper)"
    echo -e "${MAGENTA}2) Batch Multi-Instance (Create Multiple Printers)${NC}"
    echo "3) Manual Installation (Install / Update / Multi-Instance)"
    echo "4) Remove Components"
    echo "5) Backup Configuration"
    echo "6) Service Control"
    echo "7) WiFi Config (WiFi, Hotspot, Info)"
    echo "8) Quit"
    echo ""
    read -p "Select option: " main_c
    
    case $main_c in
        1) install_all ;;
        2) auto_install_batch ;;
        3) manual_install_menu ;;
        4) menu_remove ;;
        5) menu_backup ;;
        6) menu_service ;;
        7) menu_wifi ;;
        8) exit 0 ;;
        *) ;;
    esac
done
