#!/bin/bash

# Probe Tech Control - Bootstrap Installer
# Downloads the repo and starts the seamless installer.

REPO_URL="https://github.com/PravarHegde/probe-tech-control.git"
INSTALL_DIR="${HOME}/ptc_installer"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}=== Probe Tech Control Quick Installer ===${NC}"

# 1. Check for Git
if ! command -v git &> /dev/null; then
    echo -e "${BLUE}Git not found. Installing git...${NC}"
    sudo apt-get update && sudo apt-get install -y git
fi

# 2. Clone Repository
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}Updating existing installation in $INSTALL_DIR...${NC}"
    cd "$INSTALL_DIR"
    git pull
else
    echo -e "${GREEN}Cloning Probe Tech Control to $INSTALL_DIR...${NC}"
    # Use shallow clone (--depth=1) to download only the latest version
    # This reduces download size from ~100MB to ~2MB.
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 3. Launch Installer
echo -e "${BLUE}Launching Installer...${NC}"
chmod +x install.sh
# Fix: Redirect /dev/tty to stdin so the installer becomes interactive
# even when the bootstrap script itself is piped to bash.
./install.sh < /dev/tty
