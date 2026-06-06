#!/bin/bash
# Install the Huawei MateBook Conexant SN6140 sound fix as a DKMS module.
# This replaces the userspace polling daemon: routing is handled in the
# kernel codec driver and switches instantly on headphone plug/unplug.
set -e

PKG_NAME="snd-hda-codec-conexant-huawei"
PKG_VERSION="1.0"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)/${PKG_NAME}-${PKG_VERSION}"
DEST_DIR="/usr/src/${PKG_NAME}-${PKG_VERSION}"

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo bash install.sh"
    exit 1
fi

for cmd in dkms make gcc; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing '$cmd'. Install build tools first, e.g.:"
        echo "  apt install dkms build-essential linux-headers-\$(uname -r)"
        exit 1
    }
done

if [[ ! -d "/lib/modules/$(uname -r)/build" ]]; then
    echo "Kernel headers for $(uname -r) not found."
    echo "  apt install linux-headers-$(uname -r)"
    exit 1
fi

# Remove any previous copy so we always ship the current source.
dkms remove -m "$PKG_NAME" -v "$PKG_VERSION" --all 2>/dev/null || true
rm -rf "$DEST_DIR"

cp -r "$SRC_DIR" "$DEST_DIR"

dkms add    -m "$PKG_NAME" -v "$PKG_VERSION"
dkms build  -m "$PKG_NAME" -v "$PKG_VERSION"
dkms install -m "$PKG_NAME" -v "$PKG_VERSION" --force

depmod -a

echo
echo "Reloading the codec driver..."
if modprobe -r snd-hda-codec-conexant 2>/dev/null; then
    modprobe snd-hda-codec-conexant
    echo "Module reloaded."
else
    echo "Could not unload the running module (in use). Reboot to apply."
fi

echo
echo "Done. Verify with:"
echo "  modinfo snd-hda-codec-conexant | grep filename   # should point to updates/dkms"
echo "  dkms status $PKG_NAME"
echo
echo "If you previously installed the daemon, disable it:"
echo "  systemctl disable --now huawei-soundcard-headphones-monitor"
