#!/bin/bash
# ============================================================
#   47 OS Bootstrap
#   For a fresh Linux Mint (Cinnamon) install with nothing set up.
#   Installs git, clones the 47 OS repo, and runs the installer.
#
#   Usage:
#     chmod +x setup-47os.sh
#     ./setup-47os.sh
# ============================================================

set -e

CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

echo -e "${CYAN}"
echo "================================================"
echo "  47 OS Bootstrap (fresh Linux Mint)"
echo "================================================"
echo -e "${RESET}"

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Don't run as root. Run as your normal user.${RESET}"
    exit 1
fi

if ! command -v cinnamon &>/dev/null; then
    echo -e "${RED}Cinnamon desktop not found. This is for Linux Mint Cinnamon.${RESET}"
    exit 1
fi

# 1. Install git if missing
if ! command -v git &>/dev/null; then
    echo -e "${CYAN}Installing git...${RESET}"
    sudo apt update
    sudo apt install -y git
else
    echo -e "${GREEN}git already installed.${RESET}"
fi

# 2. Clone the repo (into home dir, skip if already there)
CLONE_DIR="$HOME/47os-rice"
if [ -d "$CLONE_DIR/.git" ]; then
    echo -e "${GREEN}Repo already cloned at $CLONE_DIR — pulling latest.${RESET}"
    cd "$CLONE_DIR"
    git pull
else
    echo -e "${CYAN}Cloning 47 OS repo to $CLONE_DIR...${RESET}"
    git clone https://github.com/phantom47m/47os-rice.git "$CLONE_DIR"
    cd "$CLONE_DIR"
fi

# 3. Run the installer
chmod +x install.sh
echo -e "${CYAN}Launching installer...${RESET}"
echo ""
./install.sh
