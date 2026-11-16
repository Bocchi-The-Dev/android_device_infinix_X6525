#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Build LineageOS 22.2 for the Infinix Smart 8 (X6525).
#
# This script never calls sudo and never touches anything outside the source
# tree and $HOME, so it works in an unprivileged build container. Missing host
# tools are reported, not installed: add them to the image, not at build time.
#
# Typical use, from the source tree:
#
#   device/infinix/X6525/build.sh                 # incremental build
#   device/infinix/X6525/build.sh --extract adb   # pull blobs from the stock phone first
#   device/infinix/X6525/build.sh --sync          # repo sync, then build
#   device/infinix/X6525/build.sh -j 32 -v user   # 32 jobs, user build
#
# The LineageOS checkout is found in this order: --top, $ANDROID_BUILD_TOP,
# three directories above this script (<top>/device/infinix/X6525/build.sh),
# then /work if it is the checkout itself.

set -euo pipefail

DEVICE="X6525"
VARIANT="userdebug"
JOBS="$(nproc --all 2>/dev/null || echo 4)"
TOP="${ANDROID_BUILD_TOP:-}"
SYNC=0
EXTRACT=""
CLEAN=0
CCACHE_SIZE="50G"

usage() {
    sed -n '5,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

die() {
    printf 'build: %s\n' "$*" >&2
    exit 1
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -t|--top) TOP="${2:?--top needs a path}"; shift 2 ;;
        -j|--jobs) JOBS="${2:?--jobs needs a number}"; shift 2 ;;
        -v|--variant) VARIANT="${2:?--variant needs user, userdebug or eng}"; shift 2 ;;
        --sync) SYNC=1; shift ;;
        --extract) EXTRACT="${2:?--extract needs 'adb' or a dump path}"; shift 2 ;;
        --clean) CLEAN=1; shift ;;
        --ccache-size) CCACHE_SIZE="${2:?--ccache-size needs a size}"; shift 2 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
done

case "$VARIANT" in
    user|userdebug|eng) ;;
    *) die "unknown variant '$VARIANT' (user, userdebug or eng)" ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$TOP" ]; then
    case "$SCRIPT_DIR" in
        */device/infinix/X6525) TOP="$(cd "$SCRIPT_DIR/../../.." && pwd)" ;;
    esac
fi
# Last resort: a checkout that lives at /work itself.
if [ -z "$TOP" ] && [ -f /work/build/envsetup.sh ]; then
    TOP=/work
fi
[ -n "$TOP" ] || die "cannot locate the LineageOS tree; pass --top /work/lineage-22.2"
resolved_top="$(cd -- "$TOP" && pwd)" || die "no such directory: $TOP"
TOP="$resolved_top"

[ -f "$TOP/build/envsetup.sh" ] ||
    die "$TOP is not a LineageOS tree (no build/envsetup.sh)"
[ -d "$TOP/device/infinix/$DEVICE" ] ||
    die "$TOP/device/infinix/$DEVICE is missing; clone the device tree there"

# ---------------------------------------------------------------------------
# Host tools: report, never install (no sudo in this container).
# ---------------------------------------------------------------------------
missing=()
for tool in bash git python3 java ccache curl unzip; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ "$SYNC" = 1 ]; then
    command -v repo >/dev/null 2>&1 || missing+=("repo")
fi
if [ "${#missing[@]}" -gt 0 ]; then
    printf 'build: missing host tools: %s\n' "${missing[*]}" >&2
    die "add them to the container image before building (this script will not use sudo)"
fi
command -v git-lfs >/dev/null 2>&1 ||
    printf 'build: warning: git-lfs not found; prebuilt blobs pulled via LFS may be pointers\n' >&2

# ---------------------------------------------------------------------------
# Space and prebuilts.
# ---------------------------------------------------------------------------
free_gb="$(df -Pk "$TOP" | awk 'NR == 2 { printf "%d", $4 / 1024 / 1024 }')"
[ "$free_gb" -ge 250 ] ||
    printf 'build: warning: only %s GB free under %s, a full build wants ~250 GB\n' \
        "$free_gb" "$TOP" >&2

for prebuilt in prebuilts/kernel prebuilts/dtbo.img prebuilts/dtb prebuilts/modules; do
    [ -e "$TOP/device/infinix/$DEVICE/$prebuilt" ] ||
        die "missing $prebuilt; the prebuilts are committed, run 'git lfs pull' if they are pointers"
done

# ---------------------------------------------------------------------------
# Optional: sync the tree, extract blobs.
# ---------------------------------------------------------------------------
if [ "$SYNC" = 1 ]; then
    printf 'build: repo sync -c -j%s\n' "$JOBS"
    ( cd "$TOP" && repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags )
fi

if [ -n "$EXTRACT" ]; then
    printf 'build: extracting blobs from %s\n' "$EXTRACT"
    ( cd "$TOP/device/infinix/$DEVICE" && ./extract-files.py "$EXTRACT" )
fi

BLOB_DIR="$TOP/vendor/infinix/$DEVICE"
[ -d "$BLOB_DIR" ] && [ -n "$(ls -A "$BLOB_DIR" 2>/dev/null)" ] ||
    die "no vendor blobs in $BLOB_DIR; run './build.sh --extract adb' with the stock ROM connected"

# ---------------------------------------------------------------------------
# ccache, environment, build.
# ---------------------------------------------------------------------------
export USE_CCACHE=1
export CCACHE_EXEC="$(command -v ccache)"
export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
mkdir -p "$CCACHE_DIR"
ccache -M "$CCACHE_SIZE" >/dev/null

printf 'build: device=%s variant=%s jobs=%s top=%s\n' "$DEVICE" "$VARIANT" "$JOBS" "$TOP"

set +u
# shellcheck disable=SC1091
. "$TOP/build/envsetup.sh" >/dev/null
set -u

if [ "$CLEAN" = 1 ]; then
    printf 'build: clobbering out/\n'
    m clobber
fi

lunch "lineage_${DEVICE}-${VARIANT}" >/dev/null ||
    die "lunch lineage_${DEVICE}-${VARIANT} failed"

LOG="$TOP/out/build-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$TOP/out"
printf 'build: mka bacon -j%s (log: %s)\n' "$JOBS" "$LOG"

# Keep the build's exit status through tee.
set -o pipefail
mka bacon -j"$JOBS" 2>&1 | tee "$LOG"

ZIP="$(ls -t "$TOP/out/target/product/$DEVICE"/lineage-22.2-*.zip 2>/dev/null | head -n 1 || true)"
printf '\nbuild: done\n'
if [ -n "$ZIP" ]; then
    printf '  package: %s\n' "$ZIP"
else
    printf '  package: not found under out/target/product/%s (check the log)\n' "$DEVICE"
fi
printf '  images:  %s/out/target/product/%s/{boot,dtbo,vendor_boot}.img\n' "$TOP" "$DEVICE"
printf '  log:     %s\n' "$LOG"
