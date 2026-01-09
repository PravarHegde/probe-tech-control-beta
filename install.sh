#!/bin/bash

# Probe Tech Control Installer
# A simple interactive installer similar to KIAUH

# Paths
CONFIG_DIR="${HOME}/printer_data/config"
MOONRAKER_CONF="${CONFIG_DIR}/moonraker.conf"
PRINTER_CFG="${CONFIG_DIR}/printer.cfg"
PROBE_TECH_CFG="${CONFIG_DIR}/probe_tech.cfg"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper Functions
print_header() {
    clear
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${CYAN}           PROBE TECH CONTROL INSTALLER          ${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo ""
}

check_status() {
    if [ -f "$PROBE_TECH_CFG" ]; then
        echo -e "Config Status: ${GREEN}Installed${NC}"
    else
        echo -e "Config Status: ${RED}Not Installed${NC}"
    fi
    
    if grep -q "\[update_manager client probe_tech\]" "$MOONRAKER_CONF" 2>/dev/null; then
         echo -e "Moonraker:     ${GREEN}Configured${NC}"
    else
         echo -e "Moonraker:     ${RED}Not Configured${NC}"
    fi
    echo ""
}

install_config() {
    echo -e "${YELLOW}Installing Probe Tech Configuration...${NC}"
    if [ ! -f "probe_tech.cfg" ]; then
        echo -e "${RED}Error: probe_tech.cfg not found in current directory!${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    cp probe_tech.cfg "$PROBE_TECH_CFG"
    echo -e "${GREEN}✓ probe_tech.cfg copied to $CONFIG_DIR${NC}"

    if grep -q "include probe_tech.cfg" "$PRINTER_CFG"; then
        echo -e "${YELLOW}! probe_tech.cfg already included in printer.cfg${NC}"
    else
        sed -i '1s/^/[include probe_tech.cfg]\n/' "$PRINTER_CFG"
        echo -e "${GREEN}✓ Added [include probe_tech.cfg] to printer.cfg${NC}"
    fi

    # Update Moonraker
    if grep -q "\[update_manager client probe_tech\]" "$MOONRAKER_CONF"; then
        echo -e "${YELLOW}! Moonraker already configured${NC}"
    else
        cat <<EOF >> "$MOONRAKER_CONF"

[update_manager client probe_tech]
type: web
channel: stable
repo: PravarHegde/probe-tech-control
path: ~/probe-tech-control
EOF
        echo -e "${GREEN}✓ Added Update Manager entry to moonraker.conf${NC}"
    fi

    echo ""
    echo -e "${GREEN}Installation Complete!${NC}"
    read -p "Press Enter to continue..."
}

uninstall_config() {
    echo -e "${YELLOW}Uninstalling Probe Tech Configuration...${NC}"
    
    if [ -f "$PROBE_TECH_CFG" ]; then
        rm "$PROBE_TECH_CFG"
        echo -e "${GREEN}✓ Removed probe_tech.cfg${NC}"
    fi

    # Remove include from printer.cfg (rough match)
    sed -i '/\[include probe_tech.cfg\]/d' "$PRINTER_CFG"
    echo -e "${GREEN}✓ Removed include from printer.cfg${NC}"

    # Note: Removing from moonraker.conf via script is risky without a proper parser.
    # We will just warn the user.
    echo -e "${YELLOW}! Please manually remove the [update_manager client probe_tech] block from moonraker.conf${NC}"
    
    read -p "Press Enter to continue..."
}

# Main Loop
while true; do
    print_header
    check_status
    
    echo "1) Install / Update Probe Tech Control"
    echo "2) Uninstall Configuration"
    echo "Q) Quit"
    echo ""
    read -p "Select an option: " choice

    case $choice in
        1)
            install_config
            ;;
        2)
            uninstall_config
            ;;
        q|Q)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            ;;
    esac
done
