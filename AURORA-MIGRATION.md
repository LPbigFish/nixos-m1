# J293: Asahi to Aurora

This is an existing installation, not an Aurora installer image. Keep target
`nixosConfigurations.m1`, the existing accounts, Home Manager/Darwin targets,
Btrfs subvolumes, swapfile, keyboard remapping, and `system.stateVersion`.
Do not import `aurora.nixosModules.image`.

## Selected sources

The lock follows the published `channel-testing`, whose publication record
selected `cache-testing-20261121.4` when inspected on 2026-11-25.

| Component | Revision |
| --- | --- |
| Aurora | `fd6219cd121d77ac0e23dbfe52299d712df90dc1` |
| Nixpkgs | `1d060086d60cb76a40cf37109f979d88a5bd6396` |
| nixos-apple-silicon | `12cd234285d3037cedfab979aa70b75284a59afc` |
| Linux 7.3.0 | `9125b31475836ce0a6634df45b539c6d604f36a5` |
| Aura 1.0.0b14.1 | `3ff77894567239362a116e7fcbb214c55dccf5a4` |
| U-Boot 2026.07 | `250385f8c8aaafd47a8f7990f6efe0443c28d0b5` |
| Mesa 26.3.0 | `d4ad4a4dce6d1d23ecd897d6d73fadf9ab618614` |

Both overlays and both Aurora modules are required. The Apple Silicon overlay
precedes Aurora's; local overlays follow them. NixOS constructs its own `pkgs`
so module overlays and package configuration are effective.
`boot.initrd.systemd.enable` must remain **undefined**: the selected Nixpkgs
removed scripted initrd and the option itself, including `false`.

The update command is configured for `/etc/nixos#m1`. Do not run `aurora-update`
for the first activation: it updates inputs and switches the running system.

## Verified machine and firmware

- Device tree: `apple,j293`, `apple,t8103`, `apple,arm-platform`.
- ESP: `/dev/nvme0n1p4`, mounted at `/boot`, FAT UUID `8465-190F`.
- ESP PARTUUID: `e0fa597c-885e-4a91-b121-ff245211aafe`, matching
  `/proc/device-tree/chosen/asahi,efi-system-partition`.
- Btrfs UUID: `841486e4-9eed-44c7-98fe-80e985f07052`; subvolumes `@root`,
  `@nix`, `@home`, `@swap`; existing 8-GiB `/swap/swapfile`.
- Working system: Asahi 7.3.4, system generation 13.
- Booted Stage 1: stock m1n1 `v1.6.1`, **not** trial-capable Aura.

The required archive is `/boot/vendorfw/firmware.cpio`, not `firmware.tar`.
Its SHA-256 is
`c4b95c73314235a6ee1c3ee535aefb34bea100cede9f3aea42f7ae992f5a1468`;
it matches the repository copy. All 217 manifest file hashes passed inspection.
J293 Touch Bar, BCM4378/honshu Wi-Fi and Bluetooth, camera firmware, and ALS
calibration are present.

Aurora extracts this Mac's archive to `/run/aurora-firmware/vendorfw` at boot,
restores the runtime firmware search path, then admits the deferred peripherals.
Build-time Asahi extraction is disabled. Automatic macOS Wi-Fi firmware refresh
is explicitly disabled during this migration so it cannot replace the known
firmware archive on a later boot. Reconsider that setting after hardware testing.

On this M1, bootloader installation directly replaces `m1n1/boot.bin`, with a
verified staged write and a `.old` backup. It does not upgrade Stage 1.
There is no automatic one-shot trial or fallback with the current Stage 1.
J293 is required by the build-time Stage 2 validator. Retained-generation DT ABI
checks must remain enabled; never bypass a refusal by deleting generations or
disabling the checker.
The candidate J293 tree preserves the running `dcp` and `disp0` display aliases.
The locked updater classifies retained generation 13 as DT ABI 1, matching this
Aurora kernel's ABI 1; no compatibility-check override is necessary.

## Recovery material

Before these final edits, the following directory was created with mode 0700:

```sh
RECOVERY=/home/lpbigfish/aurora-recovery-20261125-200940
```

It contains:

- `working-tree.tar`, `working.diff`, `staged.diff`, and `repository.bundle`:
  the pre-edit dirty tracked/non-ignored working files and Git history.
  The unrelated ignored nested `nixos_conf` repository was not changed.
- `original-asahi/`: configuration and lockfile from `asahi-before-aurora`.
  That branch's lock is older than the currently running closure; rebuilding it
  is **not** a substitute for preserving the working closure.
