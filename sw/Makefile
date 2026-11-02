# Software build flow for the SoC CPU.
# Requires a RISC-V GCC toolchain (override CROSS as needed).

# Auto-detect local vendor toolchain if present and CROSS not set
LOCAL_RISCV := ../vendor/riscv-gcc/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-
ifeq ($(wildcard $(LOCAL_RISCV)gcc.exe),)
    CROSS ?= riscv-none-elf-
else
    CROSS ?= $(LOCAL_RISCV)
endif

CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump

# VeeR EL2 is RV32IMC
ARCH    ?= -march=rv32imc -mabi=ilp32
CFLAGS  ?= -O1 -g -ffreestanding -nostdlib -nostartfiles -Wall
LDFLAGS ?= -T link.ld

PYTHON  ?= python3

all: test.hex test.dis

test.elf: start.S test.c link.ld
	"$(CC)" $(ARCH) $(CFLAGS) $(LDFLAGS) start.S test.c -o $@

test.bin: test.elf
	"$(OBJCOPY)" -j .text -j .rodata -O binary $< $@

test.hex: test.bin
	$(PYTHON) ../scripts/bin2hex.py $< $@ 0

test.dis: test.elf
	"$(OBJDUMP)" -d $< > $@

clean:
	-@del /f /q test.elf test.bin test.hex test.dis 2>nul || rm -f test.elf test.bin test.hex test.dis

.PHONY: all clean
