# Android device tree for Infinix Smart 8 (X6525)

LineageOS 22.2 (Android 15) device tree for the Infinix Smart 8 X6525
(Unisoc T606 / UMS9230 / qogirl6).

The vendor side of this device is still the stock Android 13 vendor, so the
VINTF files keep `target-level="7"` and `vendor-ndk 33`; the platform supplies
that level for existing vendor images.

Build target:

```
lineage_X6525-userdebug
```

## Building

Put this tree at `device/infinix/X6525` in a `lineage-22.2` checkout, then use
`build.sh`. It never calls `sudo`, so it runs in an unprivileged container;
missing host tools are reported rather than installed.

```bash
# once: pull the blobs from the stock phone (adb root) or from a dump path
device/infinix/X6525/build.sh --extract adb

# every build
device/infinix/X6525/build.sh
```

The checkout is found from the script's own location, or from
`ANDROID_BUILD_TOP`, or `/work` when that is the checkout. Override with
`--top /work/lineage-22.2`. Other flags:

```text
-j N             parallel jobs (default: nproc)
-v userdebug     build variant: user, userdebug (default), eng
--sync           repo sync -c first (needs repo on PATH)
--clean          m clobber before building
--ccache-size    ccache limit, default 50G
```

The package lands in `out/target/product/X6525/lineage-22.2-*.zip`, and the
build log in `out/build-<timestamp>.log`. Manually, the same thing is:

```bash
source build/envsetup.sh && lunch lineage_X6525-userdebug && mka bacon
```

Prebuilts (kernel, dtb, dtbo, modules, firmware) are committed; see
`prebuilts/README.md`.

SELinux is still permissive during bring-up; `device/infinix/X6525/sepolicy/`
documents how to collect denials and switch to enforcing.

## Previous release (`v20.0-20261116-beta`, LineageOS 20)

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
curl -sL https://raw.githubusercontent.com/Seuj09/android_device_infinix_X6525/lineage-22.2/subsys_diag.sh | sh
curl -sL https://raw.githubusercontent.com/Seuj09/android_device_infinix_X6525/lineage-22.2/audit_diag.sh | sh
```
