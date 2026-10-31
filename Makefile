# -----------------------------------------------------------------------------
# RISC-V VeeR EL2 SoC - build and simulation
# -----------------------------------------------------------------------------
# All generated/build products go into $(BUILD_DIR) and are git-ignored.
# Source of truth:
#   rtl/                 hand-written RTL
#   rtl/generated/       generated RTL (do not edit by hand)
#   tb/                  testbenches
#   scripts/             generators and helper scripts
# -----------------------------------------------------------------------------

SHELL := /bin/bash

# Tool locations. Override from the environment or on the command line, e.g.
#   make VCS_HOME=/path/to/vcs VERDI_HOME=/path/to/verdi
VCS_HOME   ?= /home/student/snps_tools_target/vcs/U-2023.03
VERDI_HOME ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export VCS_HOME VERDI_HOME SNPSLMD_LICENSE_FILE
export PATH := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)
export LD_LIBRARY_PATH := $(VCS_HOME)/lib:$(VCS_HOME)/linux64/lib:$(LD_LIBRARY_PATH)

VCS    ?= vcs
VERDI  ?= verdi
PYTHON ?= python3

BUILD_DIR ?= build
RTL_DIR   := rtl
TB_DIR    := tb
GEN_DIR   := rtl/generated
SCRIPTS   := scripts

# Verdi FSDB PLI for VCS
NOVAS_TAB := $(VERDI_HOME)/share/PLI/VCS/linux64/novas.tab
NOVAS_PLI := $(VERDI_HOME)/share/PLI/VCS/linux64/pli.a
VCS_FLAGS := -full64 -sverilog -debug_access+all -kdb -P $(NOVAS_TAB) $(NOVAS_PLI)

# Source lists
COMMON_RTL := \
	$(RTL_DIR)/interconnect/priority_encoder.v \
	$(RTL_DIR)/interconnect/arbiter.v

XBAR_RTL := \
	$(COMMON_RTL) \
	$(RTL_DIR)/interconnect/axi_interconnect.v \
	$(GEN_DIR)/axi_interconnect_wrap_4x4.v

XBAR_TB  := $(TB_DIR)/tb_axi_interconnect_4x4.sv

AXIL_RTL := $(RTL_DIR)/interconnect/axi_lite_test_ip.v
AXIL_TB  := $(TB_DIR)/tb_axi_lite_test_ip.sv

APB_RTL := $(RTL_DIR)/interconnect/ahb_apb_bridge.v $(RTL_DIR)/interconnect/apb_peripherals.v
APB_TB  := $(TB_DIR)/tb_apb_peripherals.sv

CRU_RTL := $(RTL_DIR)/soc/cru.v
CRU_TB  := $(TB_DIR)/tb_cru_reset.sv
BOOTROM_RTL := $(RTL_DIR)/soc/boot_rom.v
BOOTROM_HEX := $(RTL_DIR)/soc/bootrom.hex

# VCS is run from inside $(BUILD_DIR), so feed it absolute source paths.
abs = $(addprefix $(CURDIR)/,$(1))

.PHONY: all gen interconnect axilite apb bootrom cru compile-cru run-cru compile-xbar run-xbar compile-axilite \
        run-axilite compile-apb run-apb wave clean help compile-soc-full run-soc-full soc_full

all: compile-xbar compile-axilite

# -----------------------------------------------------------------------------
# Generated RTL
# -----------------------------------------------------------------------------
gen:
	@mkdir -p $(GEN_DIR)
	$(PYTHON) $(SCRIPTS)/axi_interconnect_wrap.py -p 4 4 \
		-n axi_interconnect_wrap_4x4 \
		-o $(GEN_DIR)/axi_interconnect_wrap_4x4.v

# -----------------------------------------------------------------------------
# Interconnect testbench
# -----------------------------------------------------------------------------
compile-xbar:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(XBAR_RTL)) $(call abs,$(XBAR_TB)) \
		-o simv_xbar

run-xbar: compile-xbar
	cd $(BUILD_DIR) && ./simv_xbar $(if $(FSDB),+fsdb)

interconnect: run-xbar

# -----------------------------------------------------------------------------
# AXI4-Lite test IP testbench
# -----------------------------------------------------------------------------
compile-axilite:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(AXIL_RTL)) $(call abs,$(AXIL_TB)) \
		-o simv_axilite

