#!/bin/sh
adb shell <<'DIAG_EOF'
echo "=== 1. PROPS & CMDLINE & SELINUX ==="
echo "slot=$(getprop ro.boot.slot_suffix) hw=$(getprop ro.hardware) date=$(getprop ro.build.date) enforce=$(getenforce 2>&1)"
cat /proc/cmdline

echo "=== 2. PSTORE ==="
ls -la /sys/fs/pstore
echo "--- unused-ramoops-0 ---"
xxd /sys/fs/pstore/unused-ramoops-0 2>&1
echo "--- pmsg non-adbd lines ---"
strings /sys/fs/pstore/pmsg-ramoops-0 2>/dev/null | grep -vE "adbd|ServiceManager|SELinux: Loaded" | head -n 30

echo "=== 3. PARTITIONS & MAPPER & MOUNTPOINTS ==="
cat /proc/partitions
for p in metadata cache userdata tranfs prodnv blackbox super; do
    b="/dev/block/by-name/$p"
    r=$(readlink -f "$b" 2>/dev/null)
    sz=$(blockdev --getsize64 "$b" 2>&1)
    echo "$p -> $r size=$sz $(ls -ldZ "$r" 2>/dev/null)"
done
echo "--- /dev/block/mapper ---"
ls -la /dev/block/mapper 2>&1
echo "--- dirs ---"
ls -ldZ /metadata /cache /tranfs /blackbox /mnt/vendor 2>&1

echo "=== 4. INSPECT SLOT_B IF MAPPED ==="
if [ -e /dev/block/mapper/system_b ] || [ -e /dev/block/mapper/vendor_b ]; then
    mkdir -p /tmp/mnt_s /tmp/mnt_v
    if [ -e /dev/block/mapper/system_b ]; then
        mount -o ro /dev/block/mapper/system_b /tmp/mnt_s 2>&1
        ls -ld /tmp/mnt_s/metadata /tmp/mnt_s/cache /tmp/mnt_s/tranfs 2>&1
        grep -E "ro.build.date|ro.lineage" /tmp/mnt_s/system/build.prop 2>/dev/null | head -n 6
        umount /tmp/mnt_s 2>/dev/null
    fi
    if [ -e /dev/block/mapper/vendor_b ]; then
        mount -o ro /dev/block/mapper/vendor_b /tmp/mnt_v 2>&1
        grep -E "ro.build.date|ro.vendor.build.date" /tmp/mnt_v/build.prop 2>/dev/null | head -n 4
        grep -v "^#" /tmp/mnt_v/etc/fstab.X6525 2>/dev/null | grep -v "^$"
        umount /tmp/mnt_v 2>/dev/null
    fi
else
    echo "system_b/vendor_b not mapped in Recovery"
fi

echo "=== 5. SUPERBLOCK HEADERS (READ-ONLY: userdata tranfs prodnv blackbox) ==="
for p in userdata tranfs prodnv blackbox; do
    b="/dev/block/by-name/$p"
    echo "--- $p ---"
    for off in 0 1024 5120; do
        echo "off=$off:"
        dd if="$b" bs=1 skip="$off" count=64 2>/dev/null | xxd
    done
done

echo "=== 6. TEST MAKE_F2FS + MOUNT ON /CACHE ONLY (ALREADY ZEROED) ==="
ls -la /system/bin/make_f2fs /system/bin/mke2fs /system/bin/fsck.f2fs 2>&1
cache_sz=$(blockdev --getsize64 /dev/block/by-name/cache 2>/dev/null)
if [ -n "$cache_sz" ]; then
    cache_blks=$((cache_sz / 4096))
    echo "cache_sz=$cache_sz cache_blks=$cache_blks"
    /system/bin/make_f2fs -g android -O project_quota,extra_attr /dev/block/by-name/cache "$cache_blks" 2>&1
    rc1=$?
    echo "make_f2fs(with blks) rc=$rc1"
    if [ "$rc1" -ne 0 ]; then
        /system/bin/make_f2fs -g android -O project_quota,extra_attr /dev/block/by-name/cache 2>&1
        echo "make_f2fs(no blks) rc=$?"
    fi
    mount -t f2fs -o noatime,nosuid,nodev,discard /dev/block/by-name/cache /cache 2>&1
    echo "mount cache rc=$?"
    df -h /cache 2>/dev/null
    dmesg | tail -n 20
    umount /cache 2>/dev/null
fi
DIAG_EOF
