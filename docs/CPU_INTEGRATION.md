# CPU Integration Notes — VeeR EL2

## Source and license

- Official repository: https://github.com/chipsalliance/Cores-VeeR-EL2
- License: Apache-2.0 (`LICENSE` in the VeeR repository).
- Dependencies (from VeeR README): Verilator 5+ (optional), RISC-V GCC 8.3+, Python 3.10+, Verible (lint), Perl (for `configs/veer.config`), and Git submodules (`git submodule update --init --recursive`).

## Reproducible obtain/build method

```bash
git clone https://github.com/chipsalliance/Cores-VeeR-EL2.git
cd Cores-VeeR-EL2
git submodule update --init --recursive
export RV_ROOT=$PWD
# Generate a configuration (example: no ICCM/DCCM, using external AXI memories)
perl configs/veer.config -snapshot=nolocal -set=dccm_enable=0 -set=iccm_enable=0
```

Generated files (including `snapshots/<name>/el2_param.vh`, `common_defines.vh`, `link.ld`, etc.) are required by the RTL and testbench flow. Do not copy VeeR RTL into this project without recording the exact commit and generated snapshot.

## VeeR EL2 interface summary (observed from `design/el2_veer_wrapper.sv`)

- Top module: `el2_veer_wrapper` (SystemVerilog).
- Clock/reset: `clk`, `rst_l`, `dbg_rst_l`.
- Reset vector is an input: `rst_vec[31:1]` (must be tied to a constant by the integrator).
- NMI vector: `nmi_vec[31:1]`.
- JTAG interface: `jtag_tck`, `jtag_tms`, `jtag_tdi`, `jtag_trst_n`, `jtag_tdo`, `jtag_tdoEn`.
- Interrupts: `timer_int`, `soft_int`, `extintsrc_req[1:PIC_TOTAL_INT]`.
- Local memory interfaces: dedicated ICCM and DCCM ports (can be disabled through configuration).
- AXI4 masters (when built with `RV_BUILD_AXI4`):
  - IFU AXI read (and unused write channel)
  - LSU AXI read/write
  - Sideband (SB) AXI read/write
  - DMA AXI (slave-side in the wrapper, driven by external DMA)
- AXI data width is **64 bits**; address width is 32 bits.
- Optional AHB-Lite interface exists when built with `RV_BUILD_AHB_LITE`.
- Memory export interface: `el2_mem_if.veer_sram_src` / `el2_mem_if.veer_icache_src`.

## Compatibility gaps with the current SoC

1. **Data width mismatch:** the current SoC interconnect, RAM, Boot ROM, IPU, and AXI-to-APB bridge are 32-bit. VeeR's AXI masters are 64-bit. Integration requires either a 64-bit SoC data path or AXI width converters.
2. **Multiple masters:** VeeR exposes IFU, LSU, sideband, and DMA masters. The current 4x4 interconnect has exactly four manager ports, so a mapping is possible, but port roles and IDs must be revisited.
3. **Local memories:** VeeR expects ICCM/DCCM memory interfaces unless disabled through configuration. A no-ICCM/no-DCCM configuration is possible, but must be generated and documented.
4. **Reset vector:** must be tied to a constant. The current Boot ROM is at `0x1000_0000`; if the CPU reset vector is set there, the Boot ROM must contain valid instructions. The current `bootrom.hex` contains only NOP/RET.
5. **Interrupts:** VeeR expects timer/software/external interrupt sources. The current APB PIC/Timer must be adapted or replaced.
6. **JTAG/debug:** VeeR's debug interface differs from the project's existing `jtag_dmi.v`.
7. **Clocking:** VeeR supports clock-ratio inputs for bus interfaces; the current CRU provides a single clock.

## Safe integration status

- The VeeR RTL has been inspected in a separate temporary directory only.
- It has **not** been copied into this repository.
- It has **not** been wired into `soc_top.v`.
- The current 32-bit AXI manager-port fallback in `soc_top.v` remains intact.

## Recommended next integration steps

1. Decide whether the SoC data width becomes 64-bit or whether AXI 64-to-32 width converters are added.
2. Generate a pinned VeeR snapshot (`-snapshot=...`) and record the VeeR commit hash in this repository.
3. Add VeeR as a Git submodule only after the commit and snapshot are chosen.
4. Create a SystemVerilog wrapper that ties `rst_vec`, interrupts, JTAG, and memory interfaces, and adapts VeeR's 64-bit AXI masters to the SoC interconnect.
5. Update `bootrom.hex` with a real reset handler and a C test linked at the chosen reset vector.
6. Add a VCS target that compiles VeeR + generated snapshot + SoC RTL and runs the C test.
