# Interconnect configuration decision: 4x4

## Decision

The VeeR EL2 SoC interconnect is configured as a **4x4** AXI4 crossbar, not 4x9.

## Rationale

`doc/RISC-V_VeeR_EL2_SoC_Specification.doc` (sections 2.2 and 3.3) defines
exactly four AXI4 manager ports and four AXI4 subordinate ports. A 4x9
configuration would add five subordinate ports that no block in the SoC
drives, together with unused decode and arbitration logic.

## Port mapping

| Manager-side port | SoC manager  | Subordinate-side port | SoC subordinate     |
|-------------------|--------------|-----------------------|---------------------|
| `s00`             | CPU IFU      | `m00`                 | System SRAM         |
| `s01`             | CPU LSU      | `m01`                 | Boot ROM            |
| `s02`             | Debug / sb   | `m02`                 | IPU configuration   |
| `s03`             | DMA          | `m03`                 | APB/AHB bridge      |

## Memory map

| Port | Base address | Address width | Region                            |
|------|--------------|---------------|-----------------------------------|
| `m00`| `0x0000_0000`| 28            | `0x0000_0000` - `0x0FFF_FFFF`     |
| `m01`| `0x1000_0000`| 28            | `0x1000_0000` - `0x1FFF_FFFF`     |
| `m02`| `0x2000_0000`| 12            | `0x2000_0000` - `0x2000_0FFF`     |
| `m03`| `0x3000_0000`| 28            | `0x3000_0000` - `0x3FFF_FFFF`     |

An access that matches no region receives `DECERR` (`2'b11`) from the
interconnect; it is not forwarded to any subordinate port.

## Generated RTL

`rtl/generated/axi_interconnect_wrap_4x4.v` is produced by:

```bash
make gen
# equivalently:
python3 scripts/axi_interconnect_wrap.py -p 4 4 \
    -n axi_interconnect_wrap_4x4 \
    -o rtl/generated/axi_interconnect_wrap_4x4.v
```

## Verification

`tb/tb_axi_interconnect_4x4.sv` is a self-checking testbench. It connects all
four manager-side and all four subordinate-side ports and covers:

1. Reads of the reset memory pattern from every manager port to every
   subordinate region (read decode, routing, `RID`/`RLAST`/`RRESP`).
2. Write-then-read of every manager/subordinate pair (`AW`/`W`/`B` and
   `AR`/`R` paths, write data, read data).
3. An unmapped address (`0x9000_0000`) returning `DECERR` on both the read and
   write paths.
4. Concurrent requests from all four manager ports to exercise arbitration.
5. Per-subordinate mis-routing and protocol-error counters, which must be zero.

Run it with:

```bash
make interconnect
```

A passing run ends with `RESULT: TEST PASSED`. Add `FSDB=1` to write
`build/dump.fsdb` for Verdi (`make wave`).
