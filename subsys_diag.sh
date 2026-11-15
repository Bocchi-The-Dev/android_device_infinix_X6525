#!/bin/sh
adb wait-for-device
if [ "$(adb shell id -u 2>/dev/null | tr -d '\r')" != "0" ]; then
    adb root 2>/dev/null
    sleep 2
    adb wait-for-device
fi

adb shell <<'SUBSYS_EOF'
run_root() {
    if [ "$(id -u)" = "0" ]; then
        sh -c "$1" 2>&1
    elif su 0 id >/dev/null 2>&1; then
        su 0 sh -c "$1" 2>&1
    else
        echo "[needs root - enable Settings -> System -> Developer options -> Rooted debugging]"
        return 1
    fi
}

echo "=== 1. BUILD, SLOT, SELINUX & MOUNTS ==="
echo "uid=$(id -u) date=$(date) slot=$(getprop ro.boot.slot_suffix) enforce=$(getenforce 2>&1) sysfs=$(cat /sys/fs/selinux/enforce 2>&1)"
uptime
echo "sys=$(getprop ro.build.fingerprint)"
echo "vnd=$(getprop ro.vendor.build.fingerprint)"
echo "odm=$(getprop ro.odm.build.fingerprint)"
grep -E " (/|/vendor|/odm|/vendor_dlkm|/product|/system_ext|/mnt/vendor|/data|/metadata) " /proc/mounts 2>&1

echo "=== 2. KERNEL MODULES, FIRMWARE & NVRAM ==="
ls -ld /vendor/lib/modules /vendor_dlkm/lib/modules 2>&1
ls -l /vendor_dlkm/lib/modules/wcn_bsp.ko /vendor_dlkm/lib/modules/sprd_wlan_combo.ko /vendor_dlkm/lib/modules/sprdbt_tty.ko /vendor_dlkm/lib/modules/ims_bridge.ko /vendor_dlkm/lib/modules/seth.ko /vendor_dlkm/lib/modules/sensorhub.ko 2>&1
ls -l /odm/firmware/wcnmodem.bin /odm/firmware/wifi_board_config.ini /odm/firmware/bt_configure_pskey.ini /odm/firmware/bt_configure_rf.ini 2>&1
echo "--- loaded modules (filtered) ---"
if [ -r /proc/modules ]; then
    grep -iE "wcn|wlan|sprd_wlan|sprdbt|gnss|ims|seth|sipc|spipe|audio|cam|sensor|goodix|silead|fps|fortsense|fpc|microarray|aw87" /proc/modules 2>&1
else
    run_root "lsmod 2>&1 | grep -iE 'wcn|wlan|sprd_wlan|sprdbt|gnss|ims|seth|sipc|spipe|audio|cam|sensor|goodix|silead|fps|fortsense|fpc|microarray|aw87'"
fi
echo "--- vendor / mnt/vendor dirs ---"
run_root "ls -la /mnt/vendor /data/vendor/wifi /data/vendor/wifi/wpa /data/vendor/bluetooth 2>&1"

echo "=== 3. DEVICES, RFKILL & NET INTERFACES ==="
ls -l /dev/ttyBT* /dev/spipe* /dev/stty_lte* /dev/slog* /dev/wcn* /dev/seth* /dev/sprd_sensor* 2>/dev/null | head -n 40
for r in /sys/class/rfkill/rfkill*; do
    [ -d "$r" ] && echo "$r: name=$(cat "$r/name" 2>/dev/null) type=$(cat "$r/type" 2>/dev/null) state=$(cat "$r/state" 2>/dev/null) soft=$(cat "$r/soft" 2>/dev/null) hard=$(cat "$r/hard" 2>/dev/null)"
done
ls -la /sys/class/net/ 2>&1
ip -br link 2>/dev/null || ip link show 2>&1 | grep -E "^[0-9]+:|link/"

