#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

blob_fixups: blob_fixups_user_type = {
    # Add fixups here only once you see linker errors in logcat
    # ("cannot locate symbol ..."), e.g.:
    #
    # 'vendor/lib64/libwvdrmengine.so': blob_fixup()
    #     .replace_needed('libcrypto.so', 'libcrypto-vendor.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'X6525',
    'infinix',
    blob_fixups=blob_fixups,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
