#!/bin/sh
adb shell <<'DIAG_EOF'
echo "=== 1. UDC, USB, WATCHDOG, PRINTK ==="
echo "udc: $(ls -la /sys/class/udc 2>&1)"
echo "usb_devs: $(ls -d /sys/bus/platform/devices/*usb* /sys/devices/platform/soc/soc:*/*usb* 2>/dev/null)"
echo "sys.usb.controller=$(getprop sys.usb.controller) state=$(getprop sys.usb.state) cfg=$(getprop sys.usb.config)"
echo "watchdog: $(ls -la /dev/watchdog* 2>&1)"
echo "printk: $(cat /proc/sys/kernel/printk 2>&1)"
echo "ramoops_params: $(grep . /sys/module/ramoops/parameters/* 2>/dev/null | tr '\n' ' ')"

echo "=== 2. LSMOD & DMESG (WDT/USB/PSTORE/MMC) ==="
lsmod | tr -s ' ' | cut -d' ' -f1 | grep -E "wdt|musb|usb|phy|typec|sprd_power|7sreset"
dmesg | grep -iE "wdt|watchdog|musb|udc|pstore|ramoops|sprd-sysdump" | tail -n 30

echo "=== 3. MISC BCB & METADATA/CACHE/USERDATA HEAD ==="
echo "--- misc ---"
dd if=/dev/block/by-name/misc bs=1 count=128 2>/dev/null | xxd
for p in metadata cache userdata; do
    b="/dev/block/by-name/$p"
    echo "--- $p (1024..1056) ---"
    dd if="$b" bs=1 skip=1024 count=32 2>/dev/null | xxd
done

echo "=== 4. PSTORE ==="
ls -la /sys/fs/pstore
xxd /sys/fs/pstore/unused-ramoops-0 2>&1
strings /sys/fs/pstore/pmsg-ramoops-0 2>/dev/null | grep -vE "adbd|ServiceManager|SELinux: Loaded" | tail -n 15

echo "=== 5. TEST CACHE MOUNT ==="
mount -t f2fs /dev/block/by-name/cache /cache 2>&1
echo "mount_cache_rc=$? ls=$(ls -la /cache 2>&1)"
umount /cache 2>/dev/null
DIAG_EOF
