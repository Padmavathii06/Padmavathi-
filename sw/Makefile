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

# VeeR EL2 is RV32IMC (zicsr extension required for GCC 11+ CSR instructions)
ARCH    ?= -march=rv32imc_zicsr -mabi=ilp32
CFLAGS  ?= -O1 -g -ffreestanding -nostdlib -nostartfiles -Wall
LDFLAGS ?= -T link.ld

PYTHON  ?= python3

TEST    ?= test
TESTS   := test gpio_test timer_test uart_test spi_test pic_test ram_test bootrom_test ipu_test

all: $(TEST).hex $(TEST).dis

all-tests: $(addsuffix .hex,$(TESTS)) $(addsuffix .dis,$(TESTS))

%.elf: start.S %.c link.ld
	"$(CC)" $(ARCH) $(CFLAGS) $(LDFLAGS) start.S $*.c -o $@

%.bin: %.elf
	"$(OBJCOPY)" -j .text -j .rodata -O binary $< $@

%.hex: %.bin
	$(PYTHON) ../scripts/bin2hex.py $< $@ 0

%.dis: %.elf
	"$(OBJDUMP)" -d $< > $@

clean:
	-@del /f /q *.elf *.bin *.hex *.dis 2>nul || rm -f *.elf *.bin *.hex *.dis

.PHONY: all all-tests clean
.SECONDARY:
