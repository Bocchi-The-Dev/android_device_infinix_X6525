# prebuilts

Populate this directory from the images that match the `super` you dumped:

```
prebuilts/
  kernel                 Image from boot.img (mkbootimg/magiskboot output "kernel")
  dtb/dtb.dtb            DTB blob from vendor_boot.img (output "dtb")
  dtbo.img               stock dtbo partition image (copied as-is)
  modules/*.ko           vendor ramdisk lib/modules from vendor_boot.img
  recovery_modules/*.ko  the subset device.mk copies into the recovery root
  firmware/*             vendor ramdisk lib/firmware from vendor_boot.img
  avb/*.avbpubkey        AOSP GSI AVB keys
```

`BoardConfig.mk` consumes them via:

```make
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilts/kernel
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilts/dtb
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilts/dtbo.img
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(DEVICE_PATH)/prebuilts/modules/*.ko)
```

`device.mk` copies `recovery_modules/` and `firmware/` into the recovery and
vendor ramdisks explicitly.

`BOARD_PREBUILT_DTBIMAGE_DIR` must contain one or more `*.dtb` files; the build
concatenates them into `dtb.img`. The stock `vendor_boot.img` already contains a
single concatenated FDT blob, so one file named `dtb.dtb` is correct.

`BOARD_INCLUDE_DTB_IN_BOOTIMG := true` is mandatory next to
`BOARD_PREBUILT_DTBIMAGE_DIR`: Android 15's `board_config.mk` hard-errors
otherwise. With a header-v4 image the DTB lands in the `vendor_boot` dtb section.

`BOARD_INCLUDE_DTB_IN_BOOTIMG := true` is mandatory alongside it: Android 15's
`board_config.mk` errors out with "BOARD_PREBUILT_DTBIMAGE_DIR with
'BOARD_INCLUDE_DTB_IN_BOOTIMG != true' is not supported". With a header-v4
boot image the DTB still lands in the vendor_boot dtb section.

## Extracting them

```sh
magiskboot unpack vendor_boot.img     # -> dtb, vendor_ramdisk/ramdisk.cpio
mkdir -p ramdisk && cd ramdisk
cpio -id --no-absolute-filenames < ../vendor_ramdisk/ramdisk.cpio
# lib/modules/*.ko -> prebuilts/modules/, lib/firmware/* -> prebuilts/firmware/
```

All of `modules/*.ko` must match the `prebuilts/kernel` you ship. The stock
modules are built for the stock kernel; if you drop in a custom kernel, use the
module set that was built with it.

Do not commit these binaries to a public repo unless you are sure you have the
right to redistribute them; most people keep them out of git and regenerate them
from their own device.
