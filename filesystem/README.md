# RebuiltTux2 Filesystem Support

This directory tracks filesystem support planned for RebuiltTux2.

## Supported / Planned Linux Filesystems

- ext2 - classic Linux filesystem
- ext3 - ext2 with journaling
- ext4 - modern default Linux filesystem
- btrfs - copy-on-write filesystem
- xfs - high performance filesystem
- jfs - IBM journaling filesystem
- f2fs - flash-friendly filesystem
- squashfs - compressed read-only filesystem (useful for live ISOs)
- tmpfs - memory-backed temporary filesystem
- overlayfs - layered filesystem support
- iso9660 - CD/DVD ISO filesystem support
- vfat - FAT32 compatibility
- exfat - modern removable storage filesystem
- ntfs - Windows filesystem compatibility

## Driver Layout

Future filesystem drivers can be placed here:

```
filesystem/
 ├── ext4/
 ├── btrfs/
 ├── squashfs/
 └── vfs/
```

## Note

These are the planned filesystem interfaces. Actual kernel drivers will be added as RebuiltTux2 develops.
