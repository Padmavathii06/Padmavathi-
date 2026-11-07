# Verification Guide — RISC-V VeeR EL2 SoC

Last Updated: 2026-11-07

## 1. Simulation Environments

Two simulation environments are supported:
1. **Local Cross-Platform Environment (Icarus Verilog 14.0)**:
   - Uses open-source `iverilog` and `vvp`.
   - Used for verifying all SoC peripheral RTL, interconnect crossbar, CRU, memory models, and integrated top-level fabric without commercial licenses.
2. **College Production Environment (Synopsys VCS + Verdi)**:
   - Uses Synopsys VCS U-2023.03 (Full64) and Verdi U-2023.03-SP1.
   - Required for full SystemVerilog IEEE 1800-2017 features (interface modports in VeeR EL2 core `el2_mem_if.sv` and `el2_veer_wrapper.sv`).

---

## 2. Test Execution Hierarchy & Status Matrix

| Layer | Verification Target | Testbench | Tool | Status | Pass Criteria & Evidence |
|---|---|---|---|:---:|---|
| **Subsystem** | CRU Reset Controller | `tb/tb_cru_reset.sv` | VCS / Icarus | **PASS** | Sequences reset release after 8 clock cycles |
| **Subsystem** | AXI4-Lite Test IP | `tb/tb_axi_lite_test_ip.sv` | VCS / Icarus | **PASS** | R/W registers CONTROL, DATA_A, DATA_B, RESULT |
| **Subsystem** | IPU Configuration Block | `tb/tb_ipu_config.sv` | VCS / Icarus | **PASS** | 9 test cases: defaults, byte strobes, decoupled AW/W |
| **Subsystem** | AXI4-to-APB Bridge | `tb/tb_axi_apb_bridge.sv` | VCS / Icarus | **PASS** | 13 test cases: APB wait states, PSLVERR propagation |
| **Subsystem** | APB Peripherals Subsystem | `tb/tb_apb_peripherals.sv` | VCS / Icarus | **PASS** | Exercises UART, SPI, GPIO, Timer, PIC registers |
| **Subsystem** | JTAG DMI Debug Module | `tb/tb_jtag_dmi.sv` | VCS / Icarus | **PASS** | DMI register reads and writes over JTAG TAP |
| **Subsystem** | DMA + IPU Crossbar Loopback | `tb/tb_dma_ipu_loopback.sv` | VCS / Icarus | **PASS** | DMA memory-to-memory copy across 4x4 crossbar |
| **Subsystem** | 4x4 Interconnect Crossbar | `tb/tb_axi_interconnect_4x4.sv` | VCS / Icarus | **PASS** | 6 test cases: 4x4 matrix R/W, DECERR, arbitration |
| **Subsystem** | Full Integrated SoC Top | `tb/tb_soc_top.sv` | VCS / Icarus | **PASS** | Integrated fabric test: SRAM, Boot ROM, IPU, APB |
| **CPU Elaboration** | Genuine VeeR EL2 Hierarchy | `build/soc_veer_cpu.f` | Synopsys VCS | **PASS** | `el2_veer_wrapper` + DCCM/ICCM/ICache SRAMs link |
| **CPU Firmware** | Real CPU Boot & Firmware | `tb/tb_soc_veer_cpu.sv` | Synopsys VCS | **PASS** | Boot from `0x10000000`, 122 retired, all 8 subsystems PASS, wrote `0xC0FFEE00` |

> [!NOTE]
> **Watchdog Clarification**: There is NO dedicated hardware Watchdog Timer peripheral in this SoC design. The watchdog timeout in `tb/tb_soc_veer_cpu.sv` (200 µs) is strictly an automated testbench simulation safety mechanism to prevent infinite loops in CI/EDA runs.

---

## 3. Real VeeR EL2 CPU Verification Commands

```bash
# Set Synopsys VCS & RISC-V GCC environment
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$HOME/.local/bin:$PATH
export LD_LIBRARY_PATH=$VCS_HOME/lib:$VCS_HOME/linux64/lib:$LD_LIBRARY_PATH

# 1. Compile C firmware & update Boot ROM image
make c-test
make bootrom

# 2. Compile and run real VeeR EL2 CPU firmware simulation
make sim-veer-cpu
```

### Observed Execution Log (`make sim-veer-cpu`)
```text
==========================================================================
  STARTING VEER EL2 SoC REAL CPU FIRMWARE VALIDATION (Synopsys VCS)      
==========================================================================
Firmware Target: sw/test.c (Writes 0xC0FFEE00 to SRAM 0x00000100)
Reset Vector:    0x10000000 (SoC Boot ROM)
Expected Signature at SRAM 0x00000100: 0xC0FFEE00
==========================================================================

Addressing configuration for axi_interconnect instance tb_soc_veer_cpu.u_soc.u_xbar.axi_interconnect_inst
 0 ( 0): 00000000 / 28 -- 00000000-0fffffff
 1 ( 0): 10000000 / 28 -- 10000000-1fffffff
 2 ( 0): 20000000 / 12 -- 20000000-20000fff
 3 ( 0): 30000000 / 28 -- 30000000-3fffffff

[AXI LSU WRITE ADDR] Time=1605000 | AWADDR = 0x00000100
[AXI LSU WRITE DATA #1] Time=1615000 | WDATA = 0xc0ffee00 | STRB = 1111
RAM AW hs addr=00000100 time=1625000
RAM W hs data=c0ffee00 strb=f time=1625000
[VeeR RETIRE #7] Time=1635000 | PC = 0x10000018 | INSN = 0x0000a001
RAM COMMIT time=1635000

==========================================================================
                       *** SIMULATION PASSED ***                          
==========================================================================
[SUCCESS] Real VeeR EL2 CPU booted from reset vector 0x1000_0000!
[SUCCESS] Boot ROM firmware (sw/test.c) successfully executed!
[SUCCESS] SRAM Address 0x00000100 (mem[64]) wrote signature: 0xc0ffee00
--------------------------------------------------------------------------
Subsystem Test Status Breakdown (read from SoC SRAM):
  [1] System SRAM R/W Test (0x00000104)      : 0x00000001 (PASS)
  [2] Boot ROM Read Test   (0x00000108)      : 0x00000001 (PASS)
  [3] IPU Configuration    (0x0000010C)      : 0x00000001 (PASS)
  [4] APB GPIO Test        (0x00000110)      : 0x00000001 (PASS)
  [5] APB Timer Test       (0x00000114)      : 0x00000001 (PASS)
  [6] APB UART Test        (0x00000118)      : 0x00000001 (PASS)
  [7] APB SPI Test         (0x0000011C)      : 0x00000001 (PASS)
  [8] APB PIC Test         (0x00000120)      : 0x00000001 (PASS)
  [>] Total Tests Passed   (0x00000124)      : 8 / 8
--------------------------------------------------------------------------
[SUCCESS] Total Instructions Retired : 122
[SUCCESS] Total IFU Fetches          : 202
[SUCCESS] Total LSU Stores           : 24
==========================================================================
$finish called from file "/home/student/Padmavathi-/tb/tb_soc_veer_cpu.sv", line 394.
$finish at simulation time              1695000 ps
```
