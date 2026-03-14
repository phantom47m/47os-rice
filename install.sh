#!/bin/bash
set -e

# ============================================================
#   47 OS Rice Installer
#   Applies the full 47 Industries rice to Linux Mint (Cinnamon)
#   Run: git clone <repo> && cd 47os-rice && ./install.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CYAN='\033[1;36m'
WHITE='\033[1;97m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

step=0
total=16

progress() {
    step=$((step + 1))
    echo -e "\n${CYAN}[$step/$total]${WHITE} $1${RESET}"
}

echo -e "${CYAN}"
echo "================================================"
echo "  47 Industries Rice Installer"
echo "  For Linux Mint (Cinnamon Desktop)"
echo "================================================"
echo -e "${RESET}"
echo ""
echo "This will install the full 47OS rice on your system."
echo "It will modify your theme, icons, fonts, panel, dock,"
echo "keybindings, sounds, and more."
echo ""

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Don't run as root. Run as your normal user — sudo will be used when needed.${RESET}"
    exit 1
fi

if ! command -v cinnamon &>/dev/null; then
    echo -e "${RED}Cinnamon desktop not found. This script is for Linux Mint Cinnamon.${RESET}"
    exit 1
fi

read -p "Continue? [y/N] " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && echo "Aborted." && exit 0

# ============================================================
# STEP 1: Install apt packages
# ============================================================
progress "Installing system packages..."
sudo apt update -qq
sudo apt install -y \
    alacritty plank rofi xdotool wmctrl xbindkeys xss-lock \
    brightnessctl pulseaudio-utils \
    inotify-tools devilspie2 macchanger x11-utils \
    python3 jq curl wget git dconf-cli

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 2: Install WhiteSur GTK Theme
# ============================================================
progress "Installing WhiteSur GTK theme..."
if [ -d "$HOME/.themes/WhiteSur-Dark" ]; then
    echo "  WhiteSur-Dark theme already installed, skipping download."
else
    cd /tmp
    rm -rf WhiteSur-gtk-theme
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme
    ./install.sh -c Dark -s standard -l --round
    cd "$SCRIPT_DIR"
    echo -e "  ${GREEN}WhiteSur GTK theme installed.${RESET}"
fi

# Patch the Cinnamon CSS for transparency support
if [ -d "$HOME/.themes/WhiteSur-Dark/cinnamon" ]; then
    cp "$SCRIPT_DIR/assets/theme-patches/cinnamon-opaque.css" "$HOME/.themes/WhiteSur-Dark/cinnamon/" 2>/dev/null || true
    cp "$SCRIPT_DIR/assets/theme-patches/cinnamon-translucent.css" "$HOME/.themes/WhiteSur-Dark/cinnamon/" 2>/dev/null || true
    mkdir -p "$HOME/.themes/WhiteSur-Dark/cinnamon/assets"
    cp "$SCRIPT_DIR/assets/theme-patches/menu-opaque.svg" "$HOME/.themes/WhiteSur-Dark/cinnamon/assets/" 2>/dev/null || true
    cp "$SCRIPT_DIR/assets/theme-patches/menu-translucent.svg" "$HOME/.themes/WhiteSur-Dark/cinnamon/assets/" 2>/dev/null || true
    # Set initial opaque state
    cp "$HOME/.themes/WhiteSur-Dark/cinnamon/cinnamon-opaque.css" "$HOME/.themes/WhiteSur-Dark/cinnamon/cinnamon.css" 2>/dev/null || true
    cp "$HOME/.themes/WhiteSur-Dark/cinnamon/assets/menu-opaque.svg" "$HOME/.themes/WhiteSur-Dark/cinnamon/assets/menu.svg" 2>/dev/null || true
fi

# ============================================================
# STEP 3: Install WhiteSur Icon Theme + Cursors
# ============================================================
progress "Installing WhiteSur icon theme + cursors..."
if [ -d "$HOME/.local/share/icons/WhiteSur-dark" ]; then
    echo "  WhiteSur icons already installed, skipping."
else
    cd /tmp
    rm -rf WhiteSur-icon-theme
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    ./install.sh
    cd "$SCRIPT_DIR"
    echo -e "  ${GREEN}WhiteSur icons installed.${RESET}"
fi

if [ -d "$HOME/.local/share/icons/WhiteSur-cursors" ]; then
    echo "  WhiteSur cursors already installed."
else
    cd /tmp
    rm -rf WhiteSur-cursors
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-cursors.git
    cd WhiteSur-cursors
    ./install.sh
    cd "$SCRIPT_DIR"
    echo -e "  ${GREEN}WhiteSur cursors installed.${RESET}"
