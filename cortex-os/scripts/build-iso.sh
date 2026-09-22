#!/usr/bin/env bash
set -Eeuo pipefail
project_root=$(cd "$(dirname "$0")/.." && pwd)
artifacts="$project_root/artifacts"
isoroot="$artifacts/iso-root"
iso="$artifacts/cortex-os.iso"

[[ -s "$artifacts/rootfs.ext4" ]] || { echo 'Missing rootfs.ext4; run make initramfs first' >&2; exit 1; }
[[ -s "$artifacts/initramfs.cpio.gz" ]] || { echo 'Missing initramfs.cpio.gz; run make initramfs first' >&2; exit 1; }
[[ -s "$project_root/build/kernel/arch/x86/boot/bzImage" ]] || { echo 'Missing bzImage; run make kernel first' >&2; exit 1; }

rm -rf "$isoroot"
mkdir -p "$isoroot/boot/grub"
cp "$project_root/build/kernel/arch/x86/boot/bzImage" "$isoroot/boot/vmlinuz-cortex"
cp "$artifacts/initramfs.cpio.gz" "$isoroot/boot/initramfs-cortex.cpio.gz"
cp "$artifacts/rootfs.ext4" "$isoroot/rootfs.ext4"
cat > "$isoroot/boot/grub/grub.cfg" <<'GRUB'
set timeout=3
set default=0

menuentry 'CORTEX OS - KDE Plasma (UEFI/BIOS)' {
    linux /boot/vmlinuz-cortex console=ttyS0 root=/dev/sr0 cortex.iso=1 systemd.unit=graphical.target
    initrd /boot/initramfs-cortex.cpio.gz
}
GRUB

# ISO9660 level 3 is required because rootfs.ext4 is larger than 4 GiB.
grub-mkrescue -o "$iso" -iso-level 3 "$isoroot"
chmod 0644 "$iso"
printf 'Hybrid ISO ready: %s\n' "$iso"
