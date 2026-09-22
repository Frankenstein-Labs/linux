#!/usr/bin/env bash
set -Eeuo pipefail

repo=${1:?kernel repository URL}
src=${2:?kernel source directory}
build=${3:?kernel build directory}
image=${4:?kernel image path}
root=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$root/config" "$build"

if [[ ! -d "$src/.git" ]]; then
  mkdir -p "$(dirname "$src")"
  git clone --depth=1 "$repo" "$src"
fi

commit=$(git -C "$src" rev-parse HEAD)
printf 'KERNEL_REPO=%s\nKERNEL_COMMIT=%s\n' "$repo" "$commit" > "$root/config/kernel.env"

if [[ ! -f "$build/.config" ]]; then
  make -C "$src" O="$build" x86_64_defconfig
fi

make -C "$src" O="$build" -j"$(nproc)" bzImage modules
printf 'Kernel ready: %s\n' "$image"