fi

# Custom panel icons
mkdir -p "$HOME/.local/share/icons/custom-panel"
cp "$SCRIPT_DIR/assets/icons/"*.svg "$HOME/.local/share/icons/custom-panel/" 2>/dev/null || true

# Oxy-neon cursor
mkdir -p "$HOME/.icons"
cd "$HOME/.icons"
tar xzf "$SCRIPT_DIR/assets/cursors/oxy-neon-large-0.3.tar.gz" 2>/dev/null || true
cd "$SCRIPT_DIR"

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 4: Install fonts
# ============================================================
progress "Installing fonts (SF Pro + Octosquares)..."
mkdir -p "$HOME/.local/share/fonts"
cp "$SCRIPT_DIR/assets/fonts/"* "$HOME/.local/share/fonts/"
fc-cache -f
echo -e "  ${GREEN}$(ls "$SCRIPT_DIR/assets/fonts/" | wc -l) fonts installed.${RESET}"

# ============================================================
# STEP 5: Install sounds
# ============================================================
progress "Installing sound effects..."
mkdir -p "$HOME/.local/share/47industries/sounds"
cp "$SCRIPT_DIR/assets/sounds/drag/"* "$HOME/.local/share/47industries/sounds/"

mkdir -p "$HOME/Documents/47industries/sounds"
cp "$SCRIPT_DIR/assets/sounds/ui/"* "$HOME/Documents/47industries/sounds/"

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 6: Install scripts to ~/.local/bin
# ============================================================
progress "Installing 47 Industries scripts..."
mkdir -p "$HOME/.local/bin"

# Scripts that go to ~/.local/bin
for script in 47sound 47transparency 47glass-inject.sh ghost-mode.sh \
              matrix-47.py saber-drag.sh swoosh-watcher.sh 47sound-inject.sh; do
    cp "$SCRIPT_DIR/scripts/$script" "$HOME/.local/bin/$script"
    chmod +x "$HOME/.local/bin/$script"
done

# Scripts that go to ~/Documents/47industries
mkdir -p "$HOME/Documents/47industries"
for script in launch-terminal.sh toggle-transparency.sh window-close-sound.py \
              window-state-sound.py brightness-tracker.sh volume-tracker.sh \
              close-window.sh maximize-window.sh minimize-window.sh \
              fullscreen-toggle.sh lock-screen.sh powermenu.sh app-search.sh; do
    cp "$SCRIPT_DIR/scripts/$script" "$HOME/Documents/47industries/$script"
    chmod +x "$HOME/Documents/47industries/$script"
done

# Copy assets to ~/Documents/47industries
cp "$SCRIPT_DIR/assets/images/panel-icon.png" "$HOME/Documents/47industries/" 2>/dev/null || true
cp "$SCRIPT_DIR/assets/images/launcher.png" "$HOME/Documents/47industries/" 2>/dev/null || true
cp "$SCRIPT_DIR/assets/images/sequoia-sunrise.jpg" "$HOME/Documents/47industries/" 2>/dev/null || true

# Copy ASCII art
cp "$SCRIPT_DIR/assets/ascii-art.txt" "$HOME/.local/share/47industries/"

# Copy Rofi theme
cp "$SCRIPT_DIR/config/industries.rasi" "$HOME/Documents/47industries/" 2>/dev/null || true

# Ensure ~/.local/bin is in PATH
if ! grep -q 'export PATH="\$HOME/.local/bin:\$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 7: Install Cinnamon applets
# ============================================================
progress "Installing custom Cinnamon applets..."
APPLET_DIR="$HOME/.local/share/cinnamon/applets"
mkdir -p "$APPLET_DIR"

for applet in ghost-mode@custom brightness@custom fake-battery@custom \
              fake-wifi@custom 47sound@custom vpn-toggle@custom; do
    cp -r "$SCRIPT_DIR/applets/$applet" "$APPLET_DIR/"
done

echo -e "  ${GREEN}6 custom applets installed.${RESET}"

# ============================================================
# STEP 8: Install Cinnamon extension (wobbly windows)
# ============================================================
progress "Installing Cinnamon extensions..."
EXT_DIR="$HOME/.local/share/cinnamon/extensions/compiz-windows-effect@hermes83.github.com"
mkdir -p "$EXT_DIR"
cp -r "$SCRIPT_DIR/extensions/"* "$EXT_DIR/"
echo -e "  ${GREEN}Compiz wobbly windows effect installed.${RESET}"

