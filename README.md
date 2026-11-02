# RISC-V VeeR EL2 SoC

RTL design, software toolchain integration, and verification of a RISC-V VeeR EL2 based image/data-processing System-on-Chip (SoC).

## Architecture Overview

The SoC is built around the Western Digital / CHIPS Alliance VeeR EL2 core and features:
- **CPU Subsystem**: RV32IMC VeeR EL2 with reset vector mapped to `0x1000_0000`.
- **AXI4 Interconnect**: 4x4 non-blocking crossbar routing traffic between 4 managers and 4 subordinates.
- **AXI Width Adapters**: 64-to-32-bit AXI adapters bridging the CPU's 64-bit IFU and LSU buses to the 32-bit SoC fabric.
- **System SRAM**: 256 MiB address aperture (`0x0000_0000` - `0x0FFF_FFFF`) supporting byte strobes.
- **Boot ROM**: 256 MiB address aperture (`0x1000_0000` - `0x1FFF_FFFF`) containing compiled startup firmware.
- **IPU Subsystem**: Hardware image processing unit configuration block (`0x2000_0000` - `0x2000_0FFF`).
- **APB Subsystem**: AXI4-to-APB bridge controlling UART, SPI, GPIO, Timer, and PIC peripherals (`0x3000_0000` - `0x3FFF_FFFF`).
- **Clock & Reset Unit (CRU)**: Glitch-free active-low to sequenced active-high reset generator.
- **DMA Controller**: High-throughput memory-to-memory data mover.

## Memory Map

| Port | Base Address | Width | Range | Target Subsystem |
|------|--------------|-------|-------|------------------|
| `m00` | `0x0000_0000` | 28 | `0x0000_0000` - `0x0FFF_FFFF` | System SRAM (`axi_ram`) |
| `m01` | `0x1000_0000` | 28 | `0x1000_0000` - `0x1FFF_FFFF` | Boot ROM (`boot_rom`) / Reset Vector |
| `m02` | `0x2000_0000` | 12 | `0x2000_0000` - `0x2000_0FFF` | IPU Config (`ipu_config`) |
| `m03` | `0x3000_0000` | 28 | `0x3000_0000` - `0x3FFF_FFFF` | APB Bridge (`axi_apb_bridge`) |

Unmapped accesses return `DECERR` (`2'b11`).

## Directory Layout

```
docs/                    Architecture specifications, address map, status & verification guides
rtl/interconnect/        4x4 AXI crossbar, IPU config, DMA controller, APB bridge & peripherals
rtl/soc/                 soc_top.v, veer_cpu_wrapper.sv, axi_ram.v, boot_rom.v, cru.v
rtl/debug/               JTAG/DMI debug module
rtl/generated/           Generated AXI 4x4 crossbar wrapper
tb/                      SystemVerilog testbenches (all verified under Icarus Verilog)
sw/                      C test, startup assembly, linker script, and Makefile
vendor/                  Upstream VeeR EL2, verilog-axi adapters, and RISC-V GCC toolchain
Makefile                 Unified build and simulation driver
```

## Quick Start & Verification

### Run All Simulations (Icarus Verilog)

```bash
make sim-all
```

Runs and checks all 9 testbenches:
1. `sim-cru`: CRU reset sequencer
2. `sim-axilite`: AXI4-Lite test slave
3. `sim-ipu`: IPU configuration registers
4. `sim-axi-apb`: AXI4-to-APB bridge
5. `sim-apb`: APB peripherals (UART, SPI, GPIO, Timer, PIC)
6. `sim-debug`: JTAG DMI debug controller
7. `sim-loopback`: DMA controller loopback
8. `sim-xbar`: 4x4 AXI4 crossbar matrix & arbitration
9. `sim-soc`: Full SoC top integration (SRAM, Boot ROM, IPU, APB Timer)

### Compile C Firmware Image

```bash
make c-test
make hex
make bootrom
```

Compiles `sw/test.c` + `sw/start.S` with RV32IMC GCC and updates `rtl/soc/bootrom.hex`.

### College VCS Environment Targets

```bash
make run-soc-full        # Full SoC coverage simulation
make run-xbar            # Interconnect crossbar simulation
make wave                # Open dump.fsdb in Verdi
```
