# Project Status — RISC-V VeeR EL2 SoC

Last updated: 2026-11-02

## Repository / Git state

- Working repository: `C:\Users\kadan\Documents\Padmavathi-` (Git repo, branch `main`, remote `origin` = https://github.com/Padmavathii06/Padmavathi-.git).
- There is also a non-Git mirror at `C:\Users\kadan\OneDrive\Documents\Padmavathi--main`; it is **not** the working tree for this status file.
- Uncommitted changes present at audit time:
  - Modified: `Makefile`, `rtl/interconnect/dma_controller.v`, `rtl/interconnect/ipu_config.v`, `tb/tb_dma_ipu_loopback.sv`
  - Untracked: `rtl/interconnect/axi_apb_bridge.v`, `tb/tb_axi_apb_bridge.sv`, `tb/tb_ipu_config.sv`
- No local HDL simulator (VCS/Icarus) and no RISC-V GCC toolchain were found on this Windows machine. Nothing below is claimed as executed unless explicitly stated.

## High-level summary

The repository contains a substantial, self-consistent 4x4 AXI4 interconnect verification environment plus register-transfer-level models for RAM, Boot ROM, CRU, DMA, IPU configuration, APB peripherals, two APB bridges, JTAG/DMI, and a top-level SoC wrapper. **The actual VeeR EL2 CPU RTL is not present anywhere in the repository or in sibling directories.** Therefore full SoC execution of a C program is **not** currently possible; only the surrounding infrastructure has been prepared.

## Completion checklist

### Interconnect
- [x] `rtl/interconnect/axi_interconnect.v` — AXI4 crossbar core (vendored Alex Forencich).
- [x] `rtl/generated/axi_interconnect_wrap_4x4.v` — generated 4x4 wrapper.
- [x] `scripts/axi_interconnect_wrap.py` — generator.
- [x] `tb/tb_axi_interconnect_4x4.sv` — self-checking 4x4 testbench.
- [x] `Makefile` target `interconnect`.

### AXI4-Lite test IP
- [x] `rtl/interconnect/axi_lite_test_ip.v`
- [x] `tb/tb_axi_lite_test_ip.sv`
- [x] `Makefile` target `axilite`.

### IPU configuration register block
- [x] `rtl/interconnect/ipu_config.v` — AXI4 subordinate register block.
- [x] `tb/tb_ipu_config.sv` — self-checking testbench.
- [x] `Makefile` target `ipu`.

### DMA controller
- [x] `rtl/interconnect/dma_controller.v` — memory-to-memory DMA AXI4 manager.
- [ ] Dedicated DMA-only self-checking testbench (currently exercised only through `tb_dma_ipu_loopback`).
- [x] `Makefile` target `loopback` (DMA + IPU + interconnect).

### AXI-to-APB bridge
- [x] `rtl/interconnect/axi_apb_bridge.v` — AXI4 subordinate to APB master.
- [x] `tb/tb_axi_apb_bridge.sv`.
- [x] `Makefile` target `axi-apb`.

### APB peripherals
- [x] `rtl/interconnect/apb_peripherals.v` — UART/SPI/GPIO/Timer/PIC register slaves.
- [x] `tb/tb_apb_peripherals.sv`.
- [x] `Makefile` target `apb`.

### AHB-to-APB bridge (legacy/secondary)
- [x] `rtl/interconnect/ahb_apb_bridge.v`.

### SoC memories
- [x] `rtl/soc/axi_ram.v` — AXI4 subordinate SRAM model.
- [x] `rtl/soc/boot_rom.v` — AXI4 subordinate Boot ROM with `$readmemh` init.
- [x] `rtl/soc/bootrom.hex` — placeholder NOP/RET image.

### Clock/reset
- [x] `rtl/soc/cru.v` — clock pass-through + sequenced reset.
- [x] `tb/tb_cru_reset.sv`.
- [x] `Makefile` target `cru` (compile/run target exists).

### Debug
- [x] `rtl/debug/jtag_dmi.v`.
- [x] `tb/tb_jtag_dmi.sv`.
- [x] `Makefile` target `debug`.

### SoC top-level
- [~] `rtl/soc/soc_top.v` — now instantiates CRU, the 4x4 interconnect with the documented base addresses, System SRAM (`axi_ram`), Boot ROM (`boot_rom`), IPU config (`ipu_config`), and the AXI-to-APB bridge + APB peripherals. All four manager ports are still exposed externally because no CPU RTL is integrated yet.
- [ ] CPU integration — **blocked: no VeeR EL2 RTL in repository.**

### Software scaffold
- [~] `sw/` contains a minimal RV32 C test, startup assembly, linker script, and Makefile.
- [~] `scripts/bin2hex.py` converts a little-endian ELF/binary image to 32-bit word hex.
- [ ] `make c-test` / `make hex` are defined but require a RISC-V GCC toolchain (not installed here).

### Software / C test
- [ ] No RISC-V toolchain present on this machine.
- [ ] No startup code, linker script, or C test program yet.
- [ ] No `make c-test` / `make hex` target yet.
- [ ] No testbench that executes a real CPU program.

## Missing / external dependencies

1. **VeeR EL2 CPU RTL** (required for any real execution). Not present. Obtain from the official VeeR EL2 repository (e.g. CHIPS Alliance `VeeR-EL2`) and integrate per its build/integration guide. Until then, `soc_top` can only be exercised through external AXI manager ports.
2. **Synopsys VCS + Verdi** (college environment). Not installed locally. All `make` targets that invoke `vcs` are unverified here.
3. **RISC-V GCC toolchain** (e.g. `riscv64-unknown-elf-gcc` or `riscv-none-elf-gcc`) matching the CPU's ISA/ABI. Not installed locally.
4. **GNU Make** (not installed locally; the Makefile uses GNU-make features).

## Recommended next steps (priority order)

1. Install/obtain VeeR EL2 RTL and place it under a documented vendor path (e.g. `vendor/veer_el2/` or a Git submodule). Add include paths and top-level CPU wiring to `soc_top.v`.
2. Reconcile `soc_top.v` subordinate wiring with the 4x4 memory map (SRAM @ 0x0, Boot ROM @ 0x1000_0000, IPU @ 0x2000_0000, APB bridge @ 0x3000_0000) instead of four identical SRAMs.
3. Integrate CRU reset sequencing into `soc_top` and update `tb/tb_soc_top.sv` reset wait to cover `RESET_CYCLES`.
4. Add a RISC-V C build flow (`sw/` directory, startup, linker script, `make c-test`, `make hex`) once the toolchain and CPU are available.
5. Add a CPU-execution testbench that loads `bootrom.hex` and checks an observable pass/fail register.
6. Run every `make` target in the college VCS environment and record results in `docs/VERIFICATION.md`.
7. Protect uncommitted work with a checkpoint commit before large edits.

## Risks

- `soc_top.v` as it stands does not reflect the documented memory map (four SRAMs) and will not boot a CPU.
- Several RTL models are single-beat only; burst-capable masters (CPU caches) may require upgrades.
- `axi_ram` indexes memory with only 8 address bits and ignores byte strobes in the committed version.
- `boot_rom` ready is registered, which can stall a back-to-back stream; acceptable for single beats but should be reviewed.
- No toolchain means software claims cannot be verified in this session.
