# Kernel-side fix (DKMS) — Huawei MateBook 14s/16s Conexant SN6140

This is an **alternative to the userspace daemon**. Instead of polling the
jack once per second and shelling out to `hda-verb`, the speaker/headphone
routing is handled inside the kernel codec driver and switches instantly on
plug/unplug, with no background process.

## Why a fixup is needed

On these laptops (Conexant **SN6140**, vendor `0x14f11f87`, **PCI SSID
`19e5:3e69`**):

* Internal speaker pin `0x17` ignores its own connection-select and follows
  the value programmed on headphone jack pin `0x16`.
* The headphone jack `0x16` is gated by a **GPIO on the audio function group**
  (`0x01`).
* So the HDA generic parser leaves speakers and headphones cross-wired.

The fix adds an SSID quirk to the in-tree `snd-hda-codec-conexant` driver that
installs an `automute_hook`. On every HP jack event it selects the correct DAC
on `0x16`, toggles the speaker EAPD on `0x17`, and drives the jack-enable GPIO
on `0x01` — the same verb sequence the daemon used, but event-driven.

## What's in here

```
0001-ALSA-hda-conexant-...patch        Upstream-style patch (for the mainline tree)
install.sh / uninstall.sh             DKMS install/remove helpers
snd-hda-codec-conexant-huawei-1.0/    DKMS source (patched driver + headers)
```

The DKMS source is the **Ubuntu `7.0.0-22.22`** copy of
`sound/hda/codecs/conexant.c` plus the internal headers it needs
(`common/`, `generic.h`, `helpers/`), with the fixup applied. DKMS rebuilds it
for the running kernel and installs it into `updates/dkms`, which `depmod`
prefers over the stock module.

## Install

```bash
sudo apt install dkms build-essential linux-headers-$(uname -r)   # if needed
cd kernel-module
sudo bash install.sh
```

Then drop the daemon if you had it:

```bash
systemctl disable --now huawei-soundcard-headphones-monitor
```

DKMS will automatically rebuild the module on future kernel updates.

## Verify

```bash
modinfo snd-hda-codec-conexant | grep filename   # -> .../updates/dkms/...
dkms status snd-hda-codec-conexant-huawei
```

Plug/unplug headphones — output should follow correctly with no daemon running.

## Uninstall

```bash
cd kernel-module
sudo bash uninstall.sh
```

## Notes / caveats

* The DKMS source is pinned to one Ubuntu kernel ABI version. On a **major**
  kernel jump the bundled `conexant.c` may drift from mainline; if the build
  ever fails after an upgrade, refresh the source from your kernel's
  `sound/hda/codecs/` and re-apply `0001-*.patch`.
* The real long-term fix is upstream. The included patch is ready to send to
  `alsa-devel@alsa-project.org` / the `thesofproject/linux` issue #3350 so future
  kernels work out of the box with no DKMS at all.
* Verify the PCI SSID on your unit matches `19e5:3e69`:
  `cat /sys/bus/pci/devices/0000:00:1f.3/subsystem_{vendor,device}`.
  The 14s and 16s can differ; if yours differs, change the `SND_PCI_QUIRK`
  line in `conexant.c` (and the patch) accordingly.
```
