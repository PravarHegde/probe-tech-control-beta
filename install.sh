#!/bin/bash

# Probe Tech Control Advanced Installer and Manager
# Version 8.1: Full Suite (UI Tweaks: Remove All Option)

# --- VARIABLES ---
HOME_DIR="${HOME}"
USER=$(whoami)
SERVICE_TEMPLATE="probe-tech.service"
BACKUP_DIR="${HOME}/probe_tech_backups"

# Colors (Blue, Silver/White, Gold)
BLUE='\033[1;34m'
SILVER='\033[1;37m'
GOLD='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

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
    if ! select_instance; then return; fi
    
    PROBE_CFG="${SELECTED_CONF_DIR}/probe_tech.cfg"
    PRINTER_CFG="${SELECTED_CONF_DIR}/printer.cfg"
    MOONRAKER_CONF="${SELECTED_CONF_DIR}/moonraker.conf"
    
    echo -e "${GOLD}Configuring instance at: $SELECTED_CONF_DIR${NC}"

    if [ -f "probe_tech.cfg" ]; then
        cp probe_tech.cfg "$PROBE_CFG"
        echo -e "${GREEN}✓ probe_tech.cfg copied${NC}"
    else
        echo -e "${RED}Error: probe_tech.cfg source missing.${NC}"
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
    else
        echo -e "${RED}Warning: moonraker.conf not found in ${SELECTED_CONF_DIR}${NC}"
    fi

    echo -e "${GOLD}Setting up Service...${NC}"
    if [ -f "probe-tech.service" ]; then
         sed "s/{USER}/${USER}/g" probe-tech.service > /tmp/probe-tech.service
         sudo mv /tmp/probe-tech.service "/etc/systemd/system/probe-tech.service"
         sudo systemctl daemon-reload
         sudo systemctl enable probe-tech.service
         sudo systemctl start probe-tech.service
         echo -e "${GREEN}✓ Service Started & Enabled${NC}"
    fi
}

# --- MULTI-INSTANCE CREATOR ---

create_instance() {
    print_box "CREATE NEW PRINTER INSTANCE" "${BLUE}"
    echo -e "${SILVER}This will create a new config folder and clone systemd services.${NC}"
    read -p "Enter Instance Name (e.g. printer_2): " inst_name
    
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
        cat <<EOF > "${CONF_DIR}/moonraker.conf"
[server]
host: 0.0.0.0
# Automatic port increment logic would be better, but fixed manual change is safer for now.
port: 7126
EOF
        echo -e "${GREEN}✓ Created moonraker.conf (Port 7126 set)${NC}"
    fi

    echo -e "${GOLD}Creating Systemd Services (Requires Sudo)...${NC}"
    
    # Create Klipper Service
    cat <<EOF > /tmp/klipper-${inst_name}.service
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
    sudo mv /tmp/klipper-${inst_name}.service /etc/systemd/system/klipper-${inst_name}.service

    # Create Moonraker Service
    cat <<EOF > /tmp/moonraker-${inst_name}.service
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
    sudo mv /tmp/moonraker-${inst_name}.service /etc/systemd/system/moonraker-${inst_name}.service

    # Reload and Enable
    sudo systemctl daemon-reload
    sudo systemctl enable klipper-${inst_name}
    sudo systemctl enable moonraker-${inst_name}
    sudo systemctl start klipper-${inst_name}
    sudo systemctl start moonraker-${inst_name}
    
    echo -e "${GREEN}✓ Instance Created & Services Started!${NC}"
    read -p "Press Enter..."
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
        # For remove all, we might want to clean all instances, but for now let's just do base components + specific instance config if requested. 
        # Actually standard practice is remove the big services and maybe the config files.
        do_remove_moonraker
        do_remove_klipper
        # Optional: remove probe tech service
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
        echo "2) Remove Probe Tech Config (Single Instance)"
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
    echo "2) Manual Installation (Install / Update / Multi-Instance)"
    echo "3) Remove Components"
    echo "4) Backup Configuration"
    echo "5) Service Control"
    echo "6) WiFi Config (WiFi, Hotspot, Info)"
    echo "7) Quit"
    echo ""
    read -p "Select option: " main_c
    
    case $main_c in
        1) install_all ;;
        2) manual_install_menu ;;
        3) menu_remove ;;
        4) menu_backup ;;
        5) menu_service ;;
        6) menu_wifi ;;
        7) exit 0 ;;
        *) ;;
    esac
done
