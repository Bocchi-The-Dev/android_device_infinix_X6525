#!/system/bin/sh
# Load second-stage touch/gesture modules for X6525 recovery after ueventd starts
# so firmware loading (/vendor/firmware/) is available and any unused panel driver
# failure is non-fatal (unlike first_stage_init modules.load.recovery).

load_panel()
{
    insmod /vendor/lib/modules/gpio.ko
    insmod /lib/modules/gpio-sprd.ko
    insmod /vendor/lib/modules/adaptive-ts.ko
    insmod /vendor/lib/modules/omnivision_td4160.ko
    insmod /vendor/lib/modules/focaltech_ft8756_spi_ts.ko
    insmod /vendor/lib/modules/nvt_nt36xxx_spi_ts.ko
    insmod /vendor/lib/modules/tran_gesture.ko
}

load_panel
setprop modules.loaded 1
exit 0
