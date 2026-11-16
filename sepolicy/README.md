# sepolicy

Device policy for the X6525. `BoardConfig.mk` wires this directory in:

```make
BOARD_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
```

## Current state

The tree boots permissive (`androidboot.selinux=permissive enforcing=0` in
`BOARD_KERNEL_CMDLINE`, plus `SELINUX_IGNORE_NEVERALLOWS := true`).

The rules cannot be written yet, and the reason is not just "no denials have
been collected". Read the next section before adding any.

## The real blocker: the stock vendor policy is not in this tree

`proprietary-files.txt` contains **no** `/vendor/etc/selinux` entries, so the
ROM compiles the vendor policy from AOSP plus `sepolicy/vendor` only. The stock
vendor partition (from the dump) carries its own policy, and that is where the
Unisoc types, domains and labels live — the ones the stock HAL binaries are
launched under:

```
vendor/etc/selinux/vendor_sepolicy.cil
vendor/etc/selinux/vendor_file_contexts
vendor/etc/selinux/vendor_property_contexts
vendor/etc/selinux/vendor_service_contexts
vendor/etc/selinux/vendor_hwservice_contexts
vendor/etc/selinux/vndservice_contexts
vendor/etc/selinux/vendor_seapp_contexts
vendor/etc/selinux/plat_sepolicy_vers.txt
vendor/etc/selinux/plat_pub_versioned.cil
```

(listed from the vendor image of the stock PAC, so those paths are confirmed to
exist on this device).

Consequences:

- `allow` rules alone cannot make this tree enforcing. Without the OEM
  `*_exec` labels and domains, `init` has no type to transition a stock HAL
  into, so the service fails to start no matter what rules exist.
- `vendor_file_contexts` is missing too, so the stock binaries copied into the
  ROM's vendor image are labelled generically instead of per-domain.

Two honest options:

1. **Stay permissive** (current state) until the device boots and you are
   ready to port policy. This is a bring-up tree, not a shipping one.
2. **Port the OEM policy**: extract `/vendor/etc/selinux/*` from the stock
   vendor image, ship those files, and stop letting the build generate
   `vendor_sepolicy.cil` over them. Compare the OEM labels in
   `vendor_file_contexts` against each binary in `proprietary-files.txt`, add
   the missing `_exec` labels to `vendor/file_contexts`, and only then switch
   the cmdline off permissive. Expect several boot iterations; a policy that
   fails to load or a HAL that cannot exec is a bootloop, not a warning.

## Writing rules once the device boots

`audit2te.py` turns AVC denials into rules without needing an AOSP checkout
(`audit2allow` only exists inside a build tree):

```sh
adb shell dmesg > avc.log
adb logcat -d >> avc.log
python3 sepolicy/audit2te.py avc.log                    # print to stdout
python3 sepolicy/audit2te.py avc.log --out-dir /tmp/te  # one .te per domain
```

It merges repeated denials per `(domain, type, class)`, keeps the permission
sets, and tags each rule with a denial count plus a sample path/name so the
rule can be traced back. Denials that only happened because a domain is still
permissive (`permissive=1`) are skipped unless you pass
`--include-permissive`; those are the ones that reappear the moment the domain
goes enforcing, so review them before switching over.

Workflow:

1. Boot permissive with `adb`, then exercise the device: Wi-Fi, Bluetooth,
   mobile data, calls, audio, camera, fingerprint, touch, charging, sensors,
   and a reboot into recovery.
2. Collect and convert as above.
3. Move rules into `vendor/*.te`, one file per source domain. Every `allow` is
   a hole: prefer narrowing the type (via `vendor/file_contexts`) over widening
   the rule.
4. Verify the labels you are relying on with `adb shell ls -Z <path>`.
5. Rebuild, boot enforcing, and repeat until the boot log is clean.

## Before shipping

- Drop `androidboot.selinux=permissive enforcing=0` from
  `BOARD_KERNEL_CMDLINE`.
- Drop `SELINUX_IGNORE_NEVERALLOWS := true` from `BoardConfig.mk` and fix the
  neverallow violations it was hiding.
- Keep `permissive` declarations out of the shipped policy.
