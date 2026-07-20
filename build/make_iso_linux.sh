#!/usr/bin/env bash
set -euo pipefail

# make_iso_linux.sh
# Automated helper to build the RebuiltTux ISO on a Linux host.
# Usage: sudo ./build/make_iso_linux.sh [--kernel /path/to/vmlinuz] [--no-copy-tools] [--test-qemu]

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_SCRIPT="$REPO_ROOT/build/build-iso.sh"
WORK_ISO_DIR="$REPO_ROOT/build/work/iso"
TOOLS_DIR="$REPO_ROOT/tools"
KERNEL_ARG=""
COPY_TOOLS=true
TEST_QEMU=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --kernel) KERNEL_ARG="$2"; shift 2 ;; 
    --no-copy-tools) COPY_TOOLS=false; shift ;; 
    --test-qemu) TEST_QEMU=true; shift ;; 
    -h|--help) echo "Usage: $0 [--kernel /path/to/vmlinuz] [--no-copy-tools] [--test-qemu]"; exit 0 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [ ! -f "$BUILD_SCRIPT" ]; then
  echo "Build script not found: $BUILD_SCRIPT"; exit 1
fi

echo "Preparing build directories..."
mkdir -p "$WORK_ISO_DIR/boot" "$TOOLS_DIR"

# Detect package manager and print recommended packages
PKG_CMD=""
if command -v apt-get >/dev/null 2>&1; then
  PKG_CMD="sudo apt-get update && sudo apt-get install -y xorriso grub-pc-bin grub-efi-amd64-bin grub-common grub-pc debootstrap parted sgdisk cryptsetup lvm2 mkfs.vfat dosfstools e2fsprogs btrfs-progs qemu-system-x86"
elif command -v dnf >/dev/null 2>&1; then
  PKG_CMD="sudo dnf install -y grub2-efi-x64 grub2-tools xorriso debootstrap parted gdisk cryptsetup lvm2 dosfstools e2fsprogs btrfs-progs qemu-system-x86"
else
  PKG_CMD="# Install required packages manually: grub-mkrescue/xorriso, debootstrap, parted, cryptsetup, lvm2, mkfs utilities, qemu"
fi

echo "Recommended install command for this host:" 
echo "$PKG_CMD"

echo "Locating kernel to include in ISO..."
if [ -n "$KERNEL_ARG" ]; then
  KERNEL_PATH="$KERNEL_ARG"
elif [ -f "/boot/vmlinuz" ]; then
  KERNEL_PATH="/boot/vmlinuz"
else
  # try to find a vmlinuz-*
  KERNEL_PATH="$(ls -1t /boot/vmlinuz-* 2>/dev/null | head -n1 || true)"
fi

if [ -z "$KERNEL_PATH" ] || [ ! -f "$KERNEL_PATH" ]; then
  echo "No kernel found automatically. Please pass --kernel /path/to/vmlinuz or copy a kernel to $WORK_ISO_DIR/boot/vmlinuz and re-run."
  exit 1
fi

echo "Using kernel: $KERNEL_PATH"
cp -v "$KERNEL_PATH" "$WORK_ISO_DIR/boot/vmlinuz"

# Optionally copy helper tools from host into tools/ (best-effort)
if [ "$COPY_TOOLS" = true ]; then
  echo "Gathering helper binaries into $TOOLS_DIR (best-effort)."
  TOOLS=(parted sgdisk mkfs.vfat mkfs.ext4 mkfs.btrfs cryptsetup pvcreate vgcreate lvcreate debootstrap grub-install grub-mkconfig blkid lsblk)
  for t in "${TOOLS[@]}"; do
    if command -v "$t" >/dev/null 2>&1; then
      src="$(command -v $t)"
      echo "Copying $t from $src"
      cp -v "$src" "$TOOLS_DIR/" || true
    else
      echo "Tool not found: $t (will warn at build-time)"
    fi
  done
fi

# Make sure build script is executable
chmod +x "$BUILD_SCRIPT"

# Run the build script (must be on Linux)
echo "Running build script to assemble initramfs and ISO directory..."
( cd "$REPO_ROOT" && bash "$BUILD_SCRIPT" )

# If grub-mkrescue created an ISO, move it to repo root
ISO_OUT="$REPO_ROOT/rebuilttux2.iso"
if [ -f "$ISO_OUT" ]; then
  echo "ISO created at: $ISO_OUT"
else
  # try to find generated ISO in working dir
  GEN_ISO="$(find "$REPO_ROOT/build/work/iso" -maxdepth 1 -type f -name "*.iso" -print -quit || true)"
  if [ -n "$GEN_ISO" ]; then
    mv -v "$GEN_ISO" "$ISO_OUT"
    echo "Moved generated ISO to $ISO_OUT"
  else
    echo "No ISO produced. Check output in $REPO_ROOT/build/work/iso and ensure grub-mkrescue is installed." 
    exit 1
  fi
fi

if [ "$TEST_QEMU" = true ]; then
  echo "Launching QEMU to test ISO (press Ctrl-A then X to exit if using qemu-system-x86_64)."
  if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    qemu-system-x86_64 -cdrom "$ISO_OUT" -m 2048 -boot d -enable-kvm || qemu-system-x86_64 -cdrom "$ISO_OUT" -m 1024 -boot d
  else
    echo "qemu-system-x86_64 not available. Install qemu to test the ISO.";
  fi
fi

echo "Done. Replace repo ISO placeholder if needed."