- `esp.tar`: the complete original ESP, compared successfully against `/boot`.
- `esp-critical/`: separate original `boot.bin`, its pre-existing backup,
  `EFI/BOOT/BOOTAA64.EFI`, GRUB configuration, and firmware archive.
- `host.json`, `asahi-closure.txt`, and `SHA256SUMS`.
- Evaluation, cache-bootstrap, build, and test records added during validation.
  `SHA256SUMS` covers the original backup files, not subsequently added logs.

Check the original backup:

```sh
cd "$RECOVERY"
sha256sum -c SHA256SUMS
```

The permanent GC root
`/nix/var/nix/gcroots/asahi-before-aurora` preserves:

```text
/nix/store/qh37ds85m0xha4r2d24f36i64ymdjfsi-nixos-system-DESKTOP-349210-26.11.20261117.0490633
```

All 1,591 paths in that closure were present. The pre-existing
`/boot/m1n1/boot.bin.asahi-before-aurora` matches the original live bundle:

```text
ac3ef5de8bb59e98ce48d954b485ae419bcc25146d10d34210f1ebc485e0a0ed
```

Only generation 13 remains in the main system profile. Old GRUB entries do not
prove their closures still exist: generation 12's closure is already missing.
Automatic NH cleanup remains disabled; both its future retention arguments and
the manual alias keep at least 10 generations and 30 days, and do not clean
GC roots. Do not run cleanup during the migration.

Copy the recovery directory to macOS-readable external media before activation.
The home-directory backup is on Btrfs and is not normally readable from macOS.
Keep the existing on-ESP `boot.bin.asahi-before-aurora` as well.

## Build without activation

```sh
cd /etc/nixos
nix build --dry-run --no-update-lock-file \
  .#nixosConfigurations.m1.config.system.build.toplevel
nix build --no-update-lock-file --out-link result-aurora \
  --max-jobs 2 --cores 4 --option fallback false \
  .#nixosConfigurations.m1.config.system.build.toplevel
```

Aurora's locked cache settings are:

```text
https://aurorasilicon.org/nixos-aurora/cache
aurora-nixos-1:ZxmPNEWsrzgXai+W+dlTE8cachb1xaatfXKK8X8go14=
```

Before activation these settings are not active in the running daemon. Its
`trusted-users` is `root`, so ordinary-user substituter/key flags are ignored.
The initial cache-only `sudo nix copy` import used the signed publication's
matching store paths; kernel, Mesa, Aura, and U-Boot signatures were retained.
No signature checks were disabled.

Some GNOME dependencies, speaker tools, CPU tools, and external Xbox modules are
not covered by matching cache outputs and need local builds. Fetching the
kernel source for `cpupower` is not a kernel recompilation. Investigate any
actual `linux-aurora-7.3.0.drv` or native `mesa-26.3.0.drv` source build before
proceeding.

Build/evaluation checks cannot establish that display, input, Touch Bar,
Wi-Fi, Bluetooth, speakers, camera, suspend, or Touch ID work after reboot.

### Validation record

- NixOS toplevel evaluation: all 1,711 assertions pass, no evaluation warnings.
- Home Manager and Darwin system derivations evaluate successfully. This is not
  a Darwin build on Linux.
- `nix flake check --no-build --no-update-lock-file` passes.
- `nixfmt --check` for the touched Nix files and `git diff --check` pass.
- 218 locked-upstream tests pass with zero failures, errors, or skips: Stage 2
  installation/trial transactions, consumer update targeting, firmware
  extraction/search paths, and peripheral admission. These use temporary
  fixtures, not the real ESP or host sysfs.
- Imported kernel and Mesa NAR content hashes match their registered store
  records; those records retain Aurora cache signatures.
- The checked Stage 2 builds successfully at
  `/nix/store/jhva1zr0rfr8qmjy3pa5isvynd2y5kc1-aurora-stage2`.
  Its 134-board manifest includes J293; its SHA-256 is
  `083acc496441fa38613446c4d5b7084770455f97db165efa0ce6653ce18747e6`.
  The locked updater's read-only DT ABI precheck passes against the real retained
  generation, using a lock file in the recovery directory and no ESP writes.
- Full system build completion is recorded separately after the build finishes.

## Activation: not performed

**Stop until ESP space is resolved.** Inspection found only 36 MiB free on the
476-MiB ESP. Retaining Asahi while copying Aurora's kernel/initrd and staging
Stage 2 requires more space. Do not rely on GRUB pruning files midway through
installation. Keep a conservative 120 MiB free for the first installation and
check the built artifact sizes.

