#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# APEX updates
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# Virtual A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# API level
PRODUCT_SHIPPING_API_LEVEL := 33

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Boot control HAL
#
# The stock vendor image already ships
# vendor/bin/hw/vendor.sprd.hardware.boot@1.2-service, which registers
# android.hardware.boot@1.2::IBootControl/default and knows the Unisoc
# bootloader/misc format. Do NOT install AOSP's
# android.hardware.boot@1.2-service here: that would be a second service for the
# same HAL instance and whichever starts first wins, with the AOSP one using
# the wrong bootloader protocol.
#
# The .recovery variant is the passthrough implementation library, not a
# service. Normal system operation talks to the stock service over HIDL, but no
# vendor service runs in recovery, so update_engine_sideload's
# IBootControl::getService() falls back to dlopen()ing
# android.hardware.boot@1.0-impl-1.2.so. Soong installs the recovery variant to
# recovery/root/system/lib64/hw, which is on recovery's linker search path.
# Without it, sideloading an OTA fails when update_engine tries to set the
# active boot slot.
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl.recovery

# OTA / virtual A/B
PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

# fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# Health HAL
#
# The stock vendor image ships android.hardware.health-service.example together
# with its init script and VINTF fragment (listed in proprietary-files.txt).
# That binary is built against Unisoc's healthd configuration, so keep it and do
# not install android.hardware.health@2.1-service next to it: both would
# register android.hardware.health@2.1::IHealth/default. If the stock binary is
# ever dropped from the blob list, replace this comment with
#
#     PRODUCT_PACKAGES += \
#         android.hardware.health@2.1-impl \
#         android.hardware.health@2.1-service

# First-stage fstab for vendor_boot. Named after ro.hardware, which the
# bootloader reports as "X6525" on this device.
#
# Use TARGET_COPY_OUT_VENDOR_RAMDISK ("vendor_ramdisk"), not
# TARGET_VENDOR_RAMDISK_OUT: product makefiles are parsed before envsetup.mk
# defines the _OUT variables, so _OUT would expand to an empty string here.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.X6525:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.X6525 \
    $(LOCAL_PATH)/rootdir/etc/init.recovery.X6525.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.X6525.rc

# Product characteristics
PRODUCT_CHARACTERISTICS := default

# Prebuilt Helix kernel omits CONFIG_AUDIT and sets CONFIG_IP6_NF_NAT/CONFIG_SYSVIPC,
# which conflicts with FCM level 6 kernel config requirements during OTA/VINTF check.
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Inherit the proprietary files
$(call inherit-product, vendor/infinix/X6525/X6525-vendor.mk)
