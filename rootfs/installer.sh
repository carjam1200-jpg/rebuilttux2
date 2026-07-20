#!/bin/sh
# Advanced automated full-disk installer for RebuiltTux
# Adds support for: swap, LVM, LUKS encryption, debootstrap (Debian-style), and GRUB install.

set -e

echo "RebuiltTux Advanced Automated Installer"

# Show devices
if command -v lsblk >/dev/null 2>&1; then
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
else
  ls -l /dev | head -n 200
fi

# Read target disk
printf "\nEnter target disk (e.g. /dev/sda) for full-disk install: "
read TARGET_DISK
[ -b "$TARGET_DISK" ] || { echo "Invalid disk: $TARGET_DISK"; exit 1; }

printf "This will erase all data on $TARGET_DISK. Type YES to continue: "
read CONFIRM
[ "$CONFIRM" = "YES" ] || { echo "Aborting."; exit 1; }

# Options: encryption, lvm, swap size, filesystem, distro suite
printf "Use LUKS encryption for root? [y/N]: "
read USE_LUKS
printf "Use LVM on top of (plain or LUKS)? [y/N]: "
read USE_LVM
printf "Swap size (e.g. 2G or 0 for none) [default 2G]: "
read SWAP_SIZE
SWAP_SIZE=${SWAP_SIZE:-2G}
printf "Root filesystem (ext4/btrfs) [default ext4]: "
read FS_CHOICE
FS_CHOICE=${FS_CHOICE:-ext4}
printf "Debian suite to bootstrap (stable/bookworm/testing) [default stable]: "
read DEBOOTSTRAP_SUITE
DEBOOTSTRAP_SUITE=${DEBOOTSTRAP_SUITE:-stable}

# Wipe and partition: GPT with 3 partitions (EFI, boot, rest) when LUKS used, else EFI + root
if command -v parted >/dev/null 2>&1; then
  parted -s "$TARGET_DISK" mklabel gpt
  parted -s -a optimal "$TARGET_DISK" mkpart primary fat32 1MiB 513MiB
  parted -s "$TARGET_DISK" set 1 boot on
  if [ "${USE_LUKS}" = "y" ] || [ "${USE_LUKS}" = "Y" ]; then
    parted -s -a optimal "$TARGET_DISK" mkpart primary ext4 513MiB 1025MiB
    parted -s -a optimal "$TARGET_DISK" mkpart primary 1025MiB 100%
    BOOT_PART="${TARGET_DISK}2"
    CRYPT_PART="${TARGET_DISK}3"
  else
    parted -s -a optimal "$TARGET_DISK" mkpart primary ext4 513MiB 100%
    BOOT_PART="${TARGET_DISK}2"
    ROOT_PART="${TARGET_DISK}2"
  fi
  EFI_PART="${TARGET_DISK}1"
else
  echo "parted not available. Installer requires parted or sgdisk/sfdisk. Aborting."
  exit 1
fi

sleep 2

# Format EFI
if command -v mkfs.vfat >/dev/null 2>&1; then
  mkfs.vfat -F32 "$EFI_PART"
else
  echo "mkfs.vfat not found; attempting busybox mkfs.vfat"
  [ -x /bin/busybox ] && /bin/busybox mkfs.vfat -F 32 "$EFI_PART" || true
fi

# If LUKS chosen, create LUKS container and open it
if [ "${USE_LUKS}" = "y" ] || [ "${USE_LUKS}" = "Y" ]; then
  if ! command -v cryptsetup >/dev/null 2>&1; then
    echo "cryptsetup not available in live environment. Please include cryptsetup in tools/. Aborting."
    exit 1
  fi
  printf "Enter a passphrase for LUKS root (input will be echoed): "
  read LUKS_PW
  cryptsetup luksFormat "$CRYPT_PART" <<EOF
$LUKS_PW
EOF
  cryptsetup luksOpen "$CRYPT_PART" cryptroot --key-file=- <<EOF
