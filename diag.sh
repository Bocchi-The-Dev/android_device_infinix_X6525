#!/bin/sh
# Recovery diagnostic helper for Infinix Smart 8 (X6525)
# Run on host PC while phone is booted in LineageOS Recovery with ADB enabled:
#   curl -sL https://raw.githubusercontent.com/Seuj09/android_device_infinix_X6525/lineage-20/diag.sh | sh

echo "=== PSTORE & BLOCK DEVS ==="
adb shell "ls -la /sys/fs/pstore /metadata /cache /dev/block/by-name/metadata /dev/block/by-name/cache"

echo "=== FSTAB & MOUNTS ==="
adb shell "cat /etc/fstab /proc/mounts"

echo "=== MOUNT ATTEMPT & DMESG (F2FS/EXT4/PSTORE) ==="
adb shell "mount -t f2fs /dev/block/by-name/metadata /metadata; mount -t f2fs /dev/block/by-name/cache /cache; dmesg | grep -iE 'f2fs|ext4|mmcblk0p51|mmcblk0p47|pstore|ramoops' | tail -n 40"

echo "=== METADATA HEADER (0, 1024, 5120) ==="
adb shell "xxd -l 64 /dev/block/by-name/metadata"
adb shell "xxd -s 1024 -l 64 /dev/block/by-name/metadata"
adb shell "xxd -s 5120 -l 64 /dev/block/by-name/metadata"

echo "=== CACHE HEADER (0, 1024, 5120) ==="
adb shell "xxd -l 64 /dev/block/by-name/cache"
adb shell "xxd -s 1024 -l 64 /dev/block/by-name/cache"
adb shell "xxd -s 5120 -l 64 /dev/block/by-name/cache"

echo "=== MOUNTED CONTENTS (IF ANY) ==="
adb shell "ls -la /metadata /metadata/bootstat /metadata/apex /metadata/vold /cache"

echo "=== RECOVERY.LOG TAIL ==="
adb shell "tail -n 60 /tmp/recovery.log"
