#include "ext2.h"

static int ext2_read_superblock(struct vfs_node* device)
{
    // TODO: Read block 1024 and parse the ext2 superblock
    // Check for EXT2_MAGIC before mounting
    return 0;
}

int ext2_mount(struct vfs_node* device)
{
    if (ext2_read_superblock(device) == 0)
        return 0;

    return -1;
}

static int ext2_read(struct vfs_node* node, uint32_t offset, uint32_t size, uint8_t* buffer)
{
    // TODO: inode and block lookup
    return 0;
}

static int ext2_write(struct vfs_node* node, uint32_t offset, uint32_t size, uint8_t* buffer)
{
    // TODO: ext2 write support
    return -1;
}

struct filesystem_driver ext2_driver = {
    .name = "ext2",
    .mount = ext2_mount,
    .read = ext2_read,
    .write = ext2_write,
    .readdir = 0
};