$LUKS_PW
EOF
  LUKS_DEV="/dev/mapper/cryptroot"
fi

# LVM support
if [ "${USE_LVM}" = "y" ] || [ "${USE_LVM}" = "Y" ]; then
  if ! command -v pvcreate >/dev/null 2>&1 || ! command -v vgcreate >/dev/null 2>&1 || ! command -v lvcreate >/dev/null 2>&1; then
    echo "LVM tools not found in environment. Please include lvm2 tools in tools/. Aborting."
    exit 1
  fi
  if [ -n "$LUKS_DEV" ]; then
    pvcreate "$LUKS_DEV"
    vgcreate vg_root "$LUKS_DEV"
  else
    pvcreate "$ROOT_PART"
    vgcreate vg_root "$ROOT_PART"
  fi
  # create root LV and swap LV
  if [ "$SWAP_SIZE" != "0" ]; then
    lvcreate -L "$SWAP_SIZE" -n lv_swap vg_root
  fi
  lvcreate -l 100%FREE -n lv_root vg_root
  ROOT_LV="/dev/vg_root/lv_root"
  SWAP_LV="/dev/vg_root/lv_swap"
fi

# Format boot and root
if [ -n "$BOOT_PART" ]; then
  mkfs.ext4 -F "$BOOT_PART" || true
fi

if [ -n "$ROOT_LV" ]; then
  if [ "$FS_CHOICE" = "btrfs" ]; then
    mkfs.btrfs -f "$ROOT_LV" || mkfs.ext4 -F "$ROOT_LV"
  else
    mkfs.ext4 -F "$ROOT_LV"
  fi
  ROOT_DEV="$ROOT_LV"
elif [ -n "$LUKS_DEV" ]; then
  if [ "$FS_CHOICE" = "btrfs" ]; then
    mkfs.btrfs -f "$LUKS_DEV" || mkfs.ext4 -F "$LUKS_DEV"
  else
    mkfs.ext4 -F "$LUKS_DEV"
  fi
  ROOT_DEV="$LUKS_DEV"
elif [ -n "$ROOT_PART" ]; then
  if [ "$FS_CHOICE" = "btrfs" ]; then
    mkfs.btrfs -f "$ROOT_PART" || mkfs.ext4 -F "$ROOT_PART"
  else
    mkfs.ext4 -F "$ROOT_PART"
  fi
  ROOT_DEV="$ROOT_PART"
else
  echo "No root device available. Aborting."
  exit 1
fi

# Setup swap
if [ "$SWAP_SIZE" != "0" ]; then
  if [ -n "$SWAP_LV" ]; then
    mkswap "$SWAP_LV" || true
    swapon "$SWAP_LV" || true
  else
    # create swap file on root
    mkdir -p /mnt/target
    mount "$ROOT_DEV" /mnt/target
    fallocate -l "$SWAP_SIZE" /mnt/target/swapfile || dd if=/dev/zero of=/mnt/target/swapfile bs=1M count=0 || true
    mkswap /mnt/target/swapfile || true
    swapon /mnt/target/swapfile || true
    umount /mnt/target
  fi
fi

# Mount target filesystems
mkdir -p /mnt/target
mount "$ROOT_DEV" /mnt/target
[ -n "$BOOT_PART" ] && mkdir -p /mnt/target/boot && mount "$BOOT_PART" /mnt/target/boot
mkdir -p /mnt/target/boot/efi && mount "$EFI_PART" /mnt/target/boot/efi

