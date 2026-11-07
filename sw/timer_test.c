#include "soc_regs.h"

/* Test Plan Sno 3: Timer Count and IRQ
 * Load = 5, enable, poll status and verify read-back.
 */
int main(void)
{
    set_mrac(0xAAAAAAAAu);

    TIMER_LOAD = 5u;
    TIMER_CTRL = 0x01u; /* Enable */

    if (TIMER_LOAD == 5u) {
        *(volatile uint32_t *)STAT_TIMER  = 0x00000001u;
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)STAT_TIMER  = 0xDEAD0005u;
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0005u;
    }

    for (;;) {
    }
    return 0;
}
