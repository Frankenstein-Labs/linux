# CORTEX OS prototype

This repository assembles a first bootable CORTEX prototype around the `Frankenstein-Labs/linux` kernel and a Debian root filesystem with KDE Plasma on Wayland.

## Safety boundary

The build writes only inside this directory. It does not partition or write to the host disk. The first runtime target is QEMU.

## Architecture

```text
Frankenstein-Labs/linux -> CORTEX kernel -> Debian rootfs -> systemd -> KWin/Wayland -> KDE Plasma
```

## Quick start

```bash
sudo apt update
sudo apt install -y git build-essential bc bison flex libssl-dev libelf-dev libncurses-dev dwarves cpio qemu-system-x86 debootstrap rsync

make kernel       # compile the parent kernel checkout
make rootfs       # create Debian trixie rootfs and install KDE Plasma
make initramfs    # create a boot initramfs
make run          # boot the prototype in QEMU
```

The KDE stage is intentionally distribution-packaged first. CORTEX-specific desktop components can replace KDE components after the VM boot milestone is stable.

## Build outputs

- `../`: parent `Frankenstein-Labs/linux` source checkout
- `build/kernel`: out-of-tree kernel build
- `rootfs`: Debian filesystem tree
- `artifacts/`: kernel, initramfs and future ISO outputs

## Current milestone

`Frankenstein-Labs/linux -> compiled kernel -> Debian rootfs -> QEMU -> KDE Plasma Wayland`.

The build uses a pinned kernel commit recorded in `config/kernel.env`. Review that file before rebuilding from a different revision.

## Build a BIOS/UEFI ISO

Install the ISO tooling and run:

```bash
sudo apt install -y grub-pc-bin grub-efi-amd64-bin xorriso mtools
make iso
```

The result is `artifacts/cortex-os.iso`. It contains the CORTEX kernel, initramfs and Debian KDE root image, and is assembled through `grub-mkrescue` for BIOS and UEFI boot. Validate it in QEMU with:

```bash
QEMU_DISPLAY=gtk make run-iso
```

Use `QEMU_DISPLAY=none make run-iso` for a serial/headless boot check.

The ISO has been validated in QEMU in both legacy BIOS and OVMF UEFI modes. Both paths reached `systemd`, `sddm.service` and `graphical.target`. The ISO root image is mounted read-only from the CD and exposed to the session through a writable tmpfs overlay.

```bash
make run-iso          # BIOS/legacy firmware
make run-iso-uefi     # UEFI firmware (requires OVMF files in artifacts/)
```

## GitHub Actions

The repository workflow at `.github/workflows/cortex-os-iso.yml` builds the kernel, Debian KDE rootfs, initramfs and BIOS/UEFI ISO on pushes that change the kernel or `cortex-os/**`. It can also be started manually from the **Actions** tab with **Run workflow**.

The generated `cortex-os.iso` and `SHA256SUMS` are uploaded as a workflow artifact for seven days. Because the ISO is approximately 8 GiB, the workflow disables artifact compression to avoid wasting runner time and storage on an already mostly incompressible disk image.
