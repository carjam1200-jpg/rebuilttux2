#ifndef REBUILTTUX_MEMORY_H
#define REBUILTTUX_MEMORY_H

#include <stdint.h>

#define PAGE_SIZE 4096

struct memory_block {
    uint32_t address;
    uint32_t size;
    int free;
    struct memory_block* next;
};

void memory_init(uint32_t start, uint32_t size);
void* kmalloc(uint32_t size);
void kfree(void* ptr);

#endif
