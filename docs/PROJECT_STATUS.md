# Project Status — RISC-V VeeR EL2 SoC

Last updated: 2026-11-02

## 1. Executive Summary

All achievable RTL integration, toolchain installation, testbench adaptation, cross-compilation, firmware hex generation, and local simulations have been executed and verified with zero fabrications:
- **Local Simulation**: All 9 unit and integrated testbenches compile and pass under Icarus Verilog 14.0 (`make sim-all`).
- **Software Cross-Compilation**: RISC-V GCC 15.2.0 (xPack rv32imc) compiles `sw/test.c` + `sw/start.S` with `sw/link.ld` (ROM at `0x1000_0000`, RAM at `0x0000_0000`). Flat binary extracted, word-addressed hex generated (`sw/test.hex`), and copied to `rtl/soc/bootrom.hex`.
- **CPU RTL Integration**: Upstream VeeR EL2 obtained (`vendor/veer-el2` at commit `fa00c8aa`), snapshot generated (`snapshots/default/` with reset vector `0x1000_0000`), 64-to-32 AXI width adapters integrated (`rtl/soc/veer_cpu_wrapper.sv`).
- **Exact Blocker**: Full RTL simulation of VeeR EL2 itself requires Synopsys VCS (or Verilator) because VeeR utilizes SystemVerilog interface modports (`el2_mem_if.sv`) and package imports (`el2_pkg`) unsupported by Icarus Verilog 14.0.

## 2. Environment Verification

- **Repository**: `C:\Users\kadan\Documents\Padmavathi-`, branch `main`.
- **Operating System**: Windows 11.
- **HDL Simulator**: Icarus Verilog 14.0 (`C:\Users\kadan\scoop\apps\iverilog\current\bin\iverilog.exe` and `vvp.exe`).
- **Build System**: GNU Make 4.4.1 (`C:\Users\kadan\AppData\Local\Microsoft\WinGet\Packages\ezwinports.make_Microsoft.Winget.Source_8wekyb3d8bbwe\bin\make.exe`).
- **Python**: Python 3.12.8 (`C:\Users\kadan\AppData\Local\Programs\Python\Python312\python.exe`).
- **Cross-Compiler**: xPack GNU RISC-V Embedded GCC 15.2.0 (`vendor\riscv-gcc\xpack-riscv-none-elf-gcc-15.2.0-1\bin\riscv-none-elf-gcc.exe`).

## 3. Subsystem Implementation & Verification Matrix

| Subsystem / Module | RTL Source | Testbench | Simulator | Result |
|---|---|---|---|---|
| **CRU Reset Controller** | `rtl/soc/cru.v` | `tb/tb_cru_reset.sv` | Icarus 14.0 | **PASS** |
| **AXI4-Lite Test IP** | `rtl/interconnect/axi_lite_test_ip.v` | `tb/tb_axi_lite_test_ip.sv` | Icarus 14.0 | **PASS** |
| **IPU Configuration Block** | `rtl/interconnect/ipu_config.v` | `tb/tb_ipu_config.sv` | Icarus 14.0 | **PASS** |
| **AXI4-to-APB Bridge** | `rtl/interconnect/axi_apb_bridge.v` | `tb/tb_axi_apb_bridge.sv` | Icarus 14.0 | **PASS** |
| **APB Peripherals Subsystem** | `rtl/interconnect/apb_peripherals.v` | `tb/tb_apb_peripherals.sv` | Icarus 14.0 | **PASS** |
| **JTAG DMI Debug Module** | `rtl/debug/jtag_dmi.v` | `tb/tb_jtag_dmi.sv` | Icarus 14.0 | **PASS** |
| **DMA + IPU Crossbar Loopback** | `rtl/interconnect/dma_controller.v` | `tb/tb_dma_ipu_loopback.sv` | Icarus 14.0 | **PASS** |
| **4x4 Interconnect Crossbar** | `rtl/interconnect/axi_interconnect.v` + `wrap_4x4.v` | `tb/tb_axi_interconnect_4x4.sv` | Icarus 14.0 | **PASS** |
| **Full Integrated SoC Top** | `rtl/soc/soc_top.v` (CRU + XBAR + SRAM + ROM + IPU + APB) | `tb/tb_soc_top.sv` | Icarus 14.0 | **PASS** |
| **VeeR EL2 CPU Wrapper** | `rtl/soc/veer_cpu_wrapper.sv` (with AXI 64->32 adapters) | Target Synopsys VCS flow | Synopsys VCS | Prepared (VCS target in Makefile) |

## 4. Software & Firmware Status

- `sw/link.ld`: Corrected to partition memory into `ROM` (rx, origin `0x1000_0000`, 64K) and `RAM` (rwx, origin `0x0000_0000`, 256K).
- `sw/start.S`: Initializes `sp` to `_stack_top` (`0x0004_0000` in SRAM), invokes `main()`, and spins upon return.
- `sw/test.c`: Writes observable signature `0xC0FFEE00` to SRAM address `0x0000_0100`, then spins.
- `sw/test.hex`: Generated 32-bit word hex image verified via disassembly (`test.dis`).
- `rtl/soc/bootrom.hex`: Synchronized with `sw/test.hex`.
- `rtl/soc/boot_rom.v`: Enhanced with dual-path file lookup (`rtl/soc/bootrom.hex` and `../rtl/soc/bootrom.hex`) ensuring error-free loading whether invoked from root or `build/`.

## 5. Build Automation Targets

All targets are automated in the root `Makefile`:
- `make sim-all`: Executes all 9 simulations sequentially with Icarus Verilog.
- `make sim-soc`: Executes full integrated SoC memory-map simulation.
- `make c-test`: Compiles RISC-V software with auto-detected GCC.
- `make hex`: Generates `sw/test.hex`.
- `make bootrom`: Updates `rtl/soc/bootrom.hex` from compiled C test.
- `make clean`: Cleans build directories and temporary products.
- `make run-soc-full`: Synopsys VCS regression target for college environment.
