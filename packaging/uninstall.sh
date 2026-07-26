#!/bin/bash
# uninstall.sh - removes everything install.sh created.
set -uo pipefail

INSTALL_DIR="$HOME/.local/share/metaghost"
RUN_DIR="$HOME/.local/share/metaghost-run"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
ICON_BASE="$HOME/.local/share/icons/hicolor"
PIXMAPS_DIR="$HOME/.local/share/pixmaps"

echo "This removes MetaGhost and everything under $INSTALL_DIR,"
echo "including any reports, cleaned files, and backups stored there."
read -rp "Continue? [y/N] " ans
if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

rm -rf "$INSTALL_DIR"
rm -rf "$RUN_DIR"
rm -f "$BIN_DIR/metaghost"
rm -f "$APPS_DIR/metaghost.desktop"
rm -f "$ICON_BASE/scalable/apps/metaghost.svg"
rm -f "$PIXMAPS_DIR/metaghost.svg"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

echo "MetaGhost uninstalled."