# ============================================================
# STEP 9: Deploy config files
# ============================================================
progress "Deploying configuration files..."

# Alacritty
mkdir -p "$HOME/.config/alacritty"
cp "$SCRIPT_DIR/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/"

# GTK-3.0
mkdir -p "$HOME/.config/gtk-3.0"
cp "$SCRIPT_DIR/config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/"

# Autostart entries
mkdir -p "$HOME/.config/autostart"
for f in "$SCRIPT_DIR/config/autostart/"*.desktop; do
    sed "s|\\\$HOME|$HOME|g" "$f" > "$HOME/.config/autostart/$(basename "$f")"
done

# Xbindkeys
sed "s|\\\$HOME|$HOME|g" "$SCRIPT_DIR/config/xbindkeysrc" > "$HOME/.xbindkeysrc"

# Plank dock launchers
mkdir -p "$HOME/.config/plank/dock1/launchers"
cp "$SCRIPT_DIR/config/plank-launchers/"*.dockitem "$HOME/.config/plank/dock1/launchers/"

# 47 Industries state files
mkdir -p "$HOME/.config/47industries"
echo "muted=false" > "$HOME/.config/47industries/sound-state"
echo "volume=100" >> "$HOME/.config/47industries/sound-state"
echo "50" > "$HOME/.config/47industries/transparency-level"

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 10: Install system-level files (requires sudo)
# ============================================================
progress "Installing system-level assets (requires sudo)..."

# Wallpaper & branding
sudo cp "$SCRIPT_DIR/assets/images/sequoia-sunrise.jpg" /usr/share/backgrounds/
sudo cp "$SCRIPT_DIR/assets/images/47-logo.png" /usr/share/backgrounds/
sudo cp "$SCRIPT_DIR/assets/images/47os-logo.png" /usr/share/pixmaps/

# 47os-logo icon in hicolor theme
for size in 16 22 24 32 48 64 128 256; do
    sudo mkdir -p "/usr/share/icons/hicolor/${size}x${size}/apps"
    sudo cp "$SCRIPT_DIR/assets/images/47os-logo.png" "/usr/share/icons/hicolor/${size}x${size}/apps/"
done
sudo gtk-update-icon-cache /usr/share/icons/hicolor/ 2>/dev/null || true

# Login screen
sudo cp "$SCRIPT_DIR/system/lightdm/slick-greeter.conf" /etc/lightdm/slick-greeter.conf

# Cursor on login screen
sudo mkdir -p /etc/lightdm/lightdm.conf.d
echo -e "[SeatDefaults]\ncursor-theme=WhiteSur-cursors\ncursor-theme-size=24" | \
    sudo tee /etc/lightdm/lightdm.conf.d/51-cursor.conf > /dev/null

# dconf system defaults
sudo mkdir -p /etc/dconf/db/local.d
sudo cp "$SCRIPT_DIR/system/dconf/00-47os-defaults" /etc/dconf/db/local.d/
sudo dconf update 2>/dev/null || true

# GSchema override
sudo cp "$SCRIPT_DIR/system/schemas/zz_47os.gschema.override" /usr/share/glib-2.0/schemas/
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true

# Theme enforcement script
sudo cp "$SCRIPT_DIR/system/47os-force-theme.sh" /usr/local/bin/
sudo chmod +x /usr/local/bin/47os-force-theme.sh

# Autostart for theme enforcement
sudo mkdir -p /etc/xdg/autostart
sudo tee /etc/xdg/autostart/47os-force-theme.desktop > /dev/null <<'THEMEDESKTOP'
[Desktop Entry]
Type=Application
Name=47OS Theme Enforcement
Exec=/usr/local/bin/47os-force-theme.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
THEMEDESKTOP

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 11: Configure Plank dock via dconf
# ============================================================
progress "Configuring Plank dock..."
dconf write /net/launchpad/plank/docks/dock1/alignment "'center'"
dconf write /net/launchpad/plank/docks/dock1/hide-mode "'intelligent'"
dconf write /net/launchpad/plank/docks/dock1/icon-size 52
dconf write /net/launchpad/plank/docks/dock1/items-alignment "'center'"
dconf write /net/launchpad/plank/docks/dock1/lock-items false
dconf write /net/launchpad/plank/docks/dock1/offset 0
dconf write /net/launchpad/plank/docks/dock1/position "'bottom'"
dconf write /net/launchpad/plank/docks/dock1/pressure-reveal false
dconf write /net/launchpad/plank/docks/dock1/theme "'Transparent'"
dconf write /net/launchpad/plank/docks/dock1/zoom-enabled true
dconf write /net/launchpad/plank/docks/dock1/zoom-percent 175
dconf write /net/launchpad/plank/docks/dock1/dock-items "['03-terminal.dockitem', 'brave-browser.dockitem', '04-mail.dockitem', '05-maps.dockitem', '07-camera.dockitem', '06-photos.dockitem', '08-contacts.dockitem', '10-editor.dockitem', '12-calculator.dockitem', '14-clocks.dockitem', '15-drawing.dockitem', '16-scanner.dockitem', '11-music.dockitem', 'nemo.dockitem', '17-settings.dockitem']"
echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 12: Apply theme via gsettings
# ============================================================
progress "Applying theme settings..."

