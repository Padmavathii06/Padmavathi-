#include "soc_regs.h"

/* Test Plan Sno 5: SPI Data Register
 * Write 0xAA, read-back and verify.
 */
int main(void)
{
    set_mrac(0xAAAAAAAAu);

    SPI_TXDATA = 0xAAu;
    SPI_CTRL   = 0x03u;

    if (SPI_TXDATA == 0xAAu && SPI_CTRL == 0x03u) {
        *(volatile uint32_t *)STAT_SPI    = 0x00000001u;
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)STAT_SPI    = 0xDEAD0007u;
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0007u;
    }

    for (;;) {
    }
    return 0;
}
