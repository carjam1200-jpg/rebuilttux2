#ifndef REBUILTTUX_VFS_DRIVER_H
#define REBUILTTUX_VFS_DRIVER_H

#include "vfs.h"

// Filesystem driver interface
struct filesystem_driver {
    char name[64];

    // Detect and mount a filesystem
    int (*mount)(struct vfs_node* device);

    // File operations
    int (*read)(struct vfs_node* node, uint32_t offset, uint32_t size, uint8_t* buffer);
    int (*write)(struct vfs_node* node, uint32_t offset, uint32_t size, uint8_t* buffer);

    // Directory operations
    int (*readdir)(struct vfs_node* node);
};

#endif
