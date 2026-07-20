#ifndef REBUILTTUX_EXT2_H
#define REBUILTTUX_EXT2_H

#include "../vfs/vfs.h"
#include "../vfs/driver.h"
#include <stdint.h>

#define EXT2_MAGIC 0xEF53

struct ext2_superblock {
    uint32_t inode_count;
    uint32_t block_count;
    uint32_t free_blocks;
    uint32_t free_inodes;
    uint32_t first_data_block;
    uint32_t block_size;
    uint16_t magic;
};

int ext2_mount(struct vfs_node* device);
extern struct filesystem_driver ext2_driver;

#endif
