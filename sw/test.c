#include <stdint.h>

/* Assumed scratch location in system SRAM for the observable result. */
#define RESULT_ADDR 0x00000100u

int main(void)
{
    volatile uint32_t *result = (volatile uint32_t *)RESULT_ADDR;
    *result = 0xC0FFEE00u;

    /* Spin forever; the testbench observes RESULT_ADDR. */
    for (;;) {
    }
    return 0;
}
