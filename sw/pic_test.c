#include "soc_regs.h"

/* Test Plan Sno 6: PIC Interrupt Mask
 * Write 0x1F, read-back and verify.
 */
int main(void)
{
    set_mrac(0xAAAAAAAAu);

    PIC_MASK = 0x1Fu;
    PIC_PRIO = 0x07u;

    if (PIC_MASK == 0x1Fu && PIC_PRIO == 0x07u) {
        *(volatile uint32_t *)STAT_PIC    = 0x00000001u;
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)STAT_PIC    = 0xDEAD0008u;
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0008u;
    }

    for (;;) {
    }
    return 0;
}
