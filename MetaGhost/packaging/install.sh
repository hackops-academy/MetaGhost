#!/bin/bash
# install.sh - installs MetaGhost as a desktop application on Kali Linux
# (or any Debian-based distro with a freedesktop-compliant menu).
#
# Installs per-user (no root needed for the app itself - only for
# missing system packages, via sudo, if you approve it):
#   ~/.local/share/metaghost            app files, venv, node_modules
#   ~/.local/bin/metaghost               launcher command
#   ~/.local/share/applications/         MetaGhost.desktop menu entry
#   ~/.local/share/icons/hicolor/        app icon (scalable SVG)
#
# Run from inside the extracted MetaGhost folder:
#   ./packaging/install.sh
set -euo pipefail

PACKAGING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$PACKAGING_DIR/.." && pwd)"
INSTALL_DIR="$HOME/.local/share/metaghost"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
ICON_BASE="$HOME/.local/share/icons/hicolor"
PIXMAPS_DIR="$HOME/.local/share/pixmaps"

echo "=========================================="
echo "  MetaGhost installer - HackOps Academy"
echo "=========================================="
echo

# ---------------------------------------------------------------------
# 1. Check / install system dependencies
# ---------------------------------------------------------------------
missing=()
command -v python3 >/dev/null 2>&1 || missing+=("python3")
python3 -c "import venv" >/dev/null 2>&1 || missing+=("python3-venv")
command -v pip3 >/dev/null 2>&1 || missing+=("python3-pip")
command -v node >/dev/null 2>&1 || missing+=("nodejs")
command -v npm >/dev/null 2>&1 || missing+=("npm")
command -v rsync >/dev/null 2>&1 || missing+=("rsync")
command -v exiftool >/dev/null 2>&1 || missing+=("libimage-exiftool-perl")

if [ "${#missing[@]}" -gt 0 ]; then
    echo "[*] Missing system packages: ${missing[*]}"
    if command -v apt-get >/dev/null 2>&1; then
        read -rp "    Install them now with sudo apt-get? [Y/n] " ans
        if [[ "$ans" =~ ^[Nn]$ ]]; then
            echo "Aborting - install the packages above manually and re-run."
            exit 1
        fi
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    else
        echo "apt-get not found - install these packages manually: ${missing[*]}"
        echo "(On Termux: pkg install python nodejs exiftool)"
        echo "(On macOS:  brew install python node exiftool)"
        exit 1
    fi
fi
echo "[*] System dependencies OK."
echo

# ---------------------------------------------------------------------
# 2. Copy application files into the per-user install directory
# ---------------------------------------------------------------------
echo "[*] Installing app files to $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
rsync -a --delete \
    --exclude 'packaging' \
    --exclude '.git' \
    --exclude 'venv' \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude 'hud/node_modules' \
    --exclude 'hud/dist' \
    --exclude 'reports/*.html' \
    --exclude 'clean_output/*' \
    --exclude 'backups/*' \
    --exclude 'history.json' \
    "$REPO_ROOT"/ "$INSTALL_DIR"/

# ---------------------------------------------------------------------
# 3. Python venv + deps
# ---------------------------------------------------------------------
echo "[*] Creating Python virtual environment..."
python3 -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --quiet --upgrade pip
echo "[*] Installing Python dependencies..."
"$INSTALL_DIR/venv/bin/pip" install --quiet -r "$INSTALL_DIR/requirements.txt"

# ---------------------------------------------------------------------
# 4. HUD (Electron) deps
# ---------------------------------------------------------------------
echo "[*] Installing HUD dependencies (this downloads Electron, may take a bit)..."
(cd "$INSTALL_DIR/hud" && npm install --no-audit --no-fund)

# ---------------------------------------------------------------------
# 5. Icon (scalable SVG - MetaGhost ships no rasterized PNG set)
# ---------------------------------------------------------------------
echo "[*] Installing icon..."
mkdir -p "$ICON_BASE/scalable/apps"
cp "$REPO_ROOT/assets/metaghost-logo.svg" "$ICON_BASE/scalable/apps/metaghost.svg"
mkdir -p "$PIXMAPS_DIR"
cp "$REPO_ROOT/assets/metaghost-logo.svg" "$PIXMAPS_DIR/metaghost.svg"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------
# 6. Launcher command
# ---------------------------------------------------------------------
echo "[*] Installing launcher to $BIN_DIR/metaghost ..."
mkdir -p "$BIN_DIR"
cp "$PACKAGING_DIR/bin/metaghost" "$BIN_DIR/metaghost"
chmod +x "$BIN_DIR/metaghost"

# ---------------------------------------------------------------------
# 7. Desktop menu entry
# ---------------------------------------------------------------------
echo "[*] Installing menu entry..."
mkdir -p "$APPS_DIR"
sed "s|__LAUNCHER__|$BIN_DIR/metaghost|" "$PACKAGING_DIR/metaghost.desktop" > "$APPS_DIR/metaghost.desktop"
chmod +x "$APPS_DIR/metaghost.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
fi

echo
echo "=========================================="
echo "  MetaGhost installed."
echo "=========================================="
echo
echo "Launch it from your Applications menu (search 'MetaGhost'),"
echo "or from any terminal with:  metaghost"
echo

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    echo "NOTE: $BIN_DIR is not on your PATH yet, so the 'metaghost' command"
    echo "won't work from a terminal until you add it. The Applications menu"
    echo "entry will work regardless. To fix the terminal command, add this"
    echo "to ~/.bashrc or ~/.zshrc:"
    echo
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
fi

echo "Reports, cleaned files, and backups are stored under:"
echo "  $INSTALL_DIR/reports"
echo "  $INSTALL_DIR/clean_output"
echo "  $INSTALL_DIR/backups"
echo
echo "To uninstall later: ./packaging/uninstall.sh"