There are about 93 MiB of legacy systemd-boot images in `/boot/EFI/nixos`,
separate from the working GRUB images in `/boot/kernels`. Offloading obsolete
images is a possible later space-recovery action. Both old systemd-boot entries
(generations 1 and 2) reference closures that are already missing; neither is a
usable recovery generation. The two images are:

```text
EFI/nixos/fyrv4wlxlq966sf5j0a8jwvf9xavxna1-linux-asahi-7.1.5-Image.efi
EFI/nixos/qnm7pcvfkll9h1lhh5lrs56srdzcs64n-initrd-linux-asahi-7.1.5-initrd.efi
```

Their combined size is 96,993,403 bytes; separately approved offloading would
leave approximately 127.7 MiB free without removing any retained system
generation. They are preserved in `esp.tar`. Verify the backup and an external
recovery copy **before** any such action. No ESP files or system generations
were removed during this task. Do not delete `/boot/vendorfw`,
`/boot/asahi`, the working GRUB kernels, or either original Stage 2 copy.

Before installing, confirm the identity again:

```sh
findmnt /boot
lsblk -no PARTUUID /dev/nvme0n1p4
tr '\0' '\n' < /proc/device-tree/chosen/asahi,efi-system-partition
df -h /boot
readlink -f /etc/nixos/result-aurora
```

After the build, backup, external recovery copy, and space prerequisites pass:

```sh
sudo nixos-rebuild boot --flake /etc/nixos#m1 --no-update-lock-file
```

This command **writes GRUB/EFI files and the shared Stage 2 bundle**, but does
not switch the running services or reboot. Review its output. A refused DT ABI
or partition check is a blocker, not something to override.
No reboot or Stage 1 upgrade is included in this procedure.

## Recovery A: Aurora boots, but return to Asahi

Use the exact preserved working closure, not a newly rebuilt old lockfile:

```sh
ASAHI=$(readlink -f /nix/var/nix/gcroots/asahi-before-aurora)
test -x "$ASAHI/bin/switch-to-configuration"
sudo nix-env --profile /nix/var/nix/profiles/system --set "$ASAHI"
sudo "$ASAHI/bin/switch-to-configuration" boot
```

The old configuration's installer restores its own GRUB menu and Asahi Stage 2.
Verify its result and reboot separately when ready. Restore the original
repository files into a separate checkout from the backup if desired; do not
overwrite the migration work.

## Recovery B: GRUB works, but Aurora's kernel fails

Select **NixOS - Configuration 13** in GRUB's all-configurations submenu. If it
boots, perform Recovery A.

Every GRUB entry uses the **same live Stage 2 device trees**. Selecting Asahi
does not restore its trees; if it also fails, restore the original Stage 2 using
Recovery C, then choose generation 13. Do not rely on stale generation 12.

## Recovery C: failure before GRUB, or incompatible shared device trees

From a Linux recovery environment, mount this exact ESP:

```sh
sudo mkdir -p /mnt/esp
sudo mount /dev/disk/by-partuuid/e0fa597c-885e-4a91-b121-ff245211aafe /mnt/esp
sha256sum /mnt/esp/m1n1/boot.bin.asahi-before-aurora
sudo cp /mnt/esp/m1n1/boot.bin.asahi-before-aurora /mnt/esp/m1n1/boot.bin
sync
```

The printed checksum must match the original above **before** copying.
If the EFI loader or GRUB files are also damaged, restore them from the external
copy of `esp.tar` (set `RECOVERY` to that mounted external backup):

```sh
sudo tar -C /mnt/esp -xf "$RECOVERY/esp.tar" ./EFI ./grub ./kernels
sync
sudo umount /mnt/esp
```

This restores the original boot installation; it does not rewrite firmware or
Stage 1. Boot generation 13 and perform Recovery A to restore the system profile.

From macOS/Startup Options, use `diskutil list` and `diskutil info` to identify
the partition with **Disk / Partition UUID**
`E0FA597C-885E-4A91-B121-FF245211AAFE`. Do not assume its Linux disk number
matches macOS. Mount it with `diskutil mount`, use the reported mount point,
verify the backup with `shasum -a 256`, and copy
`m1n1/boot.bin.asahi-before-aurora` over `m1n1/boot.bin`.
The external recovery copy supplies `EFI`/GRUB files if necessary.
Flush and unmount the ESP before trying Linux again. Do not reinstall or upgrade
Stage 1 as a substitute for restoring the verified Stage 2 backup.
