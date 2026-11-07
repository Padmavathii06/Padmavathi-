#include "soc_regs.h"

/* Test Plan Sno 4: UART TX Data Register
 * Write 0x55, read-back and verify.
 */
int main(void)
{
    set_mrac(0xAAAAAAAAu);

    UART_TXDATA = 0x55u;
    UART_CTRL   = 0x01u;

    if (UART_TXDATA == 0x55u && UART_CTRL == 0x01u) {
        *(volatile uint32_t *)STAT_UART   = 0x00000001u;
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)STAT_UART   = 0xDEAD0006u;
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0006u;
    }

    for (;;) {
    }
    return 0;
}
