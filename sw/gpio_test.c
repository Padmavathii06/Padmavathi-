#include "soc_regs.h"

/* Test Plan Sno 2: GPIO Direction and Output
 * Set dir = 0xFF, out = 0x3C, and read back to verify.
 */
int main(void)
{
    set_mrac(0xAAAAAAAAu);

    GPIO_DIR = 0xFFu;
    GPIO_OUT = 0x3Cu;

    if ((GPIO_DIR & 0xFFu) == 0xFFu && (GPIO_OUT & 0xFFu) == 0x3Cu) {
        *(volatile uint32_t *)STAT_GPIO   = 0x00000001u;
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)STAT_GPIO   = 0xDEAD0004u;
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0004u;
    }

    for (;;) {
    }
    return 0;
}