gsettings set org.cinnamon.theme name 'WhiteSur-Dark'
gsettings set org.cinnamon.desktop.interface gtk-theme 'WhiteSur-Dark'
gsettings set org.cinnamon.desktop.interface icon-theme 'WhiteSur-dark'
gsettings set org.cinnamon.desktop.interface cursor-theme 'WhiteSur-cursors'
gsettings set org.cinnamon.desktop.interface font-name 'SF Pro Display 10'
gsettings set org.cinnamon.desktop.wm.preferences theme 'WhiteSur-Dark'
gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'SF Pro Display Medium 10'
gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/sequoia-sunrise.jpg'
gsettings set org.cinnamon.desktop.background picture-options 'zoom'

gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors' 2>/dev/null || true

gsettings set org.cinnamon panels-enabled "['1:0:top']"
gsettings set org.cinnamon panels-height "['1:28']"
gsettings set org.cinnamon panel-scale-text-icons true
gsettings set org.cinnamon app-menu-icon-name '47os-logo'

gsettings set org.nemo.desktop computer-icon-visible false
gsettings set org.nemo.desktop home-icon-visible false
gsettings set org.nemo.desktop network-icon-visible false
gsettings set org.nemo.desktop trash-icon-visible false
gsettings set org.nemo.desktop volumes-visible false

# Desktop effects
gsettings set org.cinnamon desktop-effects true
gsettings set org.cinnamon desktop-effects-close 'scale'
gsettings set org.cinnamon desktop-effects-map 'scale'
gsettings set org.cinnamon desktop-effects-minimize 'traditional'
gsettings set org.cinnamon desktop-effects-on-dialogs true
gsettings set org.cinnamon desktop-effects-on-menus true

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 13: Set custom keybindings
# ============================================================
progress "Setting custom keybindings..."

KEYBINDING_DIR="/org/cinnamon/desktop/keybindings/custom-keybindings"
CUSTOM_KEYS=()

add_keybinding() {
    local idx=$1 name=$2 cmd=$3 binding=$4
    local path="${KEYBINDING_DIR}/custom${idx}/"
    dconf write "${path}name" "'$name'"
    dconf write "${path}command" "'$cmd'"
    dconf write "${path}binding" "['$binding']"
    CUSTOM_KEYS+=("'${path}'")
}

add_keybinding 0 "Launch Terminal" "$HOME/Documents/47industries/launch-terminal.sh" "<Primary><Alt>t"
add_keybinding 1 "Volume Up" "$HOME/Documents/47industries/volume-tracker.sh up" "F10"
add_keybinding 2 "Volume Down" "$HOME/Documents/47industries/volume-tracker.sh down" "F9"
add_keybinding 3 "Volume Mute" "$HOME/Documents/47industries/volume-tracker.sh mute" "F8"
add_keybinding 4 "Brightness Down" "$HOME/Documents/47industries/brightness-tracker.sh down" "F2"
add_keybinding 5 "Brightness Up" "$HOME/Documents/47industries/brightness-tracker.sh up" "F3"
add_keybinding 6 "Toggle Transparency" "$HOME/Documents/47industries/toggle-transparency.sh" "<Primary><Shift>t"
add_keybinding 7 "Close Window" "$HOME/Documents/47industries/close-window.sh" "<Primary>q"
add_keybinding 8 "Toggle Fullscreen" "$HOME/Documents/47industries/fullscreen-toggle.sh" "<Primary><Shift>f"
add_keybinding 9 "Lock Screen" "$HOME/Documents/47industries/lock-screen.sh" "<Primary><Shift>l"
add_keybinding 10 "Maximize Window" "$HOME/Documents/47industries/maximize-window.sh" "<Primary><Shift>Up"
add_keybinding 11 "Minimize Window" "$HOME/Documents/47industries/minimize-window.sh" "<Primary><Shift>Down"

