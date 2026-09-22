#!/usr/bin/env bash
set -Eeuo pipefail
project_root=$(cd "$(dirname "$0")/.." && pwd)
iso=${1:-$project_root/artifacts/cortex-os.iso}
[[ -s "$iso" ]] || { echo "Missing ISO: $iso" >&2; exit 1; }
qemu_display=${QEMU_DISPLAY:-none}
firmware=()
if [[ "${QEMU_UEFI:-0}" == "1" ]]; then
  code="$project_root/artifacts/OVMF_CODE_4M.fd"
  vars="$project_root/artifacts/OVMF_VARS_4M.fd"
  [[ -s "$code" && -s "$vars" ]] || { echo 'Missing OVMF files; copy them from /usr/share/OVMF first' >&2; exit 1; }
  firmware=(-drive "if=pflash,format=raw,readonly=on,file=$code" -drive "if=pflash,format=raw,file=$vars")
fi
exec qemu-system-x86_64 \
  -machine q35,accel=tcg \
  -m 4096 \
  -smp 2 \
  "${firmware[@]}" \
  -cdrom "$iso" \
  -boot d \
  -display "$qemu_display" \
  -serial mon:stdio \
  -no-reboot
