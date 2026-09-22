#!/usr/bin/env bash
set -Eeuo pipefail
rootfs=$(realpath "${1:?rootfs directory}")
kbuild=$(realpath "${2:?kernel build directory}")
artifacts=$(realpath -m "${3:?artifacts directory}")
mkdir -p "$artifacts"
if [[ $EUID -ne 0 ]]; then
  exec sudo -E "$0" "$rootfs" "$kbuild" "$artifacts"
fi
chmod 0755 "$artifacts"

disk="$artifacts/rootfs.ext4"
rm -f "$disk"
dd if=/dev/zero of="$disk" bs=1M count=8192 status=none
mkfs.ext4 -F -L CORTEX_ROOT "$disk" >/dev/null
mnt=$(mktemp -d)
loop=$(losetup --find --show "$disk")
cleanup() {
  umount "$mnt" 2>/dev/null || true
  losetup -d "$loop" 2>/dev/null || true
  rmdir "$mnt" 2>/dev/null || true
}
trap cleanup EXIT
mount "$loop" "$mnt"
rsync -aHAX --delete "$rootfs"/ "$mnt"/
mkdir -p "$mnt/boot"
cp "$kbuild/arch/x86/boot/bzImage" "$mnt/boot/vmlinuz-cortex"
sync

initramfs_tree="$artifacts/initramfs-tree"
rm -rf "$initramfs_tree"
mkdir -p "$initramfs_tree"/{bin,dev,proc,sys,newroot,cdrom,lower,upper,merged}
cp /bin/busybox "$initramfs_tree/bin/busybox"
for applet in mount sleep mkdir losetup; do
  ln -s busybox "$initramfs_tree/bin/$applet"
done
cat > "$initramfs_tree/init" <<'INIT'
#!/bin/busybox sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /newroot /cdrom /lower /upper /merged
mounted=0
if mount -t ext4 -o rw /dev/vda /newroot; then
  mounted=1
fi
if [ "$mounted" -ne 1 ]; then
  if mount -t iso9660 -o ro /dev/sr0 /cdrom; then
    if losetup -f /cdrom/rootfs.ext4; then
      if mount -t ext4 -o ro /dev/loop0 /lower; then
        if mount -t tmpfs tmpfs /upper; then
          mkdir -p /upper/upper /upper/work
          if mount -t overlay overlay -o lowerdir=/lower,upperdir=/upper/upper,workdir=/upper/work /newroot; then
            mounted=1
          fi
        fi
      fi
    fi
  fi
fi
if [ "$mounted" -ne 1 ]; then
  echo 'CORTEX initramfs: unable to mount disk or ISO rootfs' >&2
  exec /bin/busybox sh
fi
exec /bin/busybox switch_root /newroot /sbin/init
INIT
chmod +x "$initramfs_tree/init"
( cd "$initramfs_tree" && find . -print0 | cpio --null -o -H newc | gzip -9 > "$artifacts/initramfs.cpio.gz" )
chmod 0644 "$disk" "$artifacts/initramfs.cpio.gz"
printf 'Disk image ready: %s\nInitramfs ready: %s\n' "$disk" "$artifacts/initramfs.cpio.gz"
