#include "vfs.h"

#define MAX_FILESYSTEMS 16

// Registered filesystem driver table
static struct filesystem_driver* drivers[MAX_FILESYSTEMS];
static int driver_count = 0;

// Register a filesystem driver
int vfs_register(struct filesystem_driver* driver)
{
    if (driver_count >= MAX_FILESYSTEMS)
        return -1;

    drivers[driver_count++] = driver;
    return 0;
}

// Mount a filesystem device
int vfs_mount(struct vfs_node* device)
{
    for (int i = 0; i < driver_count; i++)
    {
        if (drivers[i]->mount(device) == 0)
            return 0;
    }

    return -1;
}

// Open a file through the VFS
int vfs_open(const char* path)
{
    // Filesystem lookup will be added here
    return 0;
}

// Close a file
int vfs_close(struct vfs_node* node)
{
    return 0;
}