run-axilite: compile-axilite
	cd $(BUILD_DIR) && ./simv_axilite

axilite: run-axilite

# -----------------------------------------------------------------------------
# SoC top-level smoke test
# -----------------------------------------------------------------------------
SOC_RTL := $(RTL_DIR)/soc/soc_top.v $(RTL_DIR)/soc/axi_ram.v $(XBAR_RTL)
SOC_TB  := $(TB_DIR)/tb_soc_top.sv

compile-soc:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(SOC_RTL)) $(call abs,$(SOC_TB)) \
		-o simv_soc

run-soc: compile-soc
	cd $(BUILD_DIR) && ./simv_soc

soc: run-soc

# -----------------------------------------------------------------------------
# Full SoC-level verification (end-to-end)
# -----------------------------------------------------------------------------
SOC_FULL_RTL := $(SOC_RTL)
SOC_FULL_TB  := $(SOC_TB)

compile-soc-full:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) -cm line+cond+fsm+tgl+branch \
		$(call abs,$(SOC_FULL_RTL)) $(call abs,$(SOC_FULL_TB)) \
		-o simv_soc_full

run-soc-full: compile-soc-full
	cd $(BUILD_DIR) && ./simv_soc_full

soc_full: run-soc-full

# -----------------------------------------------------------------------------
# JTAG/DMI debug module
# -----------------------------------------------------------------------------
DEBUG_RTL := $(RTL_DIR)/debug/jtag_dmi.v
DEBUG_TB  := $(TB_DIR)/tb_jtag_dmi.sv

compile-debug:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(DEBUG_RTL)) $(call abs,$(DEBUG_TB)) \
		-o simv_debug

run-debug: compile-debug
	cd $(BUILD_DIR) && ./simv_debug

debug: run-debug

# -----------------------------------------------------------------------------
# APB peripheral subsystem testbench
# -----------------------------------------------------------------------------
compile-apb:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(APB_RTL)) $(call abs,$(APB_TB)) \
		-o simv_apb

run-apb: compile-apb
	cd $(BUILD_DIR) && ./simv_apb

apb: run-apb

# -----------------------------------------------------------------------------
# Waveform / cleanup
# -----------------------------------------------------------------------------
wave:
	@test -f $(BUILD_DIR)/dump.fsdb || \
		{ echo "No $(BUILD_DIR)/dump.fsdb - run a simulation first"; exit 1; }
	cd $(BUILD_DIR) && $(VERDI) -ssf dump.fsdb &

clean:
	rm -rf $(BUILD_DIR)

LOOPBACK_RTL := $(RTL_DIR)/interconnect/dma_controller.v $(RTL_DIR)/interconnect/ipu_config.v
LOOPBACK_TB  := $(TB_DIR)/tb_dma_ipu_loopback.sv

compile-loopback:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(LOOPBACK_RTL)) $(call abs,$(LOOPBACK_TB)) \
		-o simv_loopback

run-loopback: compile-loopback
	cd $(BUILD_DIR) && ./simv_loopback

loopback: run-loopback

help:
	@echo "Targets:"
	@echo "  make gen            Regenerate rtl/generated/axi_interconnect_wrap_4x4.v"
	@echo "  make interconnect   Compile and run the 4x4 interconnect testbench"
	@echo "                      (add FSDB=1 to dump build/dump.fsdb)"
	@echo "  make axilite        Compile and run the AXI4-Lite test IP testbench"
	@echo "  make wave           Open the latest dump.fsdb in Verdi"
	@echo "  make clean          Remove $(BUILD_DIR)/"
	@echo ""
	@echo "Tool overrides (environment or command line):"
	@echo "  VCS_HOME=$(VCS_HOME)"
	@echo "  VERDI_HOME=$(VERDI_HOME)"
	@echo "  SNPSLMD_LICENSE_FILE=$(SNPSLMD_LICENSE_FILE)"

# -----------------------------------------------------------------------------
# CRU + boot ROM
# -----------------------------------------------------------------------------
bootrom:
	@mkdir -p $(GEN_DIR)
	@echo "Boot ROM image: $(BOOTROM_HEX)"
	@test -f $(BOOTROM_HEX)

compile-cru:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(CRU_RTL)) $(call abs,$(CRU_TB)) \
		-o simv_cru

run-cru: compile-cru
	cd $(BUILD_DIR) && ./simv_cru
