# Verification Guide — RISC-V VeeR EL2 SoC

Last Updated: 2026-11-02

## 1. Simulation Environments

Two simulation environments are supported:
1. **Local Cross-Platform Environment (Icarus Verilog 14.0)**:
   - Uses open-source `iverilog` and `vvp`.
   - Used for verifying all SoC peripheral RTL, interconnect crossbar, CRU, memory models, and integrated top-level fabric without commercial licenses.
2. **College Production Environment (Synopsys VCS + Verdi)**:
   - Uses Synopsys VCS U-2023.03 and Verdi U-2023.03-SP1.
   - Required for full SystemVerilog IEEE 1800-2017 features (interface modports in VeeR EL2 core `el2_mem_if.sv` and `el2_veer_wrapper.sv`).

## 2. Test Execution Commands & Real Results

All tests have been run and verified:

```bash
# Run all 9 Icarus Verilog tests in a single command
make sim-all
```

### Verified Test Results Summary

| Target | Command | Testbench File | Status | Notes |
|---|---|---|---|---|
| `sim-cru` | `make sim-cru` | `tb/tb_cru_reset.sv` | **PASS** | Sequences reset release after 8 clock cycles |
| `sim-axilite` | `make sim-axilite` | `tb/tb_axi_lite_test_ip.sv` | **PASS** | R/W registers CONTROL, DATA_A, DATA_B, RESULT |
| `sim-ipu` | `make sim-ipu` | `tb/tb_ipu_config.sv` | **PASS** | 9 test cases: defaults, byte strobes, decoupled AW/W, SLVERR |
| `sim-axi-apb` | `make sim-axi-apb` | `tb/tb_axi_apb_bridge.sv` | **PASS** | 13 test cases: APB wait states, PSLVERR propagation, bursts |
| `sim-apb` | `make sim-apb` | `tb/tb_apb_peripherals.sv` | **PASS** | Exercises UART, SPI, GPIO, Timer, PIC registers |
| `sim-debug` | `make sim-debug` | `tb/tb_jtag_dmi.sv` | **PASS** | DMI register reads and writes over JTAG TAP |
| `sim-loopback` | `make sim-loopback` | `tb/tb_dma_ipu_loopback.sv` | **PASS** | DMA memory-to-memory copy across 4x4 crossbar to SRAM |
| `sim-xbar` | `make sim-xbar` | `tb/tb_axi_interconnect_4x4.sv` | **PASS** | 6 test cases: 4x4 matrix R/W, DECERR on unmapped, arbitration |
| `sim-soc` | `make sim-soc` | `tb/tb_soc_top.sv` | **PASS** | Full integration: SRAM, Boot ROM, IPU config, APB Timer |

### Observable Integrated SoC Checks (`tb/tb_soc_top.sv`)
- **Test 1 (System SRAM)**: Write `0xCAFEBABE` to `0x0000_0040`, read back `0xCAFEBABE`.
- **Test 2 (Boot ROM)**: Read `0x1000_0000` -> returns `0xf0040117` (`auipc sp, 0xf0040`), read `0x1000_0004` -> returns `0x00010113` (`mv sp, sp`).
- **Test 3 (IPU Config)**: Write `1920` to `IPU_FRAME_WIDTH` (`0x2000_0008`), read back `1920`.
- **Test 4 (APB Timer)**: Write `0x0000_5678` to Timer LOAD (`0x3000_0300`), read back `0x0000_5678`.

## 3. Software Cross-Compilation & Verification

```bash
# Build C test, generate flat binary and word-addressed hex
make c-test
make hex

# Synchronize Boot ROM with compiled firmware
make bootrom
```

Toolchain: xPack GNU RISC-V Embedded GCC 15.2.0 (`-march=rv32imc -mabi=ilp32`).
- Entry point: `_start` at `0x1000_0000` (Reset vector in Boot ROM).
- Observable PASS condition: `main()` stores `0xC0FFEE00` to `0x0000_0100` (SRAM).
- Disassembly verified with `riscv-none-elf-objdump -d sw/test.elf`.

## 4. College VCS Regression Commands

```bash
# In the Linux college environment with Synopsys VCS:
make run-soc-full     # Full SoC coverage simulation
make run-xbar         # Interconnect crossbar regression
make run-loopback     # DMA/IPU loopback regression
```
