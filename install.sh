#!/usr/bin/env bash
set -e

echo "☕ Plasma Caffeine Widget Installer"
echo "=================================="
echo
echo "This installer sets up a lightweight Caffeine replacement for KDE Plasma:"
echo "  • systemd-native (Wayland compatible)"
echo "  • No Python, no tray, no X11"
echo "  • Uses Plasma Command Output widget"
echo "  • Nerd Font icons (recommended)"
echo

# --- Locate script directory ---
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Detect distribution ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot detect Linux distribution."
    exit 1
fi

# --- Install optional dependencies ---
echo "📦 Checking optional dependencies for $DISTRO..."
case "$DISTRO" in
    arch|manjaro|endeavouros)
        sudo pacman -Syu --needed --noconfirm \
            plasma-workspace || true

        # Nerd Font (icons)
        if ! pacman -Q ttf-jetbrains-mono-nerd &>/dev/null; then
            echo "🖋️ Installing Nerd Font (JetBrains Mono)..."
            sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd || true
        fi
        ;;
    ubuntu|debian|neon|pop)
        sudo apt update
        sudo apt install -y \
            plasma-workspace fonts-noto-color-emoji || true
        ;;
    fedora)
        sudo dnf install -y \
            plasma-workspace google-noto-emoji-fonts || true
        ;;
    opensuse*|suse)
        sudo zypper install -y \
            plasma5-workspace google-noto-emoji-fonts || true
        ;;
    *)
        echo "⚠️ Unknown distribution: $DISTRO"
        echo "Please ensure KDE Plasma and a Nerd Font are installed."
        ;;
esac

# --- Prepare install paths ---
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# --- Install scripts ---
echo "📁 Installing scripts to $INSTALL_DIR..."
install -m 755 "$DIR/caffeine-status.sh" "$INSTALL_DIR/caffeine-status.sh"
install -m 755 "$DIR/caffeine-toggle.sh" "$INSTALL_DIR/caffeine-toggle.sh"

# --- Final instructions ---
echo
echo "✅ Installation complete!"
echo
echo "---------------------------------------"
echo "Plasma setup:"
echo "1️⃣ Install the Command Output widget:"
echo "   https://github.com/Zren/plasma-applet-commandoutput"
echo
echo "2️⃣ Add it to your panel."
echo
echo "3️⃣ Command:"
echo "   $INSTALL_DIR/caffeine-status.sh"
echo
echo "4️⃣ Update interval:"
echo "   0 seconds"
echo
echo "5️⃣ Click action:"
echo "   $INSTALL_DIR/caffeine-toggle.sh"
echo "---------------------------------------"
echo
echo "ℹ️ If icons are not visible, set the widget font to a Nerd Font."
echo
echo "Optional Plasma restart:"
echo "   kquitapp6 plasmashell && kstart6 plasmashell"
echo