IFS=','
dconf write /org/cinnamon/desktop/keybindings/custom-list "[${CUSTOM_KEYS[*]}]"
unset IFS

echo -e "  ${GREEN}12 keybindings configured.${RESET}"

# ============================================================
# STEP 14: Set panel applets
# ============================================================
progress "Configuring panel applets..."

gsettings set org.cinnamon enabled-applets "['panel1:left:0:menu@cinnamon.org:0', 'panel1:right:0:systray@cinnamon.org:3', 'panel1:right:1:notifications@cinnamon.org:5', 'panel1:right:2:keyboard@cinnamon.org:8', 'panel1:right:3:ghost-mode@custom:18', 'panel1:right:4:brightness@custom:20', 'panel1:right:5:fake-wifi@custom:17', 'panel1:right:6:sound@cinnamon.org:11', 'panel1:right:7:fake-battery@custom:16', 'panel1:right:8:calendar@cinnamon.org:13']"

# Configure the app menu icon
mkdir -p "$HOME/.config/cinnamon/spices/menu@cinnamon.org"
cat > "$HOME/.config/cinnamon/spices/menu@cinnamon.org/0.json" <<MENUJSON
{
    "menu-icon-custom": {"type": "checkbox", "default": true, "value": true},
    "menu-icon": {"type": "iconfilechooser", "default": "", "value": "$HOME/Documents/47industries/panel-icon.png"},
    "menu-icon-size": {"type": "spinbutton", "default": 28, "value": 32}
}
MENUJSON

# Enable wobbly windows
gsettings set org.cinnamon enabled-extensions "['compiz-windows-effect@hermes83.github.com']"

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 15: Add splash screen to .bashrc
# ============================================================
progress "Setting up terminal splash screen..."

if ! grep -q "matrix-47.py" "$HOME/.bashrc"; then
    echo 'python3 ~/.local/bin/matrix-47.py' >> "$HOME/.bashrc"
    echo "  Added matrix-47.py splash to .bashrc"
else
    echo "  Splash screen already in .bashrc"
fi

echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# STEP 16: Copy browser extension
# ============================================================
progress "Copying browser extension..."
mkdir -p "$HOME/Documents/47industries/47-glass-extension"
cp -r "$SCRIPT_DIR/browser-extension/"* "$HOME/Documents/47industries/47-glass-extension/" 2>/dev/null || true
echo -e "  ${GREEN}Done.${RESET}"

# ============================================================
# DONE
# ============================================================
echo ""
echo -e "${CYAN}================================================${RESET}"
echo -e "${GREEN}  47 Industries rice installed successfully!${RESET}"
echo -e "${CYAN}================================================${RESET}"
echo ""
echo -e "${WHITE}  What was installed:${RESET}"
echo "  - WhiteSur Dark theme + icons + cursors"
echo "  - SF Pro Display fonts"
echo "  - Alacritty terminal (neon cyan theme)"
echo "  - Plank dock (macOS-style, bottom, zoom 175%)"
echo "  - 6 custom Cinnamon panel applets"
echo "  - Wobbly windows effect"
echo "  - 47 Sound system (sounds on all actions)"
echo "  - Transparency toggle system (Ctrl+Shift+T)"
echo "  - Ghost Mode (VPN + MAC spoof + encrypted DNS)"
echo "  - Matrix-style terminal splash screen"
echo "  - 12 custom keybindings"
echo "  - Custom login screen"
echo "  - Window drag/close/state sounds"
echo "  - File download/delete swoosh sounds"
echo ""
echo -e "${WHITE}  To finish:${RESET}"
echo "  1. Log out and log back in (or Ctrl+Alt+Esc to restart Cinnamon)"
echo "  2. Browser extension: load ~/Documents/47industries/47-glass-extension/"
echo "     as unpacked extension in Brave/Chrome (chrome://extensions)"
echo ""
echo -e "${WHITE}  Key shortcuts:${RESET}"
echo "  Ctrl+Alt+T     - Open terminal (with sound)"
echo "  Ctrl+Shift+T   - Toggle transparency"
echo "  Ctrl+Q         - Close window (with sound)"
echo "  Ctrl+Shift+F   - Toggle fullscreen"
echo "  Ctrl+Shift+L   - Lock screen"
echo "  F2/F3          - Brightness down/up"
echo "  F8/F9/F10      - Mute/Vol down/Vol up"
echo ""
echo -e "${CYAN}  47 Industries${RESET}"
echo ""
