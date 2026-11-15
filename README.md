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

## Recovery Diagnostics

While booted in LineageOS Recovery (`Advanced` -> `Enable ADB`), run on the host:

```bash
curl -sL https://raw.githubusercontent.com/Seuj09/android_device_infinix_X6525/lineage-20/diag.sh | sh
```

## Live Boot Diagnostics

If the phone reaches the boot animation with ADB accessible (`ro.adb.secure=0`), run on the host:

```bash
curl -sL https://raw.githubusercontent.com/Seuj09/android_device_infinix_X6525/lineage-20/live_diag.sh | sh
```

## Thermal HAL Fix (`v20.0-20261115-thermalfix`)

If you already flashed `v20.0-20261115-bootdiag` on slot `_b`, download `vendor.img` from [`v20.0-20261115-thermalfix`](https://github.com/Seuj09/android_device_infinix_X6525/releases/tag/v20.0-20261115-thermalfix) and update only `vendor_b`:

```bash
adb reboot bootloader
fastboot set_active b
fastboot reboot fastboot
fastboot flash vendor_b vendor.img
fastboot reboot
```

Once booted (or if it still loops at the boot animation), run `live_diag.sh` above.

## Slot `_b` Bring-up Debug (`v20.0-20261115-bootdiag`)

From LineageOS Recovery (`Enable ADB`), download `vendor_boot.img`, `vendor.img`, and `system.img` from [`v20.0-20261115-bootdiag`](https://github.com/Seuj09/android_device_infinix_X6525/releases/tag/v20.0-20261115-bootdiag) and flash slot `_b` only (leaving slot `_a` untouched):

```bash
adb reboot bootloader
fastboot set_active b
fastboot flash vendor_boot_b vendor_boot.img
fastboot reboot fastboot
fastboot flash vendor_b vendor.img
fastboot flash system_b system.img
fastboot reboot
```

After normal boot stalls or reboots, boot back into Recovery (`Enable ADB`) and run `diag.sh` above to inspect kernel/init `ramoops` and `/cache/boottrace.txt`.
