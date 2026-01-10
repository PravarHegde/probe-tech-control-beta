#!/bin/bash

# Probe Tech Control Advanced Installer and Manager
# Version 5: Professional Edition (Box UI, WiFi, Auto-Detect)

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

# Improved Instance Detection: Looks for directories containing printer.cfg
get_instances() {
    find "${HOME}" -maxdepth 2 -name "printer.cfg" -print0 | xargs -0 -I {} dirname {} | sort | uniq
}

# Shows a list of valid config directories to pick from
select_instance() {
    echo -e "${GOLD}Select Klipper Instance (Config Folder):${NC}"
    
    # Capture output of get_instances into array
    mapfile -t instances < <(get_instances)
    
    if [ ${#instances[@]} -eq 0 ]; then
        echo -e "${RED}No Klipper configurations found! (Checked for printer.cfg in ~/*)${NC}"
        # Fallback to creating a default directory if none exist?
        echo -e "${SILVER}Creating default: ~/printer_data/config${NC}"
        mkdir -p "${HOME}/printer_data/config"
        instances=("${HOME}/printer_data/config")
    fi

    i=1
    for inst in "${instances[@]}"; do
        # Show parent folder name usually (e.g. printer_data/config -> printer_data)
        parent=$(basename "$(dirname "$inst")")
        name=$(basename "$inst")
        echo "$i) $parent/$name"
        ((i++))
    done
    
    read -p "Enter number: " sel
    
    if [[ ! "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt ${#instances[@]} ]; then
        echo -e "${RED}Invalid selection.${NC}"
        return 1
    fi
    
    # Return selected path
    SELECTED_CONF_DIR="${instances[$((sel-1))]}"
    # SELECTED_INSTANCE is the parent of the config dir, e.g. ~/printer_data
    SELECTED_INSTANCE="$(dirname "$SELECTED_CONF_DIR")"
    
    echo -e "Selected Config: ${GREEN}${SELECTED_CONF_DIR}${NC}"
    return 0
}

check_status() {
    print_box "PROBE TECH CONTROL - ADVANCED MANAGER" "${BLUE}"
    
    # Check Probe Tech Config (Global check, or check specifically for 'default' instance if single?)
    # We'll check if ANY printer.cfg has our include, roughly.
    if grep -r "include probe_tech.cfg" "${HOME}" --include="printer.cfg" >/dev/null 2>&1; then
         echo -e "Probe Tech Control: ${GREEN}Installed${NC}"
    else
         echo -e "Probe Tech Control: ${SILVER}Not Detected${NC}"
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
    nmcli -p device show wlan0 2>/dev/null | grep -E "IP4.ADDRESS|GENERAL.CONNECTION"
    echo ""
}

menu_wifi() {
    while true; do
        clear
        print_box "WIFI CONFIGURATION" "${GOLD}"
        wifi_status
        echo "1) Connect to WiFi Network"
        echo "2) Show Network Info (LAN/Current)"
        echo "3) Back to Main Menu"
        echo ""
        read -p "Select: " c
        case $c in
            1) 
                echo -e "${SILVER}Scanning networks...${NC}"
                nmcli device wifi list
                read -p "Enter SSID Name: " ssid
                read -s -p "Enter Password: " pass
                echo ""
                echo "Connecting..."
                sudo nmcli device wifi connect "$ssid" password "$pass"
                read -p "Press Enter..."
                ;;
            2)
                ip addr show
                read -p "Press Enter..."
                ;;
            3) return ;;
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
    # Just in case, ensure user is in tty group
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
    # 1. Select Instance
    if ! select_instance; then return; fi
    
    PROBE_CFG="${SELECTED_CONF_DIR}/probe_tech.cfg"
    PRINTER_CFG="${SELECTED_CONF_DIR}/printer.cfg"
    MOONRAKER_CONF="${SELECTED_CONF_DIR}/moonraker.conf"
    
    echo -e "${GOLD}Configuring instance at: $SELECTED_CONF_DIR${NC}"

    # 2. Config Copy
    if [ -f "probe_tech.cfg" ]; then
        cp probe_tech.cfg "$PROBE_CFG"
        echo -e "${GREEN}✓ probe_tech.cfg copied${NC}"
    else
        echo -e "${RED}Error: probe_tech.cfg source missing.${NC}"
    fi

    # 3. Printer.cfg Link
    if [ -f "$PRINTER_CFG" ]; then
        if ! grep -q "include probe_tech.cfg" "$PRINTER_CFG"; then
            # Insert at top
            sed -i '1s/^/[include probe_tech.cfg]\n/' "$PRINTER_CFG"
            echo -e "${GREEN}✓ Linked in printer.cfg${NC}"
        else
            echo -e "${SILVER}Link already exists.${NC}"
        fi
    else
        echo -e "${RED}Warning: printer.cfg not found in ${SELECTED_CONF_DIR}${NC}"
    fi

    # 4. Moonraker Update Manager
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

    # 5. Service
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

install_all() {
    echo -e "${BLUE}=== AUTO-INSTALL ALL ===${NC}"
    echo -e "Installing Klipper, Moonraker, and Probe Tech..."
    
    install_klipper
    install_moonraker
    
    # For auto-install, if we can find a config dir, use first one automatically?
    # Or just prompt once. Prompting is safer.
    install_probe_tech
    
    echo -e "${GREEN}Installation Complete!${NC}"
    read -p "Press Enter..."
}

# --- SUBMENUS ---

menu_remove() {
    while true; do
        clear
        print_box "REMOVE COMPONENTS" "${RED}"
        echo "1) Remove Probe Tech Config"
        echo "2) Uninstall Moonraker (Destructive)"
        echo "3) Uninstall Klipper (Destructive)"
        echo "4) Back"
        echo ""
        read -p "Select: " c
        case $c in
            1) 
                if select_instance; then
                    rm -f "${SELECTED_CONF_DIR}/probe_tech.cfg"
                    sed -i '/\[include probe_tech.cfg\]/d' "${SELECTED_CONF_DIR}/printer.cfg" 2>/dev/null
                    echo -e "${GREEN}Removed config links.${NC}"
                    read -p "Press Enter..."
                fi
                ;;
            2) 
                read -p "Uninstall Moonraker? (y/n): " y
                if [ "$y" = "y" ]; then
                    sudo systemctl stop moonraker 2>/dev/null
                    rm -rf "${HOME}/moonraker"
                    echo "Moonraker removed."
                fi
                ;;
            3)
                read -p "Uninstall Klipper? (y/n): " y
                if [ "$y" = "y" ]; then
                    sudo systemctl stop klipper 2>/dev/null
                    rm -rf "${HOME}/klipper"
                    echo "Klipper removed."
                fi
                ;;
            4) return ;;
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

manual_install_menu() {
    while true; do
        clear
        print_box "MANUAL INSTALLATION" "${BLUE}"
        echo "1) Install Probe Tech Control (Config & Service)"
        echo "2) Install Moonraker"
        echo "3) Install Klipper"
        echo "4) Back"
        echo ""
        read -p "Select: " c
        case $c in
            1) install_probe_tech; read -p "Press Enter..." ;;
            2) install_moonraker ;;
            3) install_klipper ;;
            4) return ;;
        esac
    done
}

# --- MAIN LOOP ---

while true; do
    clear
    check_status
    
    echo "1) Auto-Install All (Probe Tech Control, Moonraker, Klipper)"
    echo "2) Manual Installation (Install / Update)"
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
        4) backup_config ;;
        5) menu_service ;;
        6) menu_wifi ;;
        7) exit 0 ;;
        *) ;;
    esac
done
