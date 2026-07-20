#include "mem.h"

static struct memory_block* heap_start;

void memory_init(uint32_t start, uint32_t size)
{
    heap_start = (struct memory_block*)start;
    heap_start->address = start;
    heap_start->size = size;
    heap_start->free = 1;
    heap_start->next = 0;
}

void* kmalloc(uint32_t size)
{
    struct memory_block* current = heap_start;

    while (current)
    {
        if (current->free && current->size >= size)
        {
            current->free = 0;
            return (void*)(current->address + sizeof(struct memory_block));
        }
        current = current->next;
    }

    return 0;
}

void kfree(void* ptr)
{
    if (!ptr)
        return;

    struct memory_block* block = (struct memory_block*)((uint32_t)ptr - sizeof(struct memory_block));
    block->free = 1;
}
