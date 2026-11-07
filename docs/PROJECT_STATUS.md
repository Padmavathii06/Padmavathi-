# Project Status — RISC-V VeeR EL2 SoC

Last updated: 2026-11-07

## 1. Executive Summary

Full end-to-end integration and hardware verification of the genuine Western Digital / CHIPS Alliance RISC-V VeeR EL2 CPU inside the Padmavathi SoC fabric has been completed and verified using Synopsys VCS Full64 on Rocky Linux 8.10 (`vlsi24.vce.ac.in`):
- **CPU Hierarchy Elaboration**: Genuine VeeR EL2 core (`el2_veer_wrapper`) with DCCM/ICCM/ICache SRAM macros and dual 64-to-32 AXI width adapters elaborates and compiles cleanly in VCS Full64.
- **CPU Firmware Execution**: CPU boots from reset vector `0x1000_0000` (SoC Boot ROM), fetches instructions over AXI, executes compiled C code (`sw/test.c`), retires instructions, and writes signature `0xC0FFEE00` into SoC SRAM at address `0x0000_0100` (`mem[64]`).
- **Subsystem Regression**: All 10 peripheral, interconnect, and memory subsystem testbenches compile and pass under VCS Full64 and Icarus Verilog.
- **Software Cross-Compilation**: RISC-V GCC 15.2.0 (xPack rv32imc) compiles `sw/test.c` + `sw/start.S` with `sw/link.ld` (ROM at `0x1000_0000`, RAM at `0x0000_0000`). Flat binary extracted, word-addressed hex generated (`sw/test.hex`), and copied to `rtl/soc/bootrom.hex`.
- **Hardware Architecture Note**: There is NO dedicated hardware Watchdog Timer peripheral in this SoC design. The watchdog timeout in the testbench is strictly a simulation safety mechanism.

## 2. Environment Verification

- **Workstation**: `vlsi24.vce.ac.in` (Rocky Linux 8.10 Green Obsidian).
- **HDL Simulator**: Synopsys VCS U-2023.03 (Full64) & Verdi U-2023.03-SP1.
- **Cross-Compiler**: xPack GNU RISC-V Embedded GCC 15.2.0-1 (`riscv-none-elf-gcc`).
- **Target Core**: Genuine RISC-V VeeR EL2 (`el2_veer_wrapper.sv`).

## 3. Subsystem Implementation & Verification Matrix

| Subsystem / Module | RTL Source | Testbench | Simulator | Result |
|---|---|---|---|:---:|
| **CRU Reset Controller** | `rtl/soc/cru.v` | `tb/tb_cru_reset.sv` | VCS / Icarus | **PASS** |
| **AXI4-Lite Test IP** | `rtl/interconnect/axi_lite_test_ip.v` | `tb/tb_axi_lite_test_ip.sv` | VCS / Icarus | **PASS** |
| **IPU Configuration Block** | `rtl/interconnect/ipu_config.v` | `tb/tb_ipu_config.sv` | VCS / Icarus | **PASS** |
| **AXI4-to-APB Bridge** | `rtl/interconnect/axi_apb_bridge.v` | `tb/tb_axi_apb_bridge.sv` | VCS / Icarus | **PASS** |
| **APB Peripherals Subsystem** | `rtl/interconnect/apb_peripherals.v` | `tb/tb_apb_peripherals.sv` | VCS / Icarus | **PASS** |
| **JTAG DMI Debug Module** | `rtl/debug/jtag_dmi.v` | `tb/tb_jtag_dmi.sv` | VCS / Icarus | **PASS** |
| **DMA + IPU Crossbar Loopback** | `rtl/interconnect/dma_controller.v` | `tb/tb_dma_ipu_loopback.sv` | VCS / Icarus | **PASS** |
| **4x4 Interconnect Crossbar** | `rtl/interconnect/axi_interconnect.v` + `wrap_4x4.v` | `tb/tb_axi_interconnect_4x4.sv` | VCS / Icarus | **PASS** |
| **Full Integrated SoC Top** | `rtl/soc/soc_top.v` | `tb/tb_soc_top.sv` | VCS / Icarus | **PASS** |
| **VeeR EL2 Real CPU Integration** | `rtl/soc/veer_cpu_wrapper.sv` | `tb/tb_soc_veer_cpu.sv` | Synopsys VCS | **PASS** |

## 4. VeeR EL2 CPU Firmware Simulation Evidence

Executed target: `make sim-veer-cpu`
- **Reset Vector**: `0x1000_0000` (SoC Boot ROM).
- **Instructions Retired**: 122 instructions retired through core pipeline.
- **IFU Fetches**: 202 fetch requests serviced by Boot ROM.
- **LSU Stores**: 24 store requests to SoC SRAM & MMIO peripherals.
- **Observed Signature**: SRAM index 64 (`0x0000_0100`) = `0xC0FFEE00`.
- **Subsystem Breakdown**:
  1. System SRAM R/W (`0x0000_0104`): `0x00000001` (PASS)
  2. Boot ROM Read (`0x0000_0108`): `0x00000001` (PASS)
  3. IPU Config Block (`0x0000_010C`): `0x00000001` (PASS)
  4. APB GPIO (`0x0000_0110`): `0x00000001` (PASS)
  5. APB Timer (`0x0000_0114`): `0x00000001` (PASS)
  6. APB UART (`0x0000_0118`): `0x00000001` (PASS)
  7. APB SPI (`0x0000_011C`): `0x00000001` (PASS)
  8. APB PIC (`0x0000_0120`): `0x00000001` (PASS)
  - **Total Tests Passed**: 8 / 8 (`0x0000_0124` = 8).
- **Termination**: `$finish` at simulation time `22985000 ps` with status `*** SIMULATION PASSED ***`.

## 5. Build Automation Targets

All targets are automated in the root `Makefile`:
- `make sim-veer-cpu`: Compiles and runs the full VeeR EL2 CPU firmware simulation in Synopsys VCS.
- `make run-soc`: Executes full integrated SoC memory-map simulation with Synopsys VCS.
- `make run-soc-full`: Comprehensive VCS regression with full code coverage.
- `make c-test`: Compiles RISC-V software with RV32IMC GCC.
- `make hex`: Generates `sw/test.hex`.
- `make bootrom`: Updates `rtl/soc/bootrom.hex` from compiled C test.
- `make clean`: Cleans build products and temporary artifacts.
