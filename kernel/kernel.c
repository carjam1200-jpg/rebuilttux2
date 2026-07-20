#include "memory/mem.h"

static void kernel_banner(void)
{
    // TODO: Replace with framebuffer/terminal output
}

void kernel_main(void)
{
    kernel_banner();

    // Initialize kernel heap
    memory_init(0x100000, 0x100000);

    // TODO:
    // - Initialize interrupts
    // - Start VFS
    // - Mount root filesystem
    // - Start userspace

    while (1)
    {
        __asm__ volatile("hlt");
    }
}
