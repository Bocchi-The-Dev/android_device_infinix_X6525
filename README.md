# Android device tree for Infinix Smart 8 (X6525)

LineageOS 20 (Android 13) device tree for the Infinix Smart 8 X6525
(Unisoc T606 / UMS9230 / qogirl6).

Build target:

```
lineage_X6525-userdebug
```

See the top-level `README.md` and `docs/BRINGUP.md` in this repo for the full
walkthrough. The short version:

```bash
tools/unpack-super.sh super.img ~/dump
python3 tools/gen-blob-list.py ~/dump -o device/infinix/X6525/proprietary-files.txt
device/infinix/X6525/extract-files.sh ~/dump
# install prebuilts (kernel/dtb/dtbo), then:
source build/envsetup.sh && breakfast X6525 && mka bacon
```

## Beta Release (`v20.0-20261116-beta`)

Built cleanly from `lineage-20` with all bring-up debug helpers (`WITH_ADB_INSECURE`, `ignore_loglevel`, `init.X6525.diag.rc`, `boottrace.sh`) removed.

### Assets (from [`v20.0-20261116-beta`](https://github.com/Seuj09/android_device_infinix_X6525/releases/tag/v20.0-20261116-beta))
- `lineage-20.0-20261116-UNOFFICIAL-X6525.zip` (`.sha256sum`) — Full LineageOS 20 OTA package
- `boot.img`, `dtbo.img`, `vendor_boot.img` — Clean boot/recovery/DTBO images (`vbmeta*` omitted; assumes verification is already disabled)

### Installing / Updating

From LineageOS Recovery (`Apply Update` -> `Apply from ADB`):

```bash
adb sideload lineage-20.0-20261116-UNOFFICIAL-X6525.zip
```

> **Note for A/B slot `_a` stock backup**: `adb sideload` writes the OTA payload to the **inactive** slot (so if you are currently on slot `_b`, sideloading writes to slot `_a`). If you want to keep slot `_a` untouched as a stock backup, install only `vendor_boot_b`, `boot_b`, `dtbo_b`, and the extracted partition images onto `*_b` via `fastbootd` instead.

If you are switching from another ROM or stock, wipe data in Recovery (`Factory reset` -> `Format data/factory reset`) after/before sideloading.

## Subsystem & Runtime Diagnostics

Once booted into LineageOS (with USB debugging and `Settings -> System -> Developer options -> Rooted debugging` enabled):

```bash
curl -sL https://raw.githubusercontent.com/Seuj09/android_device_infinix_X6525/lineage-20/subsys_diag.sh | sh
curl -sL https://raw.githubusercontent.com/Seuj09/android_device_infinix_X6525/lineage-20/audit_diag.sh | sh
```
