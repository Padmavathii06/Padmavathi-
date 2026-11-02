# CPU Integration Notes — VeeR EL2

Last Updated: 2026-11-02

## 1. Upstream Source & Configuration

- **Official Repository**: https://github.com/chipsalliance/Cores-VeeR-EL2
- **License**: Apache-2.0 (`LICENSE` in VeeR repository)
- **Local Clone**: `vendor/veer-el2/`
- **Pinned Commit**: `fa00c8aadc4a077d78b277129c1badf90d881255`
- **Configuration Snapshot**: `snapshots/default/` generated via:
  ```bash
  perl configs/veer.config -target=default -set=reset_vec=0x10000000 -set=dccm_enable=0 -set=iccm_enable=0
  ```
- **Generated Snapshot Products**:
  - `snapshots/default/common_defines.vh`
  - `snapshots/default/defines.h`
  - `snapshots/default/el2_param.vh`
  - `snapshots/default/el2_pdef.vh`
  - `snapshots/default/link.ld`
  - `snapshots/default/pic_map_auto.svh`
  - `snapshots/default/whisper.json`
  - `snapshots/default/perl_configs.pl`

## 2. Interface Specifications & Architecture

VeeR EL2 core top module: `el2_veer_wrapper` (`vendor/veer-el2/design/el2_veer_wrapper.sv`).

- **Clock & Resets**:
  - `clk`: Primary system clock.
  - `rst_l`: Active-low core reset.
  - `dbg_rst_l`: Active-low debug subsystem reset.
- **Reset Vector**:
  - `rst_vec[31:1]`: Pinned to `31'h0800_0000`, setting CPU entry address to `0x1000_0000` (SoC Boot ROM).
- **Bus Protocols & Data Width**:
  - Instruction Fetch Unit (IFU): AXI4 master, 64-bit data width (`ifu_axi_rdata[63:0]`).
  - Load/Store Unit (LSU): AXI4 master, 64-bit data width (`lsu_axi_wdata[63:0]`, `lsu_axi_rdata[63:0]`).
  - Sideband / Debug (SB): AXI4 master, 64-bit data width.
  - System Bus DMA: AXI4 subordinate, 64-bit data width.
- **Clock Enables**:
  - `lsu_bus_clk_en`, `ifu_bus_clk_en`, `dbg_bus_clk_en`, `dma_bus_clk_en` tied to `1'b1` for 1:1 synchronous clocking.
- **Interrupts**:
  - `timer_int`, `soft_int`, `extintsrc_req[31:1]`.

## 3. Bus Width Gap & Adapter Integration

The SoC interconnect crossbar (`axi_interconnect_wrap_4x4`), System SRAM (`axi_ram`), Boot ROM (`boot_rom`), IPU config (`ipu_config`), and AXI-to-APB bridge (`axi_apb_bridge`) are all 32-bit AXI4 data paths.

To resolve the 64-bit to 32-bit mismatch:
- Sourced genuine AXI width adapters: `vendor/verilog-axi/rtl/axi_adapter.v` (Alex Forencich, MIT license).
- Implemented `rtl/soc/veer_cpu_wrapper.sv`:
  - Instantiates `el2_veer_wrapper`.
  - Connects VeeR's 64-bit IFU read channel through an `axi_adapter` (S_DATA=64, M_DATA=32) to 32-bit manager port `m0_ifu_*` (SoC Manager 0).
  - Connects VeeR's 64-bit LSU read/write channels through an `axi_adapter` (S_DATA=64, M_DATA=32) to 32-bit manager port `m1_lsu_*` (SoC Manager 1).
  - Ties debug, JTAG, scan, and MPC controls to safe active defaults.

## 4. Simulation Status & Technical Blocker

- **Open-Source Local Flow (Icarus Verilog 14.0)**:
  - Attempting to compile `el2_mem_if.sv` and VeeR SystemVerilog packages with Icarus Verilog yields:
    `syntax error; sorry: interface modports / unpacked struct ports not supported.`
  - VeeR EL2 relies heavily on SystemVerilog IEEE 1800-2017 language constructs (`interface ... modport`, `import el2_pkg::*`, package-scoped parameters) that Icarus Verilog cannot synthesize or simulate.
- **Target College Flow (Synopsys VCS U-2023.03+)**:
  - Synopsys VCS natively supports the full SystemVerilog IEEE 1800-2017 language standard including interface modports.
  - The Makefile is configured with VCS and Verdi flags (`-full64 -sverilog -kdb -debug_access+all`) ready for execution in the college environment (`/home/student/snps_tools_target/vcs/U-2023.03`).
