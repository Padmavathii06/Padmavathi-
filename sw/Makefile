# Software build flow for the SoC CPU.
# Requires a RISC-V GCC toolchain (override CROSS as needed).

CROSS ?= riscv64-unknown-elf-
CC    := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy

ARCH ?= -march=rv32imc -mabi=ilp32
CFLAGS ?= -O1 -g -ffreestanding -nostdlib -nostartfiles -Wall
LDFLAGS ?= -T link.ld

TEXT_BASE ?= 0x00000000

all: test.hex

test.elf: start.S test.c link.ld
	$(CC) $(ARCH) $(CFLAGS) $(LDFLAGS) start.S test.c -o $@

test.bin: test.elf
	$(OBJCOPY) -O binary $< $@

test.hex: test.bin
	python3 ../scripts/bin2hex.py $< $@ $(TEXT_BASE)

clean:
	rm -f test.elf test.bin test.hex

.PHONY: all clean
