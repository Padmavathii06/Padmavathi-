# Handoff Report — RISC-V VeeR EL2 SoC

Date: 2026-11-02
Repository: `C:\Users\kadan\Documents\Padmavathi-`
Branch: `main`

---

## 1. Completed Work

1. **Repository Audit & Toolchain Setup**:
   - Installed Icarus Verilog 14.0 (`iverilog`, `vvp`).
   - Installed GNU Make 4.4.1.
   - Installed and extracted xPack GNU RISC-V Embedded GCC 15.2.0 (RV32IMC target).
2. **Upstream VeeR EL2 & AXI Width Converters**:
   - Cloned genuine VeeR EL2 core (`vendor/veer-el2`) at commit `fa00c8aadc4a077d78b277129c1badf90d881255`.
   - Generated pinned configuration snapshot `snapshots/default/` with reset vector `0x1000_0000`, DCCM=0, ICCM=0.
   - Cloned genuine AXI width adapters (`vendor/verilog-axi`).
   - Created `rtl/soc/veer_cpu_wrapper.sv` wrapping `el2_veer_wrapper` and converting 64-bit IFU and LSU master ports to 32-bit using `axi_adapter`.
3. **SoC Integration & Boot ROM**:
   - Updated `rtl/soc/soc_top.v` with base addresses for SRAM (`0x0000_0000`), Boot ROM (`0x1000_0000`), IPU (`0x2000_0000`), and APB (`0x3000_0000`).
   - Enhanced `rtl/soc/boot_rom.v` with fallback path resolution to support execution from both repository root and `build/`.
