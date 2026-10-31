# RISC-V VeeR EL2 SoC

RTL and verification for the VeeR EL2 based image/data-processing SoC described in
`doc/RISC-V_VeeR_EL2_SoC_Specification.doc`.

## Directory layout

```
doc/                     Specification and reference material
rtl/interconnect/        Hand-written interconnect RTL
rtl/generated/           Generated RTL (do not edit by hand)
tb/                      Testbenches (source of truth)
scripts/                 RTL generators and helper scripts
Makefile                 Build / simulation entry point
```

Build products are written to `build/` and are not tracked by git.

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
make wave            # open the latest build/dump.fsdb in Verdi
make clean           # delete build/
```

Add `FSDB=1` to `make interconnect` to write `build/dump.fsdb`, for example
`make interconnect FSDB=1`.

## Interconnect configuration

The SoC specification defines four AXI4 manager ports (CPU IFU, CPU LSU,
Debug/sb, DMA) and four subordinate ports (SRAM, Boot ROM, IPU config,
APB/AHB bridge), so the interconnect is a **4x4** crossbar. See
`doc/interconnect_4x4_decision.md` for the decision, port mapping, memory map
and verification coverage.

| Port | Base address | Region                        |
|------|--------------|-------------------------------|
| `m00`| `0x0000_0000`| SRAM, 256 MiB                 |
| `m01`| `0x1000_0000`| Boot ROM, 256 MiB             |
| `m02`| `0x2000_0000`| IPU configuration, 4 KiB      |
| `m03`| `0x3000_0000`| APB/AHB bridge, 256 MiB       |

## Current verification status

- `make axilite` - passes. The AXI4-Lite register slave is verified for
  write/read of CONTROL, DATA_A, DATA_B and RESULT, with bresp/rresp checks
  and a self-checking `RESULT: TEST PASSED`.
- `make soc` - compiles the SoC top-level (interconnect + SRAM/ROM/IPU/APB
  RAM models) and runs a smoke test exercising the active-low reset and
  one manager port across all four subordinate regions.
- `make interconnect` - passes. The self-checking 4x4 testbench connects all
  four manager-side and all four subordinate-side ports and verifies:
  read routing from every manager to every subordinate, write/read-back of all
  manager/subordinate pairs, `DECERR` for unmapped addresses on both read and
  write paths, concurrent arbitration from all four managers to distinct
  subordinates, concurrent arbitration from all four managers to the same
  subordinate without data loss, and zero mis-routing/protocol errors. A
  passing run exits with `RESULT: TEST PASSED`; any mismatch calls `$fatal`
  so `make` reports a non-zero exit status.

The previous `tb/tb_axi_interconnect_4x9.sv` and
`rtl/generated/axi_interconnect_wrap_4x9.v` are retained as historical
reference only; they are not built by the Makefile.
