# RebuiltTux2 Virtual File System (VFS)

The VFS layer provides a common interface between the kernel and filesystem drivers.

## Goals

- Allow multiple filesystem drivers
- Provide common file operations
- Hide filesystem-specific details from programs
- Support mounting filesystems

## Planned API

```
mount()
unmount()
open()
close()
read()
write()
mkdir()
readdir()
stat()
```

## Driver Model

Filesystem drivers register themselves with the VFS:

```
VFS
 |
 +-- ext2 driver
 +-- ext4 driver
 +-- btrfs driver
 +-- fat driver
 +-- squashfs driver
```

