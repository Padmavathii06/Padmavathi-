# Address Map — RISC-V VeeR EL2 SoC

Source of truth: `doc/interconnect_4x4_decision.md` and `doc/RISC-V_VeeR_EL2_SoC_Specification.doc`.

## AXI4 interconnect (4x4) regions

| Subordinate port | Region base | Address width | Range | Target block |
|---|---|---|---|---|
| `m00` | `0x0000_0000` | 28 | `0x0000_0000` - `0x0FFF_FFFF` (256 MiB) | System SRAM (`axi_ram`) |
| `m01` | `0x1000_0000` | 28 | `0x1000_0000` - `0x1FFF_FFFF` (256 MiB) | Boot ROM (`boot_rom`) |
| `m02` | `0x2000_0000` | 12 | `0x2000_0000` - `0x2000_0FFF` (4 KiB) | IPU configuration (`ipu_config`) |
| `m03` | `0x3000_0000` | 28 | `0x3000_0000` - `0x3FFF_FFFF` (256 MiB) | AXI-to-APB bridge (`axi_apb_bridge`) |

Unmapped addresses (e.g. `0x9000_0000`) return `DECERR` (`2'b11`) from the interconnect.

## IPU configuration registers (`0x2000_0000` base, word-aligned)

| Offset | Name | Access | Description |
|---|---|---|---|
| `0x00` | `IPU_CTRL` | R/W | `[0]` start, `[1]` stop, `[2]` soft reset, `[5:4]` mode |
| `0x04` | `IPU_STATUS` | RO | `[0]` busy, `[1]` done, `[2]` err, `[3]` fifo_of, `[4]` fifo_uf |
| `0x08` | `IPU_FRAME_WIDTH` | R/W | Image width in pixels (default 64) |
| `0x0C` | `IPU_FRAME_HEIGHT` | R/W | Image height in lines (default 64) |
| `0x10` | `IPU_SRC_ADDR` | R/W | Source buffer base address in SRAM |
| `0x14` | `IPU_DST_ADDR` | R/W | Destination buffer base address in SRAM |
| `0x18` | `IPU_IRQ_MASK` | R/W | `[0]` done_ie, `[1]` err_ie |
| `0x1C` | `IPU_IRQ_STATUS` | W1C | `[0]` done_irq, `[1]` err_irq |
| `0x20`..`0x40` | `IPU_KERNEL_COEFF[0..8]` | R/W | 3x3 convolution coefficients |

## APB peripheral subsystem (`0x3000_0000` base via AXI-to-APB bridge)

Word address within the APB region selects the peripheral by bits `[11:8]` (offsets below are the word offset from the APB base):

| Peripheral | Base word offset | Registers (word offsets) |
|---|---|---|
| UART | `0x000` | 0 CTRL, 1 STATUS, 2 TXDATA, 3 RXDATA |
| SPI | `0x100` | 0 CTRL, 1 STATUS, 2 TXDATA, 3 RXDATA |
| GPIO | `0x200` | 0 DIR, 1 OUT, 2 IN, 3 IRQMASK |
| Timer | `0x300` | 0 LOAD, 1 COUNT, 2 CTRL, 3 STATUS |
| PIC | `0x400` | 0 MASK, 1 PEND, 2 PRIO |

APB peripherals are accessed through `axi_apb_bridge` at the full AXI addresses `0x3000_xxxx`.

## DMA configuration (memory-mapped control)

The current `dma_controller` is **not** an AXI subordinate; it exposes a configuration interface (`cfg_src_addr`, `cfg_dst_addr`, `cfg_len`, `cfg_start`) and status (`cfg_done`, `cfg_err`, `dma_irq`) that must be wired to registers by integration. No committed register map exists yet; this must be defined when the CPU is integrated. Do not invent addresses in software without updating this document.

## Notes

- `soc_top.v` in the current tree does **not** instantiate the documented subordinate map; it instantiates four SRAMs. This is a known gap (see `PROJECT_STATUS.md`).
- AXI region widths in the interconnect testbench are 28/28/12/28 bits, matching this map.
