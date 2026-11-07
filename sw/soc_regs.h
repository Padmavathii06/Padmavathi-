#ifndef SOC_REGS_H
#define SOC_REGS_H

#include <stdint.h>

/* =========================================================================
 * SoC Memory Map Base Addresses
 * ========================================================================= */
#define SRAM_BASE        0x00000000u
#define BOOTROM_BASE     0x10000000u
#define IPU_BASE         0x20000000u
#define APB_BASE         0x30000000u

/* Scratchpad signature and test status locations in System SRAM */
#define RESULT_ADDR      0x00000100u  /* Overall status: 0xC0FFEE00 on pass */
#define STAT_SRAM        0x00000104u  /* SRAM test status */
#define STAT_ROM         0x00000108u  /* Boot ROM test status */
#define STAT_IPU         0x0000010Cu  /* IPU config test status */
#define STAT_GPIO        0x00000110u  /* GPIO test status */
#define STAT_TIMER       0x00000114u  /* Timer test status */
#define STAT_UART        0x00000118u  /* UART test status */
#define STAT_SPI         0x0000011Cu  /* SPI test status */
#define STAT_PIC         0x00000120u  /* PIC test status */
#define STAT_COUNT       0x00000124u  /* Total passed tests count */

#define TEST_PASS_SIG    0xC0FFEE00u

/* =========================================================================
 * APB Peripherals Base Addresses & Registers (0x3000_0000 base)
 * ========================================================================= */
/* UART Registers */
#define UART_CTRL        (*(volatile uint32_t *)(APB_BASE + 0x0000u))
#define UART_STATUS      (*(volatile uint32_t *)(APB_BASE + 0x0004u))
#define UART_TXDATA      (*(volatile uint32_t *)(APB_BASE + 0x0008u))
#define UART_RXDATA      (*(volatile uint32_t *)(APB_BASE + 0x000Cu))

/* SPI Registers */
#define SPI_CTRL         (*(volatile uint32_t *)(APB_BASE + 0x0100u))
#define SPI_STATUS       (*(volatile uint32_t *)(APB_BASE + 0x0104u))
#define SPI_TXDATA       (*(volatile uint32_t *)(APB_BASE + 0x0108u))
#define SPI_RXDATA       (*(volatile uint32_t *)(APB_BASE + 0x010Cu))

/* GPIO Registers */
#define GPIO_DIR         (*(volatile uint32_t *)(APB_BASE + 0x0200u))
#define GPIO_OUT         (*(volatile uint32_t *)(APB_BASE + 0x0204u))
#define GPIO_IN          (*(volatile uint32_t *)(APB_BASE + 0x0208u))
#define GPIO_IRQMASK     (*(volatile uint32_t *)(APB_BASE + 0x020Cu))

/* Timer Registers */
#define TIMER_LOAD       (*(volatile uint32_t *)(APB_BASE + 0x0300u))
#define TIMER_COUNT      (*(volatile uint32_t *)(APB_BASE + 0x0304u))
#define TIMER_CTRL       (*(volatile uint32_t *)(APB_BASE + 0x0308u))
#define TIMER_STATUS     (*(volatile uint32_t *)(APB_BASE + 0x030Cu))

/* PIC Registers */
#define PIC_MASK         (*(volatile uint32_t *)(APB_BASE + 0x0400u))
#define PIC_PEND         (*(volatile uint32_t *)(APB_BASE + 0x0404u))
#define PIC_PRIO         (*(volatile uint32_t *)(APB_BASE + 0x0408u))

/* =========================================================================
 * IPU Configuration Registers (0x2000_0000 base)
 * ========================================================================= */
#define IPU_CTRL         (*(volatile uint32_t *)(IPU_BASE + 0x00u))
#define IPU_STATUS       (*(volatile uint32_t *)(IPU_BASE + 0x04u))
#define IPU_FRAME_WIDTH  (*(volatile uint32_t *)(IPU_BASE + 0x08u))
#define IPU_FRAME_HEIGHT (*(volatile uint32_t *)(IPU_BASE + 0x0Cu))
#define IPU_SRC_ADDR     (*(volatile uint32_t *)(IPU_BASE + 0x10u))
#define IPU_DST_ADDR     (*(volatile uint32_t *)(IPU_BASE + 0x14u))
#define IPU_IRQ_MASK     (*(volatile uint32_t *)(IPU_BASE + 0x18u))
#define IPU_IRQ_STATUS   (*(volatile uint32_t *)(IPU_BASE + 0x1Cu))
#define IPU_KERNEL(i)    (*(volatile uint32_t *)(IPU_BASE + 0x20u + ((i) * 4u)))

/* Helper for setting MRAC (Machine Region Access Control) CSR 0x7C0 */
static inline void set_mrac(uint32_t val) {
    asm volatile ("csrw 0x7c0, %0" : : "r"(val));
}

#endif /* SOC_REGS_H */
