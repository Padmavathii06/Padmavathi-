# Verification Guide — RISC-V VeeR EL2 SoC

## Environment

- Synopsys VCS + Verdi are expected at the college (paths configured in `Makefile`).
- No simulator or RISC-V toolchain is available on the development machine used for this audit, so **none of the targets below have been executed in this session**. Commands are provided exactly as they should be run.

## Makefile targets

| Target | Command | Sources |
|---|---|---|
| `make interconnect` | `make interconnect` | XBAR + `tb_axi_interconnect_4x4.sv` |
| `make axilite` | `make axilite` | AXI4-Lite test IP + TB |
| `make ipu` | `make ipu` | IPU config + TB |
| `make axi-apb` | `make axi-apb` | AXI-to-APB bridge + APB peripherals + TB |
| `make apb` | `make apb` | AHB-to-APB bridge + APB peripherals + TB |
| `make loopback` | `make loopback` | DMA + IPU + interconnect + TB |
| `make debug` | `make debug` | JTAG/DMI + TB |
| `make cru` | `make cru` | CRU + TB |
| `make soc` | `make soc` | SoC top + SRAM + interconnect + TB |
| `make soc_full` | `make soc_full` | Same as `soc` with coverage flags |
| `make clean` | `make clean` | removes `build/` |

Add `FSDB=1` to any run target to produce `build/dump.fsdb`, then `make wave`.

## Expected outputs

- A passing self-checking testbench prints `RESULT: TEST PASSED` and exits 0.
- A failing run prints `RESULT: TEST FAILED` and calls `$fatal`.

## Current verification status (this session)

- Static review only. No compilation or simulation was run.
- `soc_top.v` integration is incomplete (see `PROJECT_STATUS.md`); `make soc` exercises the current wrapper but does not validate Boot ROM, IPU, APB, CRU, or CPU.
- No CPU program execution has been demonstrated.

## Software build (toolchain required)

- RISC-V GCC is not installed in this environment. When it is, run:
  - `make c-test` — builds `sw/test.elf`, `sw/test.bin`, `sw/test.hex`.
  - `make hex` — alias for `make c-test` (ensures `sw/test.hex` exists).
- `sw/test.hex` is a 32-bit little-endian word image consumable by `$readmemh`.
- The flow assumes the CPU reset vector is `0x0000_0000` (system SRAM). Confirm against the VeeR EL2 configuration/specification before claiming execution.