4. **Testbench Fixes & Full Verification**:
   - Fixed `tb/tb_axi_lite_test_ip.sv`: wrapped FSDB dump in `` `ifdef FSDB `` guard.
   - Fixed `tb/tb_axi_interconnect_4x4.sv`: wrapped FSDB dump and converted unpacked array parameters to scalar constants for Icarus Verilog 14 compatibility.
   - Fixed `tb/tb_dma_ipu_loopback.sv`: converted unpacked array parameters to scalar constants; fixed DMA start trigger timing to `@(negedge clk)`.
   - Updated `tb/tb_soc_top.sv`: extended tests to exercise all 4 memory-mapped regions: System SRAM, Boot ROM, IPU config, and APB peripherals.
5. **Software Toolchain, Linker Script & Firmware**:
   - Updated `sw/link.ld` with separate `ROM` (`0x1000_0000`, 64K) and `RAM` (`0x0000_0000`, 256K) regions.
   - Updated `sw/Makefile` with automated toolchain detection and cross-platform targets.
   - Compiled `sw/test.c` + `sw/start.S` into `sw/test.elf`.
   - Extracted binary `sw/test.bin` and generated word-addressed `sw/test.hex` via `scripts/bin2hex.py`.
   - Synchronized `rtl/soc/bootrom.hex` with `sw/test.hex`.
6. **Build Automation**:
   - Updated root `Makefile` with `sim-all`, `sim-soc`, `sim-xbar`, `sim-cru`, `sim-axilite`, `sim-ipu`, `sim-axi-apb`, `sim-apb`, `sim-debug`, `sim-loopback`, `c-test`, `hex`, and `bootrom`.
7. **Documentation**:
   - Updated `README.md`, `docs/PROJECT_STATUS.md`, `docs/ADDRESS_MAP.md`, `docs/VERIFICATION.md`, and `docs/CPU_INTEGRATION.md`.

---

## 2. Files Changed

| File | Change Summary |
|---|---|
| `.gitignore` | Ignored `build/`, `vendor/`, `*.vvp`, and temporary build artifacts |
| `Makefile` | Added Icarus Verilog simulation targets (`sim-all`, `sim-*`), software targets (`c-test`, `hex`, `bootrom`) |
| `README.md` | Documented architecture, quick-start verification, build targets |
| `docs/ADDRESS_MAP.md` | Documented confirmed 4x4 address map, reset vector, and verified test accesses |
| `docs/CPU_INTEGRATION.md` | Documented upstream commit, snapshot parameters, 64-to-32 AXI adaptation, and VCS blocker |
| `docs/PROJECT_STATUS.md` | Comprehensive status of all 9 verified testbenches, software, and CPU wrapper |
| `docs/VERIFICATION.md` | Detailed commands and verified PASS results for all simulations |
| `HANDOFF.md` | Complete handoff documentation |
| `rtl/soc/boot_rom.v` | Added dual-path file lookup (`rtl/soc/bootrom.hex` & `../rtl/soc/bootrom.hex`) |
| `rtl/soc/bootrom.hex` | Replaced placeholder with compiled RV32IMC test firmware image |
| `rtl/soc/soc_top.v` | Standardized `boot_rom` instantiation |
| `rtl/soc/veer_cpu_wrapper.sv` | **NEW**: VeeR EL2 core wrapper with 64-to-32-bit AXI adapters on IFU and LSU |
| `sw/Makefile` | Auto-detects toolchain, compiles `test.elf`, extracts `test.bin`, generates `test.hex` |
| `sw/link.ld` | Fixed reset vector mapping (`0x1000_0000` ROM, `0x0000_0000` RAM) |
| `sw/test.hex` | Generated word-addressed firmware image |
| `tb/tb_axi_interconnect_4x4.sv` | Added FSDB guard; resolved unpacked array parameters for Icarus 14 |
| `tb/tb_axi_lite_test_ip.sv` | Added FSDB guard |
| `tb/tb_dma_ipu_loopback.sv` | Added FSDB guard; resolved array parameters; corrected DMA start timing |
| `tb/tb_soc_top.sv` | Added multi-region tests verifying SRAM, Boot ROM, IPU config, and APB Timer |

---

## 3. Actual Tests Run and Verified Results

All 9 testbenches have been compiled and simulated under Icarus Verilog 14.0. All passed:

| # | Test | Command | Simulator | Result |
|---|---|---|---|---|
| 1 | CRU Reset Sequencer | `make sim-cru` | Icarus 14.0 | **PASS** |
| 2 | AXI4-Lite Test IP | `make sim-axilite` | Icarus 14.0 | **PASS** |
| 3 | IPU Configuration Block | `make sim-ipu` | Icarus 14.0 | **PASS** |
| 4 | AXI4-to-APB Bridge | `make sim-axi-apb` | Icarus 14.0 | **PASS** |
| 5 | APB Peripherals Subsystem | `make sim-apb` | Icarus 14.0 | **PASS** |
| 6 | JTAG DMI Debug Module | `make sim-debug` | Icarus 14.0 | **PASS** |
| 7 | DMA + IPU Crossbar Loopback | `make sim-loopback` | Icarus 14.0 | **PASS** |
| 8 | 4x4 AXI4 Crossbar Interconnect | `make sim-xbar` | Icarus 14.0 | **PASS** |
| 9 | Full Integrated SoC Top | `make sim-soc` | Icarus 14.0 | **PASS** |

**Regression Target**:
`make sim-all` runs all 9 tests sequentially and exits 0 with:
```
========================================================
ALL 9 SIMULATIONS PASSED SUCCESSFULLY
========================================================
```

---

## 4. Exact Commands to Reproduce

### Run All RTL Simulations:
```bash
make sim-all
```

### Recompile RISC-V Firmware:
```bash
make c-test
make hex
make bootrom
```

### Run Integrated SoC Simulation:
```bash
make sim-soc
```

---

## 5. Exact Remaining Blockers

1. **VeeR EL2 RTL Local Simulation**:
   - VeeR EL2 core (`el2_veer_wrapper.sv`) and its memory interface (`el2_mem_if.sv`) use SystemVerilog IEEE 1800-2017 `interface ... modport` constructs and package-scoped typenames (`import el2_pkg::*`).
   - Icarus Verilog 14.0 fails during elaboration with `syntax error; sorry: interface modports not supported`.
   - Therefore, direct CPU execution simulation requires Synopsys VCS in the college environment.

---

## 6. Next Actions Required in the College VCS Environment

When running on the Linux workstations with Synopsys VCS and Verdi:

1. Set tool environment (if not already set in profile):
   ```bash
   export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
   export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
   export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
   export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
   ```
2. Run the full SoC regression with code coverage:
   ```bash
   make run-soc-full
   ```
3. Run the interconnect crossbar regression with Verdi waveform dump:
   ```bash
   make run-xbar FSDB=1
   make wave
   ```
