#include "soc_regs.h"

int main(void)
{
    /* Set MRAC CSR 0x7C0:
     * Mark regions 0..15 as side-effect (device IO, non-cacheable).
     * This forces VeeR EL2 LSU to issue exact single-beat 32-bit AXI
     * transactions (awlen=0, arlen=0, awsize=2, arsize=2) to match
     * the APB bridge, IPU config, and SRAM without burst errors.
     */
    set_mrac(0xAAAAAAAAu);

    int errors = 0;
    uint32_t pass_count = 0;

    /* ---------------------------------------------------------------------
     * 1. System SRAM Test (0x0000_0040)
     * --------------------------------------------------------------------- */
    volatile uint32_t *sram_ptr = (volatile uint32_t *)(SRAM_BASE + 0x40u);
    *sram_ptr = 0xCAFEBABEu;
    if (*sram_ptr == 0xCAFEBABEu) {
        *(volatile uint32_t *)STAT_SRAM = 0x00000001u;
        pass_count++;
    } else {
        *(volatile uint32_t *)STAT_SRAM = 0xDEAD0001u;
        errors++;
    }

    /* ---------------------------------------------------------------------
     * 2. Boot ROM Read Test (0x1000_0000)
     * --------------------------------------------------------------------- */
    volatile uint32_t *rom_ptr = (volatile uint32_t *)BOOTROM_BASE;
    if (*rom_ptr == 0xf0040117u) {
        *(volatile uint32_t *)STAT_ROM = 0x00000001u;
        pass_count++;
    } else {
        *(volatile uint32_t *)STAT_ROM = 0xDEAD0002u;
        errors++;
    }

    /* ---------------------------------------------------------------------
     * 3. IPU Configuration Test (0x2000_0008, 0x2000_000C, 0x2000_0000)
     * --------------------------------------------------------------------- */
    IPU_FRAME_WIDTH  = 1920u;
    IPU_FRAME_HEIGHT = 1080u;
    IPU_CTRL         = 0x01u;
    if (IPU_FRAME_WIDTH == 1920u && IPU_FRAME_HEIGHT == 1080u) {
        *(volatile uint32_t *)STAT_IPU = 0x00000001u;
        pass_count++;
    } else {
        *(volatile uint32_t *)STAT_IPU = 0xDEAD0003u;
        errors++;
    }

    /* ---------------------------------------------------------------------
     * 4. APB GPIO Test (0x3000_0200) - Test Plan Sno 2: dir=0xFF, out=0x3C
     * --------------------------------------------------------------------- */
    GPIO_DIR = 0xFFu;
    GPIO_OUT = 0x3Cu;
    if ((GPIO_DIR & 0xFFu) == 0xFFu && (GPIO_OUT & 0xFFu) == 0x3Cu) {
        *(volatile uint32_t *)STAT_GPIO = 0x00000001u;
        pass_count++;
    } else {
        *(volatile uint32_t *)STAT_GPIO = 0xDEAD0004u;
        errors++;
    }

    /* ---------------------------------------------------------------------
     * 5. APB Timer Test (0x3000_0300) - Test Plan Sno 3: load=5, enable
     * --------------------------------------------------------------------- */
    TIMER_LOAD = 5u;
    TIMER_CTRL = 0x01u;
    if (TIMER_LOAD == 5u) {
        *(volatile uint32_t *)STAT_TIMER = 0x00000001u;
        pass_count++;
    } else {
        *(volatile uint32_t *)STAT_TIMER = 0xDEAD0005u;
        errors++;
    }

    /* ---------------------------------------------------------------------
     * 6. APB UART Test (0x3000_0000) - Test Plan Sno 4: write 0x55, read-back
     * --------------------------------------------------------------------- */
    UART_TXDATA = 0x55u;
    UART_CTRL   = 0x01u;
    if (UART_TXDATA == 0x55u && UART_CTRL == 0x01u) {
        *(volatile uint32_t *)STAT_UART = 0x00000001u;
        pass_count++;
    } else {
        *(volatile uint32_t *)STAT_UART = 0xDEAD0006u;
        errors++;
    }

    /* ---------------------------------------------------------------------
     * 7. APB SPI Test (0x3000_0100) - Test Plan Sno 5: write 0xAA, read-back
     * --------------------------------------------------------------------- */
    SPI_TXDATA = 0xAAu;
    SPI_CTRL   = 0x03u;
    if (SPI_TXDATA == 0xAAu && SPI_CTRL == 0x03u) {
        *(volatile uint32_t *)STAT_SPI = 0x00000001u;
        pass_count++;
    } else {
        *(volatile uint32_t *)STAT_SPI = 0xDEAD0007u;
        errors++;
    }

    /* ---------------------------------------------------------------------
     * 8. APB PIC Test (0x3000_0400) - Test Plan Sno 6: write 0x1F, read-back
     * --------------------------------------------------------------------- */
    PIC_MASK = 0x1Fu;
    PIC_PRIO = 0x07u;
    if (PIC_MASK == 0x1Fu && PIC_PRIO == 0x07u) {
        *(volatile uint32_t *)STAT_PIC = 0x00000001u;
        pass_count++;
    } else {
        *(volatile uint32_t *)STAT_PIC = 0xDEAD0008u;
        errors++;
    }

    /* Record total passed test count */
    *(volatile uint32_t *)STAT_COUNT = pass_count;

    /* ---------------------------------------------------------------------
     * Overall Result Signature
     * --------------------------------------------------------------------- */
    if (errors == 0 && pass_count == 8) {
        *(volatile uint32_t *)RESULT_ADDR = TEST_PASS_SIG; /* 0xC0FFEE00 */
    } else {
        *(volatile uint32_t *)RESULT_ADDR = 0xDEAD0000u | (uint32_t)errors;
    }

    /* Spin forever; the testbench observes RESULT_ADDR */
    for (;;) {
    }
    return 0;
}
