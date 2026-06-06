#!/bin/bash
# Remove the DKMS Conexant sound fix and restore the stock kernel module.
set -e

PKG_NAME="snd-hda-codec-conexant-huawei"
PKG_VERSION="1.0"
DEST_DIR="/usr/src/${PKG_NAME}-${PKG_VERSION}"

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo bash uninstall.sh"
    exit 1
fi

dkms remove -m "$PKG_NAME" -v "$PKG_VERSION" --all 2>/dev/null || true
rm -rf "$DEST_DIR"
depmod -a

echo "Reloading the stock codec driver..."
if modprobe -r snd-hda-codec-conexant 2>/dev/null; then
    modprobe snd-hda-codec-conexant
    echo "Stock module reloaded."
else
    echo "Could not unload the running module (in use). Reboot to apply."
fi

echo "Done."
