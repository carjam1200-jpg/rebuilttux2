#ifndef REBUILTTUX_VFS_H
#define REBUILTTUX_VFS_H

#include <stdint.h>

// Basic filesystem node structure
struct vfs_node {
    char name[256];
    uint32_t flags;
    uint32_t size;

    int (*read)(struct vfs_node* node, uint32_t offset, uint32_t size, uint8_t* buffer);
    int (*write)(struct vfs_node* node, uint32_t offset, uint32_t size, uint8_t* buffer);
};

// Filesystem operations
int vfs_mount(struct vfs_node* device);
int vfs_open(const char* path);
int vfs_close(struct vfs_node* node);

#endif
