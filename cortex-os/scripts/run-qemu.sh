#!/usr/bin/env bash
set -Eeuo pipefail
kernel=${1:?kernel image}
initramfs=${2:?initramfs}
rootfs=${3:?rootfs directory}
project_root=$(cd "$(dirname "$0")/.." && pwd)
disk="$project_root/artifacts/rootfs.ext4"
[[ -f "$disk" ]] || { echo "Missing $disk; run make initramfs first" >&2; exit 1; }

# Use QEMU_DISPLAY=gtk when running from a graphical desktop; headless is safest in CI/sandbox.
qemu_display=${QEMU_DISPLAY:-none}
exec qemu-system-x86_64 \
  -machine q35,accel=tcg \
  -m 4096 \
  -smp 2 \
  -kernel "$kernel" \
  -initrd "$initramfs" \
  -drive file="$disk",if=virtio,format=raw \
  -append 'console=ttyS0 root=/dev/vda rw systemd.unit=graphical.target' \
  -display "$qemu_display" \
  -serial mon:stdio \
  -no-reboot
