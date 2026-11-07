#include "soc_regs.h"

/* Test Plan Sno 16: Boot ROM Content
 * Read boot vector word 0 and verify expected instruction pattern.
 */
int main(void)
{
    set_mrac(0xAAAAAAAAu);

    volatile uint32_t *rom_ptr = (volatile uint32_t *)BOOTROM_BASE;

    if (*rom_ptr == 0xf0040117u) {
        *(volatile uint32_t *)STAT_ROM    = 0x00000001u;
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)STAT_ROM    = 0xDEAD0002u;
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0002u;
    }

    for (;;) {
    }
    return 0;
}
