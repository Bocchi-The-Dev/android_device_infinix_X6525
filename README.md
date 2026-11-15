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

Or run the individual commands directly (`diag.sh` source):

```bash
adb shell "ls -la /sys/fs/pstore /metadata /cache /dev/block/by-name/metadata /dev/block/by-name/cache"
adb shell "mount -t f2fs /dev/block/by-name/metadata /metadata; mount -t f2fs /dev/block/by-name/cache /cache; dmesg | grep -iE 'f2fs|ext4|mmcblk0p51|mmcblk0p47|pstore|ramoops' | tail -n 40"
adb shell "xxd -l 64 /dev/block/by-name/metadata"
adb shell "xxd -s 1024 -l 64 /dev/block/by-name/metadata"
adb shell "xxd -s 5120 -l 64 /dev/block/by-name/metadata"
adb shell "xxd -l 64 /dev/block/by-name/cache"
adb shell "xxd -s 1024 -l 64 /dev/block/by-name/cache"
adb shell "xxd -s 5120 -l 64 /dev/block/by-name/cache"
adb shell "ls -la /metadata /metadata/bootstat /metadata/apex /metadata/vold /cache"
adb shell "tail -n 60 /tmp/recovery.log"
```
