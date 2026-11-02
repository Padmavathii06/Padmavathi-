# RISC-V VeeR EL2 SoC

RTL design and verification of a RISC-V VeeR EL2 based image/data-processing
System-on-Chip (SoC). The repository contains the hand-written RTL, generated
interconnect wrappers, testbenches, RTL generators and a unified Makefile-driven
build/simulation flow based on Synopsys VCS and Verdi.

Source of truth for the architecture is
`doc/RISC-V_VeeR_EL2_SoC_Specification.doc`; the interconnect configuration is
documented in `doc/interconnect_4x4_decision.md` and verification in
`doc/test_plan.md`.

## Project overview

The SoC is built around a VeeR EL2 RISC-V core and exposes four AXI4 manager
ports (CPU IFU, CPU LSU, Debug/sideband, DMA) and four subordinate ports
(System SRAM, Boot ROM, IPU configuration, APB/AHB bridge). A generated 4x4
AXI4 crossbar routes traffic between them. Additional subsystems include an IPU
configuration register block, DMA controller, APB peripheral set, JTAG/DMI debug
module, clock/reset unit (CRU) and boot ROM.

## Directory layout

```
doc/                     Specification, decision notes, test plan
rtl/interconnect/        Hand-written interconnect & peripheral RTL
rtl/soc/                 SoC top-level, SRAM/ROM models, CRU
rtl/debug/               JTAG/DMI debug module
rtl/generated/           Generated RTL (do not edit by hand)
tb/                      SystemVerilog testbenches (source of truth)
scripts/                 RTL generators and helper scripts
Makefile                 Build / simulation entry point
build/                   Build products (git-ignored)
```

## Key components

| Component | Location | Description |
|-----------|----------|-------------|
| AXI4 interconnect | `rtl/interconnect/axi_interconnect.v` | Hand-written crossbar core |
| Interconnect wrapper (4x4) | `rtl/generated/axi_interconnect_wrap_4x4.v` | Generated, do not edit |
| AXI4-Lite test IP | `rtl/interconnect/axi_lite_test_ip.v` | Register slave (CONTROL/DATA_A/DATA_B/RESULT) |
| APB bridge & peripherals | `rtl/interconnect/ahb_apb_bridge.v`, `apb_peripherals.v` | APB subsystem |
| DMA controller | `rtl/interconnect/dma_controller.v` | DMA engine |
| IPU config | `rtl/interconnect/ipu_config.v` | IPU register block |
| SoC top | `rtl/soc/soc_top.v` | Top-level integration |
| SRAM / Boot ROM | `rtl/soc/axi_ram.v`, `boot_rom.v` | Memory models |
| CRU | `rtl/soc/cru.v` | Clock & reset unit |
| JTAG/DMI | `rtl/debug/jtag_dmi.v` | Debug module |

## Interconnect configuration (4x4)

The SoC defines four AXI4 manager ports and four AXI4 subordinate ports, so the
interconnect is a **4x4** crossbar. See `doc/interconnect_4x4_decision.md`.

| Manager port | SoC manager | Subordinate port | SoC subordinate |
|--------------|-------------|------------------|-----------------|
| `s00` | CPU IFU | `m00` | System SRAM |
| `s01` | CPU LSU | `m01` | Boot ROM |
| `s02` | Debug / sb | `m02` | IPU configuration |
| `s03` | DMA | `m03` | APB/AHB bridge |

### Memory map

| Port | Base address | Address width | Region |
|------|--------------|---------------|--------|
| `m00` | `0x0000_0000` | 28 | `0x0000_0000` - `0x0FFF_FFFF` (256 MiB) |
| `m01` | `0x1000_0000` | 28 | `0x1000_0000` - `0x1FFF_FFFF` (256 MiB) |
| `m02` | `0x2000_0000` | 12 | `0x2000_0000` - `0x2000_0FFF` (4 KiB) |
| `m03` | `0x3000_0000` | 28 | `0x3000_0000` - `0x3FFF_FFFF` (256 MiB) |

