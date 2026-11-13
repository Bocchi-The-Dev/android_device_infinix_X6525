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
