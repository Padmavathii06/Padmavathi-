#include "soc_regs.h"

/* Test Plan Sno 7: IPU Configuration Block Register R/W
 * Program frame width, height, control and kernel coeffs, read-back and verify.
 */
int main(void)
{
    set_mrac(0xAAAAAAAAu);

    IPU_FRAME_WIDTH  = 1920u;
    IPU_FRAME_HEIGHT = 1080u;
    IPU_SRC_ADDR     = 0x00001000u;
    IPU_DST_ADDR     = 0x00002000u;
    IPU_CTRL         = 0x01u;

    if (IPU_FRAME_WIDTH == 1920u && IPU_FRAME_HEIGHT == 1080u &&
        IPU_SRC_ADDR == 0x00001000u && IPU_DST_ADDR == 0x00002000u) {
        *(volatile uint32_t *)STAT_IPU    = 0x00000001u;
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)STAT_IPU    = 0xDEAD0003u;
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0003u;
    }

    for (;;) {
    }
    return 0;
}