Unmapped addresses receive `DECERR` (`2'b11`) from the interconnect and are not
forwarded to any subordinate.

## Prerequisites

- Synopsys VCS and Verdi
- Python 3 with Jinja2 (only needed for `make gen`)
- GNU Make

Tool paths and the license server default to the values in the `Makefile`.
Override them if needed:

```bash
make VCS_HOME=/path/to/vcs VERDI_HOME=/path/to/verdi \
     SNPSLMD_LICENSE_FILE=port@server <target>
```

## Common targets

```bash
make help            # list all targets
make gen             # regenerate rtl/generated/axi_interconnect_wrap_4x4.v
make axilite         # compile + run the AXI4-Lite test IP testbench
make interconnect    # compile + run the 4x4 interconnect testbench
make soc             # compile + run the SoC top-level smoke test
make apb             # compile + run the APB peripheral testbench
make debug           # compile + run the JTAG/DMI testbench
make cru             # compile + run the CRU reset testbench
make loopback        # compile + run the DMA/IPU loopback testbench
make wave            # open the latest build/dump.fsdb in Verdi
make clean           # delete build/
```

Add `FSDB=1` to a run target to write `build/dump.fsdb`, for example
`make interconnect FSDB=1`.

## Verification status

- `make axilite` - passes. AXI4-Lite register slave verified for write/read of
  CONTROL, DATA_A, DATA_B and RESULT, with bresp/rresp checks and a
  self-checking `RESULT: TEST PASSED`.
- `make interconnect` - passes. Self-checking 4x4 testbench connects all four
  manager and all four subordinate ports and verifies: read routing from every
  manager to every subordinate, write/read-back of all manager/subordinate
  pairs, `DECERR` for unmapped addresses on both read and write paths,
  concurrent arbitration from all four managers to distinct subordinates and to
  the same subordinate without data loss, and zero mis-routing/protocol errors.
  A passing run exits with `RESULT: TEST PASSED`; mismatches call `$fatal`.
- `make soc` - compiles the SoC top-level (interconnect + SRAM/ROM/IPU/APB
  RAM models) and runs a smoke test exercising the active-low reset and one
  manager port across all four subordinate regions.
- `make apb`, `make debug`, `make cru`, `make loopback` - additional subsystem
  testbenches for APB peripherals, JTAG/DMI, clock/reset and DMA/IPU loopback.

## Generated RTL

`rtl/generated/axi_interconnect_wrap_4x4.v` is produced by:

```bash
make gen
# equivalently:
python3 scripts/axi_interconnect_wrap.py -p 4 4 \
    -n axi_interconnect_wrap_4x4 \
    -o rtl/generated/axi_interconnect_wrap_4x4.v
```

Do not edit generated files by hand.

## Notes

- Build products are written to `build/` and are not tracked by git.
- The previous `tb/tb_axi_interconnect_4x9.sv` and
  `rtl/generated/axi_interconnect_wrap_4x9.v` are retained as historical
  reference only; they are not built by the Makefile.
- Repository: https://github.com/Padmavathii06/Padmavathi-

## Documentation
- `docs/PROJECT_STATUS.md` — completed work, remaining work, risks, next steps.
- `docs/ADDRESS_MAP.md` — AXI/APB register and memory map.
- `docs/VERIFICATION.md` — test commands, expected outputs, verification status.
- `docs/CPU_INTEGRATION.md` — VeeR EL2 source, build, interface, and integration-gap notes.

## Dependencies (not all available in this environment)
- Synopsys VCS + Verdi (college)
- GNU Make
- Python 3 with Jinja2 (for `make gen`)
- RISC-V GCC toolchain (for software flow; not yet installed)
- VeeR EL2 CPU RTL (not yet integrated; required for full SoC execution)
