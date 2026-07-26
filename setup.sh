#!/bin/bash
# setup.sh - one-time setup for the MetaGhost GUI.
# Run this once after cloning: ./setup.sh
set -e
cd "$(dirname "$0")"

echo "[*] Checking for exiftool..."
if ! command -v exiftool &> /dev/null; then
    echo "[!] exiftool not found. Attempting install..."
    if [ -f /data/data/com.termux/files/usr/bin/pkg ]; then
        pkg update -y && pkg install exiftool -y
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y libimage-exiftool-perl
    elif command -v brew &> /dev/null; then
        brew install exiftool
    elif command -v pacman &> /dev/null; then
        sudo pacman -S exiftool
    else
        echo "[X] Could not auto-install. Please install 'exiftool' manually, then re-run this script."
        exit 1
    fi
else
    echo "[✔] exiftool is installed."
fi

echo "[*] Creating Python virtual environment..."
python3 -m venv venv
. venv/bin/activate

echo "[*] Installing Python dependencies..."
pip install --quiet -r requirements.txt

echo "[*] Installing HUD (Electron) dependencies..."
cd hud
npm install
cd ..

echo ""
echo "Setup complete."
echo "Run ./start.sh to launch the API and the GUI together."
echo "(Prefer the classic terminal tool? ./MetaGhost.sh still works standalone.)"