# Bootstrap a Debian-style root using debootstrap if available
if command -v debootstrap >/dev/null 2>&1; then
  echo "Running debootstrap ($DEBOOTSTRAP_SUITE)..."
  debootstrap --arch amd64 "$DEBOOTSTRAP_SUITE" /mnt/target http://deb.debian.org/debian || true
  # Minimal chroot config
  mount --bind /dev /mnt/target/dev || true
  mount --bind /proc /mnt/target/proc || true
  mount --bind /sys /mnt/target/sys || true
  chroot /mnt/target /bin/sh -c "echo 'deb http://deb.debian.org/debian $DEBOOTSTRAP_SUITE main contrib non-free' > /etc/apt/sources.list"
  chroot /mnt/target /bin/sh -c "apt-get update || true"
  chroot /mnt/target /bin/sh -c "apt-get install -y --no-install-recommends linux-image-amd64 grub-pc grub-efi-amd64 cryptsetup lvm2 || true"
else
  echo "debootstrap not found. Skipping package bootstrap — installer will still create a minimal BusyBox-based root."
  mkdir -p /mnt/target/{bin,sbin,etc,proc,sys,usr,lib,var,home,root,tmp}
  if [ -x /bin/busybox ]; then
    cp /bin/busybox /mnt/target/bin/
    chmod +x /mnt/target/bin/busybox
    chroot /mnt/target /bin/busybox --install -s /bin || true
  fi
fi

# Setup fstab and crypttab
if command -v blkid >/dev/null 2>&1; then
  ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEV" || true)
  EFI_UUID=$(blkid -s UUID -o value "$EFI_PART" || true)
fi
cat > /mnt/target/etc/fstab <<'FST'
# <file system> <mount point> <type> <options> <dump> <pass>
__ROOT_ENTRY__
UUID=__EFI_UUID__ /boot/efi vfat umask=0077 0 1
FST

if [ -n "$ROOT_UUID" ]; then
  if [ -n "$LUKS_DEV" ]; then
    ROOT_ENTRY="/dev/mapper/cryptroot / ext4 defaults 0 1"
  else
    ROOT_ENTRY="UUID=$ROOT_UUID / ext4 defaults 0 1"
  fi
  sed -i "s#__ROOT_ENTRY__#$ROOT_ENTRY#" /mnt/target/etc/fstab
fi

if [ -n "$LUKS_DEV" ]; then
  cat > /mnt/target/etc/crypttab <<EOF
cryptroot UUID=$(blkid -s UUID -o value "$CRYPT_PART") none luks
EOF
fi

# Hostname and marker
echo "rebuilttux" > /mnt/target/etc/hostname
mkdir -p /mnt/target/etc
echo "RebuiltTux" > /mnt/target/etc/rebuilttux-installed

# Attempt to install grub from live environment into the new system
if command -v grub-install >/dev/null 2>&1; then
  echo "Attempting grub-install into target..."
  mount --bind /dev /mnt/target/dev || true
  mount --bind /proc /mnt/target/proc || true
  mount --bind /sys /mnt/target/sys || true
  if [ -d /sys/firmware/efi ]; then
    grub-install --target=x86_64-efi --efi-directory=/mnt/target/boot/efi --boot-directory=/mnt/target/boot --removable --root-directory=/mnt/target || true
  else
    grub-install --boot-directory=/mnt/target/boot "$TARGET_DISK" || true
  fi
  umount /mnt/target/dev || true
  umount /mnt/target/proc || true
  umount /mnt/target/sys || true
else
  echo "grub-install not found in live environment. Please install a bootloader manually after reboot, or include grub-install in tools/."
fi

# Create user
printf "Enter a username to create (default 'user'): "
read USERNAME
USERNAME=${USERNAME:-user}
if chroot /mnt/target sh -c 'command -v adduser >/dev/null 2>&1'; then
  chroot /mnt/target adduser -D "$USERNAME" || true
else
  echo "$USERNAME:x:1000:1000::/home/$USERNAME:/bin/sh" >> /mnt/target/etc/passwd
  mkdir -p /mnt/target/home/$USERNAME
  chown 1000:1000 /mnt/target/home/$USERNAME || true
fi

sync
umount /mnt/target/boot/efi || true
[ -n "$BOOT_PART" ] && umount /mnt/target/boot || true
umount /mnt/target || true

echo "Installation finished. Reboot and remove the ISO to boot into the installed system."
