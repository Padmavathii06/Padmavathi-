# Test Plan - RISC-V VeeR EL2 SoC

| Sno. | Test Name | Description | Check Points | SV Tests | C Tests |
|------|-----------|-------------|--------------|----------|---------|
| 1 | APB Peripheral Register R/W | Verify read/write access to APB peripheral registers (GPIO, Timer, UART, SPI, PIC). | Register write/read-back matches; PREADY asserted; PSLVERR de-asserted for valid addresses. | `tb_apb_peripherals` (GPIO dir/out read-back, timer load/ctrl/status, UART txdata, SPI data, PIC mask) | C driver tests for GPIO, Timer, UART, SPI, PIC register access |
| 2 | GPIO Direction and Output | Verify GPIO direction register controls output enable and data register drives pins. | `gpio_dir` reflects written value; `gpio_out` reflects written value; `gpio_in` sampled correctly. | `tb_apb_peripherals` GPIO section | `gpio_test.c`: set dir=0xFF, out=0x3C, read-back |
| 3 | Timer Count and IRQ | Verify timer loads, counts down, and asserts IRQ on underflow. | Timer counts to zero; `timer_irq` asserted; status register reflects expiry. | `tb_apb_peripherals` Timer section | `timer_test.c`: load=5, enable+irq, poll status |
| 4 | UART TX Data Register | Verify UART TX data register write/read-back. | Written value readable from TX data register. | `tb_apb_peripherals` UART section | `uart_test.c`: write 0x55, read-back |
| 5 | SPI Data Register | Verify SPI data register write/read-back. | Written value readable from SPI data register. | `tb_apb_peripherals` SPI section | `spi_test.c`: write 0xAA, read-back |
| 6 | PIC Interrupt Mask | Verify PIC interrupt mask register write/read-back. | Written mask value readable. | `tb_apb_peripherals` PIC section | `pic_test.c`: write 0x1F, read-back |
| 7 | AXI4-Lite Register Slave | Verify AXI4-Lite test IP registers CONTROL, DATA_A, DATA_B, RESULT. | Write/read of all registers; bresp/rresp OKAY; RESULT computed correctly. | `tb_axi_lite_test_ip` | `axilite_test.c`: register R/W and RESULT check |
| 8 | AXI Interconnect Read Routing | Verify read access from every manager to every subordinate region. | Correct RID/RLAST/RRESP; data matches reset pattern; no mis-routing. | `tb_axi_interconnect_4x4` test 1 | `interconnect_read_test.c`: matrix read all 4x4 |
| 9 | AXI Interconnect Write/Read-Back | Verify write-then-read for every manager/subordinate pair. | AW/W/B and AR/R complete; write data read back correctly. | `tb_axi_interconnect_4x4` test 2 | `interconnect_wr_test.c`: all 16 pairs |
| 10 | AXI Interconnect DECERR (Unmapped) | Verify unmapped address returns DECERR on read and write. | RRESP/BRESP = 2'b11; no subordinate access. | `tb_axi_interconnect_4x4` test 3 | `decerr_test.c`: access 0x9000_0000 |
| 11 | AXI Interconnect Concurrent Arbitration (Distinct) | Verify concurrent requests from all four managers to distinct subordinates. | All transactions complete without data loss. | `tb_axi_interconnect_4x4` test 4 | `arb_distinct_test.c`: 4 concurrent |
| 12 | AXI Interconnect Concurrent Arbitration (Same Subordinate) | Verify concurrent requests from all four managers to same subordinate. | No data loss; correct ordering/response. | `tb_axi_interconnect_4x4` test 5 | `arb_same_test.c`: 4 to same sub |
| 13 | AXI Interconnect Protocol/Mis-routing Counters | Verify per-subordinate mis-routing and protocol-error counters are zero. | Counters == 0 at end of test. | `tb_axi_interconnect_4x4` | `interconnect_counters_test.c` |
| 14 | SoC Top-Level Smoke Test | Verify SoC top-level integration (CPU, interconnect, SRAM, ROM, APB bridge). | Boot, basic memory access, no X. | `tb_soc_top` (Makefile target `soc`) | `soc_smoke_test.c`: boot and memory probe |
| 15 | AXI RAM Read/Write | Verify AXI RAM supports read/write with correct data. | Write data readable; byte enables work. | `tb_soc_top` / dedicated | `ram_test.c`: read/write/byte-enable |
| 16 | Boot ROM Content | Verify boot ROM returns expected boot code. | Read returns valid instructions. | `tb_soc_top` | `bootrom_test.c`: read boot vector |
| 17 | AHB-APB Bridge | Verify AHB to APB bridge transfers. | Correct address/data transfer; PREADY handling. | `tb_apb_peripherals` (via bridge) | `ahb_apb_bridge_test.c` |
| 18 | Reset Behavior | Verify all modules reset to known state. | After reset, registers at default; no X. | All testbenches apply reset | `reset_test.c` |
| 19 | Interrupt Routing | Verify peripheral IRQs route to PIC and CPU. | `pic_irq_lines` reflects peripheral IRQs. | `tb_apb_peripherals` IRQ wiring | `irq_test.c`: trigger timer/uart/spi/gpio IRQs |
| 20 | End-to-End SoC Functional | Verify full SoC runs a small program from boot ROM. | Program completes; expected result. | `tb_soc_top` | `e2e_test.c`: run sample program |

---

Generated for VeeR EL2 SoC verification. SV tests refer to SystemVerilog testbenches under `tb/`; C tests refer to software tests running on the SoC.