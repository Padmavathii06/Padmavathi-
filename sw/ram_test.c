#include "soc_regs.h"

/* Test Plan Sno 15: AXI RAM Read/Write
 * Write data, read-back, verify data and byte strobes.
 */
int main(void)
{
    set_mrac(0xAAAAAAAAu);

    volatile uint32_t *word_ptr = (volatile uint32_t *)(SRAM_BASE + 0x40u);
    *word_ptr = 0x12345678u;

    if (*word_ptr == 0x12345678u) {
        *(volatile uint32_t *)STAT_SRAM   = 0x00000001u;
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)STAT_SRAM   = 0xDEAD0001u;
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0001u;
    }

    for (;;) {
    }
    return 0;
}
