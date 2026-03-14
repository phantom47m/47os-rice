#!/bin/bash
# ============================================
# 47 OS Rice Installer
# Transforms Linux Mint Cinnamon into 47 OS
# By 47 Industries — 47industries.com
# ============================================

set -e

CYAN='\033[0;36m'
WHITE='\033[1;37m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_banner() {
    echo -e "${CYAN}"
    echo "  ██╗  ██╗███████╗     ██████╗ ███████╗"
    echo "  ██║  ██║╚════██║    ██╔═══██╗██╔════╝"
    echo "  ███████║    ██╔╝    ██║   ██║███████╗"
    echo "  ╚════██║   ██╔╝     ██║   ██║╚════██║"
    echo "       ██║   ██╔╝     ╚██████╔╝███████║"
    echo "       ╚═╝   ╚═╝      ╚═════╝ ╚══════╝"
    echo -e "${WHITE}  Genesis Edition — Rice Installer${NC}"
    echo ""
}

step() {
    echo -e "${CYAN}[*]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

fail() {
    echo -e "${RED}[✗]${NC} $1"
}

# ============================================
# PRE-FLIGHT CHECKS
# ============================================

print_banner

if [ "$EUID" -eq 0 ]; then
    fail "Don't run as root. Run as your normal user — the script will use sudo when needed."
    exit 1
fi

# Check we're on Linux Mint Cinnamon
if ! command -v cinnamon &>/dev/null; then
    fail "Cinnamon desktop not found. This script is designed for Linux Mint Cinnamon."
    exit 1
fi

echo -e "${WHITE}This will transform your Linux Mint into 47 OS.${NC}"
echo "It will install themes, icons, fonts, wallpapers, and configurations."
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# ============================================
# INSTALL DEPENDENCIES
# ============================================

step "Installing dependencies..."
sudo apt update -qq
sudo apt install -y -qq alacritty plank python3 dconf-cli 2>/dev/null
success "Dependencies installed"

# ============================================
# THEMES
# ============================================

step "Installing WhiteSur themes..."
sudo cp -a "$SCRIPT_DIR/themes/WhiteSur-Dark" /usr/share/themes/
sudo cp -a "$SCRIPT_DIR/themes/WhiteSur-Dark-solid" /usr/share/themes/
success "GTK themes installed"

# ============================================
# ICONS
# ============================================

step "Installing WhiteSur icons..."
sudo cp -a "$SCRIPT_DIR/icons/WhiteSur" /usr/share/icons/
sudo cp -a "$SCRIPT_DIR/icons/WhiteSur-dark" /usr/share/icons/
sudo cp -a "$SCRIPT_DIR/icons/WhiteSur-cursors" /usr/share/icons/
success "Icon themes installed"

# ============================================
# FONTS
# ============================================

step "Installing SF Pro Display fonts..."
sudo mkdir -p /usr/share/fonts/truetype/sf-pro
sudo cp -a "$SCRIPT_DIR/fonts/sf-pro/"* /usr/share/fonts/truetype/sf-pro/
sudo fc-cache -f
success "Fonts installed"

# ============================================
# WALLPAPERS
# ============================================

step "Installing wallpapers..."
sudo cp "$SCRIPT_DIR/wallpapers/sequoia-sunrise.jpg" /usr/share/backgrounds/
sudo cp "$SCRIPT_DIR/wallpapers/47-logo.png" /usr/share/backgrounds/
# Override default Mint wallpaper
sudo ln -sf /usr/share/backgrounds/sequoia-sunrise.jpg /usr/share/backgrounds/linuxmint/default_background.jpg
success "Wallpapers installed"

# ============================================
# 47 OS BRANDING
# ============================================

step "Installing 47 OS branding..."
sudo cp "$SCRIPT_DIR/branding/47os-logo.png" /usr/share/pixmaps/
sudo cp "$SCRIPT_DIR/branding/47os-logo.png" /usr/share/pixmaps/eggs.png
sudo cp "$SCRIPT_DIR/branding/47os-logo.png" /usr/share/pixmaps/install-system.png

# Install at all icon sizes
for size in 16 22 24 32 48 64 128 256; do
    sudo mkdir -p "/usr/share/icons/hicolor/${size}x${size}/apps"
    if [ -f "$SCRIPT_DIR/branding/hicolor/${size}x${size}/apps/47os-logo.png" ]; then
        sudo cp "$SCRIPT_DIR/branding/hicolor/${size}x${size}/apps/47os-logo.png" "/usr/share/icons/hicolor/${size}x${size}/apps/"
    fi
done
sudo mkdir -p /usr/share/icons/hicolor/scalable/apps
sudo cp "$SCRIPT_DIR/branding/47os-logo.png" /usr/share/icons/hicolor/scalable/apps/

# Update icon cache
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null
success "Branding installed"

# ============================================
# GSETTINGS & DCONF OVERRIDES
# ============================================

step "Configuring system overrides..."
sudo cp "$SCRIPT_DIR/config/zz_47os.gschema.override" /usr/share/glib-2.0/schemas/
sudo cp "$SCRIPT_DIR/config/mint-artwork.gschema.override.47os" /usr/share/glib-2.0/schemas/mint-artwork.gschema.override
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

# Dconf system database
sudo mkdir -p /etc/dconf/profile /etc/dconf/db/local.d
echo -e "user-db:user\nsystem-db:local" | sudo tee /etc/dconf/profile/user > /dev/null
if [ -f "$SCRIPT_DIR/config/00-47os-defaults" ]; then
    sudo cp "$SCRIPT_DIR/config/00-47os-defaults" /etc/dconf/db/local.d/
fi
sudo dconf update 2>/dev/null
success "System overrides configured"

# ============================================
# CINNAMON MENU APPLET
# ============================================

step "Configuring Cinnamon menu..."
sudo cp "$SCRIPT_DIR/config/menu-settings-override.json" /usr/share/cinnamon/applets/menu@cinnamon.org/settings-override.json
success "Menu configured with 47 logo"

# ============================================
# LIGHTDM / LOGIN SCREEN
# ============================================

step "Configuring login screen..."
# Remove autologin for installed systems
sudo tee /etc/lightdm/lightdm.conf > /dev/null << 'LIGHTDM'
[Seat:*]
user-session=cinnamon
greeter-session=slick-greeter
LIGHTDM

sudo cp "$SCRIPT_DIR/config/slick-greeter.conf" /etc/lightdm/
success "Login screen configured"

# ============================================
# THEME ENFORCEMENT SCRIPT
# ============================================

step "Installing theme enforcement..."
sudo cp "$SCRIPT_DIR/scripts/47os-force-theme.sh" /usr/local/bin/
sudo chmod +x /usr/local/bin/47os-force-theme.sh
sudo cp "$SCRIPT_DIR/config/47os-force-theme.desktop" /etc/xdg/autostart/
success "Theme enforcement installed"

# ============================================
# ALACRITTY TERMINAL
# ============================================

step "Configuring Alacritty terminal..."
mkdir -p "$HOME/.config/alacritty"
cp "$SCRIPT_DIR/config/alacritty.toml" "$HOME/.config/alacritty/"
success "Alacritty configured"

# ============================================
# TERMINAL SPLASH (MATRIX 47)
# ============================================

step "Installing 47 Industries terminal splash..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/47industries"
cp "$SCRIPT_DIR/scripts/matrix-47.py" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/matrix-47.py"
cp "$SCRIPT_DIR/branding/ascii-art.txt" "$HOME/.local/share/47industries/"

# Add to bashrc if not already there
if ! grep -q "matrix-47.py" "$HOME/.bashrc" 2>/dev/null; then
    echo '' >> "$HOME/.bashrc"
    echo '# 47 Industries Terminal Splash' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo 'python3 ~/.local/bin/matrix-47.py' >> "$HOME/.bashrc"
fi
success "Terminal splash installed"

# ============================================
# SOUNDS
# ============================================

step "Installing 47 Industries sounds..."
mkdir -p "$HOME/.local/share/47industries/sounds"
cp "$SCRIPT_DIR/sounds/"*.wav "$HOME/.local/share/47industries/" 2>/dev/null
cp -a "$SCRIPT_DIR/sounds/"* "$HOME/.local/share/47industries/sounds/" 2>/dev/null
success "Sounds installed"

# ============================================
# 47 INDUSTRIES SCRIPTS
# ============================================

step "Installing 47 Industries scripts..."
mkdir -p "$HOME/Documents/47industries"
cp "$SCRIPT_DIR/scripts/47industries/"* "$HOME/Documents/47industries/" 2>/dev/null
chmod +x "$HOME/Documents/47industries/"*.sh 2>/dev/null
success "Scripts installed"

# ============================================
# PLANK DOCK
# ============================================

step "Configuring Plank dock..."
mkdir -p "$HOME/.config/plank/dock1/launchers"
cp -a "$SCRIPT_DIR/plank/dock1/"* "$HOME/.config/plank/dock1/" 2>/dev/null

# Add Plank to autostart
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/plank.desktop" << 'PLANK'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
PLANK
success "Plank dock configured"

# ============================================
# CUSTOM CINNAMON APPLETS
# ============================================

step "Installing custom Cinnamon applets..."
mkdir -p "$HOME/.local/share/cinnamon/applets"
cp -a "$SCRIPT_DIR/applets/"*@custom "$HOME/.local/share/cinnamon/applets/" 2>/dev/null
success "Custom applets installed"

# ============================================
# APPLY SETTINGS NOW
# ============================================

step "Applying theme settings..."

# Cinnamon
gsettings set org.cinnamon.theme name 'WhiteSur-Dark'
gsettings set org.cinnamon.desktop.interface gtk-theme 'WhiteSur-Dark'
gsettings set org.cinnamon.desktop.interface icon-theme 'WhiteSur-dark'
gsettings set org.cinnamon.desktop.interface cursor-theme 'WhiteSur-cursors'
gsettings set org.cinnamon.desktop.interface font-name 'SF Pro Display 10'
gsettings set org.cinnamon.desktop.wm.preferences theme 'WhiteSur-Dark'
gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'SF Pro Display Medium 10'
gsettings set org.cinnamon.desktop.background picture-uri "file:///usr/share/backgrounds/sequoia-sunrise.jpg"
gsettings set org.cinnamon.desktop.background picture-options 'zoom'

# Panel
gsettings set org.cinnamon panels-enabled "['1:0:top']"
gsettings set org.cinnamon panels-height "['1:28']"

# Desktop icons off
gsettings set org.nemo.desktop computer-icon-visible false
gsettings set org.nemo.desktop home-icon-visible false
gsettings set org.nemo.desktop network-icon-visible false
gsettings set org.nemo.desktop trash-icon-visible false
gsettings set org.nemo.desktop volumes-visible false

# Menu icon
gsettings set org.cinnamon app-menu-icon-name '47os-logo'

# GNOME fallbacks
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors' 2>/dev/null

success "Theme settings applied"

# ============================================
# DONE
# ============================================

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}  47 OS installation complete!${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${WHITE}Please log out and back in for all changes to take effect.${NC}"
echo -e "${WHITE}For the full experience, restart your computer.${NC}"
echo ""
echo -e "${CYAN}  47 Industries — 47industries.com${NC}"
echo ""
