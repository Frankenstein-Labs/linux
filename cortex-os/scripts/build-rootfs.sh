#!/usr/bin/env bash
set -Eeuo pipefail

rootfs=${1:?rootfs directory}
project_root=$(cd "$(dirname "$0")/.." && pwd)

if [[ $EUID -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

mkdir -p "$rootfs"
if [[ ! -f "$rootfs/etc/debian_version" ]]; then
  debootstrap --arch=amd64 --variant=minbase trixie "$rootfs" http://deb.debian.org/debian
fi

cp /etc/resolv.conf "$rootfs/etc/resolv.conf.cortex-host"
rm -f "$rootfs/etc/resolv.conf"
touch "$rootfs/etc/resolv.conf"
cat > "$rootfs/etc/apt/sources.list.d/debian.sources" <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free-firmware

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free-firmware
EOF

mount --bind /etc/resolv.conf "$rootfs/etc/resolv.conf"
mount --bind /dev "$rootfs/dev"
mount --bind /dev/pts "$rootfs/dev/pts"
trap 'umount -R "$rootfs/dev/pts" 2>/dev/null || true; umount -R "$rootfs/dev" 2>/dev/null || true; umount "$rootfs/etc/resolv.conf" 2>/dev/null || true' EXIT

chroot "$rootfs" /usr/bin/env DEBIAN_FRONTEND=noninteractive bash -eux <<'CHROOT'
apt-get update
apt-get install -y --no-install-recommends \
  systemd-sysv dbus sudo network-manager \
  linux-base systemd-timesyncd \
  plasma-desktop plasma-workspace kwin-wayland \
  sddm konsole dolphin xwayland mesa-utils
systemctl enable sddm NetworkManager
useradd -m -s /bin/bash cortex || true
printf 'cortex:cortex\n' | chpasswd
usermod -aG sudo,audio,video,render,input cortex
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<'UNIT'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin cortex --noclear %I $TERM
UNIT
cat > /etc/issue <<'ISSUE'
CORTEX OS prototype - KDE Plasma Wayland
ISSUE
apt-get clean
CHROOT

printf 'Rootfs ready: %s\n' "$rootfs"
