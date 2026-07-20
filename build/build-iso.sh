#!/bin/bash
# RebuiltTux 2 ISO build script
# Prepares a minimal initramfs-based rootfs and (optionally) packs an ISO.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/build/work"
ISO_DIR="$BUILD_DIR/iso"
INITRAMFS_DIR="$BUILD_DIR/initramfs-root"
OUTPUT="$REPO_ROOT/rebuilttux2.iso"
BUSYBOX_OUT="$REPO_ROOT/tools/busybox"
# Try a few known BusyBox static binary URLs for x86_64
BUSYBOX_URLS=(
  "https://busybox.net/downloads/binaries/1.21.1/busybox-x86_64"
  "https://busybox.net/downloads/binaries/1.33.1/busybox-x86_64"
  "https://busybox.net/downloads/binaries/1.34.1/busybox-x86_64"
)

mkdir -p "$ISO_DIR/boot/grub" "$INITRAMFS_DIR"/bin "$INITRAMFS_DIR"/usr/bin "$INITRAMFS_DIR"/proc "$INITRAMFS_DIR"/sys "$INITRAMFS_DIR"/dev "$REPO_ROOT/tools"

# Copy the provided init into the initramfs layout
if [ -f "$REPO_ROOT/rootfs/init" ]; then
  cp "$REPO_ROOT/rootfs/init" "$INITRAMFS_DIR/init"
  chmod +x "$INITRAMFS_DIR/init"
else
  echo "Warning: rootfs/init not found. Create $REPO_ROOT/rootfs/init before building."
fi

# Copy an installer script into the initramfs if present
if [ -f "$REPO_ROOT/rootfs/installer.sh" ]; then
  mkdir -p "$INITRAMFS_DIR/installer"
  cp "$REPO_ROOT/rootfs/installer.sh" "$INITRAMFS_DIR/installer/installer.sh"
  chmod +x "$INITRAMFS_DIR/installer/installer.sh"
fi

# Ensure busybox is available (static). Try to use tools/busybox or download one from known URLs.
if [ ! -f "$BUSYBOX_OUT" ]; then
  echo "BusyBox binary not found at $BUSYBOX_OUT. Attempting to download a static BusyBox..."
  mkdir -p "$(dirname "$BUSYBOX_OUT")"
  for url in "${BUSYBOX_URLS[@]}"; do
    echo "Trying $url"
    if command -v curl >/dev/null 2>&1; then
      curl -L --fail -o "$BUSYBOX_OUT" "$url" && break || true
    elif command -v wget >/dev/null 2>&1; then
      wget -O "$BUSYBOX_OUT" "$url" && break || true
    fi
  done
fi

if [ -f "$BUSYBOX_OUT" ]; then
  chmod +x "$BUSYBOX_OUT"
  cp "$BUSYBOX_OUT" "$INITRAMFS_DIR/bin/busybox"
  (cd "$INITRAMFS_DIR/bin" && ./busybox --install -s .) || true
else
  echo "BusyBox not available. The initramfs will lack a shell. Provide a static busybox at $BUSYBOX_OUT to include one."
fi

# Copy any additional helper binaries provided in tools/ into the initramfs (e.g., parted, sgdisk, mkfs.*)
if [ -d "$REPO_ROOT/tools" ]; then
  for f in "$REPO_ROOT"/tools/*; do
    [ -f "$f" ] || continue
    echo "Including helper tool: $(basename "$f")"
    cp "$f" "$INITRAMFS_DIR/bin/" || true
    chmod +x "$INITRAMFS_DIR/bin/$(basename "$f")" || true
  done
fi

# Additional guidance
cat > "$ISO_DIR/README.txt" <<EOF
RebuiltTux 2 boot image

This ISO contains a minimal initramfs-based live environment and an automated installer.
For advanced features (LVM, LUKS, debootstrap, grub-install) include the following static tools in tools/ prior to building the ISO:
  - parted, sgdisk, sfdisk
  - mkfs.vfat, mkfs.ext4, mkfs.btrfs
  - cryptsetup
  - lvm2 tools (pvcreate, vgcreate, lvcreate)
  - debootstrap
  - grub-install, grub-mkconfig
  - blkid, lsblk

Place static binaries in tools/ so they are copied into the initramfs. Building a truly bootable ISO requires running this script on a Linux host with grub-mkrescue installed.

To build:
  1) Provide a kernel at $ISO_DIR/boot/vmlinuz (copy from your distro)
  2) Place helper static binaries in tools/
  3) Run this script on Linux: ./build/build-iso.sh
EOF

# GRUB menu entry that expects a kernel and the generated initramfs
cat > "$ISO_DIR/boot/grub/grub.cfg" <<EOF
set timeout=5
set default=0

menuentry "RebuiltTux 2 (minimal initramfs)" {
    linux /boot/vmlinuz quiet root=/dev/ram0 init=/init
    initrd /boot/initramfs.cpio.gz
}
EOF

# Create minimal device node for console if possible
if command -v sudo >/dev/null 2>&1 && command -v mknod >/dev/null 2>&1; then
  sudo mknod -m 622 "$INITRAMFS_DIR/dev/console" c 5 1 || true
fi

# Pack the initramfs
OLDPWD="$(pwd)"
cd "$INITRAMFS_DIR"
find . | cpio -o -H newc 2>/dev/null | gzip -9 > "$ISO_DIR/boot/initramfs.cpio.gz"
cd "$OLDPWD"

# Build ISO if grub-mkrescue is available
if command -v grub-mkrescue >/dev/null 2>&1; then
    grub-mkrescue -o "$OUTPUT" "$ISO_DIR" || true
else
    echo "grub-mkrescue not found; created ISO directory only at $ISO_DIR"
fi

echo "Build finished: $OUTPUT (or see $ISO_DIR for files)."