echo "=== 4. SERVICES, PROPS & HALS ==="
echo "--- init.svc (subsystems) ---"
getprop | grep -iE "^\[init\.svc\.(vendor\.)?(wifi|wpa|hostapd|wcn|connmgr|bluetooth|ril|modem|cp_disk|audio|cam|sensor|finger|goodix|silead|thermal|insmod)" | sort
echo "--- subsystem props ---"
getprop | grep -iE "wifi\.|wlan\.|wcn|bt\.|bluetooth|a2dp|gsm\.|ril\.|persist\.vendor\.radio|vendor\.all\.modules|baseband|ro\.hardware\.audio|cam\.|fingerprint" | sort
echo "--- ps (subsystems) ---"
ps -A -o PID,USER,STAT,ARGS 2>&1 | grep -iE "wifi|wpa|hostapd|wcn|connmgr|bluetooth|ril|uril|modem|cp_disk|audio|cam|sensor|fp|goodix|silead"
echo "--- service list (filtered) ---"
timeout 5 service list 2>&1 | grep -iE "wifi|supplicant|hostapd|bluetooth|radio|ims|telephony|connmgr|wcn|audio|camera|sensor|biometric|fingerprint" | sort
echo "--- lshal (filtered) ---"
run_root "timeout 5 lshal 2>&1 | grep -iE 'wifi|bluetooth|radio|wcn|connmgr|audio|camera|sensors|fingerprint|secure_element|ims'"

echo "=== 5. WIFI STATUS & CONFIG ==="
timeout 5 cmd wifi status 2>&1
timeout 5 dumpsys wifi 2>&1 | grep -iE "Wi-Fi is|curState|WifiController|StaIface|SoftAp|CountryCode|Failure|error|iface|hal|supplicant|mac" | head -n 35
ls -la /vendor/etc/wifi /vendor/etc/wifi/vendor_hals /vendor/overlay/ 2>&1

echo "=== 6. BT / TELEPHONY / AUDIO / CAMERA / SENSORS / FP ==="
echo "--- bluetooth_manager ---"
timeout 5 dumpsys bluetooth_manager 2>&1 | grep -iE "enabled:|state:|address:|name:|AdapterService|Hci|offload|crash|fail|error" | head -n 20
echo "--- telephony ---"
timeout 5 dumpsys telephony.registry 2>&1 | grep -iE "mServiceState|mDataConnectionState|mCallState|mSignalStrength|PhoneId|subId|RegState|ims" | head -n 30
timeout 5 dumpsys isub 2>&1 | grep -iE "Subscription|SubId|SimSlot|CarrierName|Number|Mcc|Mnc" | head -n 20
timeout 5 dumpsys phone 2>&1 | grep -iE "mDataEnabled|isUserDataEnabled|isVolte|isWifiCalling|mSimState|ActiveSubId" | head -n 20
echo "--- audio ---"
timeout 5 dumpsys media.audio_flinger 2>&1 | grep -iE "Hardware status|Standby|thread|whale|a2dp|AudioFlinger|error" | head -n 20
echo "--- camera ---"
timeout 5 dumpsys media.camera 2>&1 | grep -iE "Number of camera|Camera [0-9]|Status:|Provider|legacy|error" | head -n 20
echo "--- sensors ---"
timeout 5 dumpsys sensorservice 2>&1 | head -n 25
echo "--- fingerprint ---"
timeout 5 dumpsys fingerprint 2>&1 | head -n 20

echo "=== 7. DMESG (SUBSYSTEMS) ==="
run_root "dmesg | grep -iE 'wcn|marlin|wlan|sprdwl|sprd_wlan|ttyBT|sprdbt|rfkill|sipc|seth|ims_bridge|modem|insmod|modprobe|avc:|firmware|sensorhub|goodix|silead|whale|aw87' | tail -n 100"

echo "=== 8. LOGCAT & TOMBSTONES ==="
echo "--- logcat crash ---"
timeout 5 logcat -d -b crash -v brief 2>&1 | tail -n 40
echo "--- logcat subsystem errors ---"
timeout 5 logcat -d -b main,system,crash -v brief 2>&1 | grep -iE "wifi|wlan|supplicant|hostapd|wcn|connmgr|wcnd|bluetooth|bt_|ril|telephony|ims|audio.*hal|whale|cameraserver|cameraprovider|sensor|fingerprint|biometric|avc:|linker|dlopen" | grep -iE "^[EFW]/|fail|err|denied|unable|timeout|cannot|missing|stop|crash|die|unsupported" | tail -n 120
echo "--- logcat radio ---"
timeout 5 logcat -d -b radio -v brief 2>&1 | tail -n 80
echo "--- tombstones ---"
run_root "ls -lt /data/tombstones 2>&1 | head -n 10"
SUBSYS_EOF
