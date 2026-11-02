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

# Auto-detect tools if present in known Windows/Unix locations
PYTHON ?= $(if $(wildcard C:/Users/kadan/AppData/Local/Programs/Python/Python312/python.exe),C:/Users/kadan/AppData/Local/Programs/Python/Python312/python.exe,python3)
IVERILOG ?= $(if $(wildcard C:/Users/kadan/scoop/apps/iverilog/current/bin/iverilog.exe),C:/Users/kadan/scoop/apps/iverilog/current/bin/iverilog.exe,iverilog)
VVP      ?= $(if $(wildcard C:/Users/kadan/scoop/apps/iverilog/current/bin/vvp.exe),C:/Users/kadan/scoop/apps/iverilog/current/bin/vvp.exe,vvp)

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

IPU_RTL := $(RTL_DIR)/interconnect/ipu_config.v
IPU_TB  := $(TB_DIR)/tb_ipu_config.sv

AXI_APB_RTL := $(RTL_DIR)/interconnect/axi_apb_bridge.v $(RTL_DIR)/interconnect/apb_peripherals.v
AXI_APB_TB  := $(TB_DIR)/tb_axi_apb_bridge.sv

APB_RTL := $(RTL_DIR)/interconnect/ahb_apb_bridge.v $(RTL_DIR)/interconnect/apb_peripherals.v
APB_TB  := $(TB_DIR)/tb_apb_peripherals.sv

CRU_RTL := $(RTL_DIR)/soc/cru.v
CRU_TB  := $(TB_DIR)/tb_cru_reset.sv
BOOTROM_RTL := $(RTL_DIR)/soc/boot_rom.v
BOOTROM_HEX := $(RTL_DIR)/soc/bootrom.hex

SOC_RTL := $(RTL_DIR)/soc/soc_top.v $(RTL_DIR)/soc/axi_ram.v $(BOOTROM_RTL) $(IPU_RTL) $(AXI_APB_RTL) $(CRU_RTL) $(XBAR_RTL)
SOC_TB  := $(TB_DIR)/tb_soc_top.sv

DEBUG_RTL := $(RTL_DIR)/debug/jtag_dmi.v
DEBUG_TB  := $(TB_DIR)/tb_jtag_dmi.sv

LOOPBACK_RTL := \
	$(RTL_DIR)/interconnect/dma_controller.v \
	$(RTL_DIR)/soc/axi_ram.v \
	$(XBAR_RTL)
LOOPBACK_TB  := $(TB_DIR)/tb_dma_ipu_loopback.sv

# VCS is run from inside $(BUILD_DIR), so feed it absolute source paths.
abs = $(addprefix $(CURDIR)/,$(1))

.PHONY: all gen interconnect axilite apb bootrom cru compile-cru run-cru compile-xbar run-xbar compile-axilite \
        run-axilite compile-apb run-apb wave clean help compile-soc-full run-soc-full soc_full \
        compile-loopback run-loopback loopback compile-ipu run-ipu ipu \
        compile-axi-apb run-axi-apb axi-apb c-test hex \
        sim-cru sim-axilite sim-ipu sim-axi-apb sim-apb sim-debug sim-loopback sim-xbar sim-soc sim-all

all: compile-xbar compile-axilite

# -----------------------------------------------------------------------------
# Generated RTL
# -----------------------------------------------------------------------------
gen:
	@mkdir -p $(GEN_DIR) 2>/dev/null || if not exist "$(GEN_DIR)" mkdir "$(GEN_DIR)"
	$(PYTHON) $(SCRIPTS)/axi_interconnect_wrap.py -p 4 4 \
		-n axi_interconnect_wrap_4x4 \
		-o $(GEN_DIR)/axi_interconnect_wrap_4x4.v

# -----------------------------------------------------------------------------
# VCS targets (for college Synopsys environment)
# -----------------------------------------------------------------------------
compile-xbar:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(XBAR_RTL)) $(call abs,$(XBAR_TB)) \
		-o simv_xbar

run-xbar: compile-xbar
	cd $(BUILD_DIR) && ./simv_xbar $(if $(FSDB),+fsdb)

interconnect: run-xbar

compile-axilite:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(AXIL_RTL)) $(call abs,$(AXIL_TB)) \
		-o simv_axilite

run-axilite: compile-axilite
	cd $(BUILD_DIR) && ./simv_axilite

axilite: run-axilite

compile-soc:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(SOC_RTL)) $(call abs,$(SOC_TB)) \
		-o simv_soc

run-soc: compile-soc
	cd $(BUILD_DIR) && ./simv_soc

soc: run-soc

compile-soc-full:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) -cm line+cond+fsm+tgl+branch \
		$(call abs,$(SOC_RTL)) $(call abs,$(SOC_TB)) \
		-o simv_soc_full

run-soc-full: compile-soc-full
	cd $(BUILD_DIR) && ./simv_soc_full

soc_full: run-soc-full

compile-debug:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(DEBUG_RTL)) $(call abs,$(DEBUG_TB)) \
		-o simv_debug

run-debug: compile-debug
	cd $(BUILD_DIR) && ./simv_debug

debug: run-debug

compile-apb:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(APB_RTL)) $(call abs,$(APB_TB)) \
		-o simv_apb

run-apb: compile-apb
	cd $(BUILD_DIR) && ./simv_apb

apb: run-apb

compile-loopback:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(LOOPBACK_RTL)) $(call abs,$(LOOPBACK_TB)) \
		-o simv_loopback

run-loopback: compile-loopback
	cd $(BUILD_DIR) && ./simv_loopback

loopback: run-loopback

compile-ipu:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(IPU_RTL)) $(call abs,$(IPU_TB)) \
		-o simv_ipu

run-ipu: compile-ipu
	cd $(BUILD_DIR) && ./simv_ipu

ipu: run-ipu

compile-axi-apb:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(AXI_APB_RTL)) $(call abs,$(AXI_APB_TB)) \
		-o simv_axi_apb

run-axi-apb: compile-axi-apb
	cd $(BUILD_DIR) && ./simv_axi_apb

axi-apb: run-axi-apb

compile-cru:
	@mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(VCS) $(VCS_FLAGS) \
		$(call abs,$(CRU_RTL)) $(call abs,$(CRU_TB)) \
		-o simv_cru

run-cru: compile-cru
	cd $(BUILD_DIR) && ./simv_cru

# -----------------------------------------------------------------------------
# Icarus Verilog open-source simulation flow (cross-platform / local verification)
# -----------------------------------------------------------------------------
IVLOG_FLAGS := -g2012 -I $(RTL_DIR)/interconnect -I $(RTL_DIR)/soc

sim-cru:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_cru_reset -o $(BUILD_DIR)/sim_cru.vvp $(CRU_RTL) $(CRU_TB)
	"$(VVP)" $(BUILD_DIR)/sim_cru.vvp

sim-axilite:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_axi_lite_test_ip -o $(BUILD_DIR)/sim_axilite.vvp $(AXIL_RTL) $(AXIL_TB)
	"$(VVP)" $(BUILD_DIR)/sim_axilite.vvp

sim-ipu:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_ipu_config -o $(BUILD_DIR)/sim_ipu.vvp $(IPU_RTL) $(IPU_TB)
	"$(VVP)" $(BUILD_DIR)/sim_ipu.vvp

sim-axi-apb:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_axi_apb_bridge -o $(BUILD_DIR)/sim_axi_apb.vvp $(AXI_APB_RTL) $(AXI_APB_TB)
	"$(VVP)" $(BUILD_DIR)/sim_axi_apb.vvp

sim-apb:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_apb_peripherals -o $(BUILD_DIR)/sim_apb.vvp $(APB_RTL) $(APB_TB)
	"$(VVP)" $(BUILD_DIR)/sim_apb.vvp

sim-debug:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_jtag_dmi -o $(BUILD_DIR)/sim_debug.vvp $(DEBUG_RTL) $(DEBUG_TB)
	"$(VVP)" $(BUILD_DIR)/sim_debug.vvp

sim-loopback:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_dma_ipu_loopback -o $(BUILD_DIR)/sim_loopback.vvp $(LOOPBACK_RTL) $(LOOPBACK_TB)
	"$(VVP)" $(BUILD_DIR)/sim_loopback.vvp

sim-xbar:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_axi_interconnect_4x4 -o $(BUILD_DIR)/sim_xbar.vvp $(XBAR_RTL) $(XBAR_TB)
	"$(VVP)" $(BUILD_DIR)/sim_xbar.vvp

sim-soc:
	@mkdir -p $(BUILD_DIR) 2>/dev/null || if not exist "$(BUILD_DIR)" mkdir "$(BUILD_DIR)"
	"$(IVERILOG)" $(IVLOG_FLAGS) -s tb_soc_top -o $(BUILD_DIR)/sim_soc.vvp $(SOC_RTL) $(SOC_TB)
	"$(VVP)" $(BUILD_DIR)/sim_soc.vvp

sim-all: sim-cru sim-axilite sim-ipu sim-axi-apb sim-apb sim-debug sim-loopback sim-xbar sim-soc
	@echo "========================================================"
	@echo "ALL 9 SIMULATIONS PASSED SUCCESSFULLY"
	@echo "========================================================"

# -----------------------------------------------------------------------------
# Software flow (RISC-V cross-compilation & HEX generation)
# -----------------------------------------------------------------------------
c-test:
	$(MAKE) -C sw PYTHON="$(PYTHON)"

hex: c-test
	@echo "Generated HEX: sw/test.hex"
	@test -f sw/test.hex || if exist sw\test.hex exit 0

bootrom: hex
	@cp sw/test.hex $(BOOTROM_HEX) 2>/dev/null || copy /y sw\test.hex $(subst /,\,$(BOOTROM_HEX))
	@echo "Boot ROM updated with compiled software hex"

# -----------------------------------------------------------------------------
# Waveform / cleanup
# -----------------------------------------------------------------------------
wave:
	@test -f $(BUILD_DIR)/dump.fsdb || \
		{ echo "No $(BUILD_DIR)/dump.fsdb - run a simulation first"; exit 1; }
	cd $(BUILD_DIR) && $(VERDI) -ssf dump.fsdb &

clean:
	-rm -rf $(BUILD_DIR) 2>/dev/null || rd /s /q $(BUILD_DIR) 2>nul || true
	$(MAKE) -C sw clean

help:
	@echo "RISC-V VeeR EL2 SoC Makefile Targets:"
	@echo "  make sim-all        Run all 9 unit and integrated simulations with Icarus Verilog"
	@echo "  make sim-soc        Run integrated full SoC simulation (SRAM, Boot ROM, IPU, APB)"
	@echo "  make sim-xbar       Run 4x4 AXI interconnect crossbar simulation"
	@echo "  make sim-cru        Run CRU reset controller simulation"
	@echo "  make sim-axilite    Run AXI-Lite IP simulation"
	@echo "  make sim-ipu        Run IPU configuration register block simulation"
	@echo "  make sim-axi-apb    Run AXI-to-APB bridge simulation"
	@echo "  make sim-apb        Run APB peripherals subsystem simulation"
	@echo "  make sim-debug      Run JTAG DMI debug controller simulation"
	@echo "  make sim-loopback   Run DMA + IPU crossbar loopback simulation"
	@echo "  make c-test         Cross-compile RISC-V test firmware with rv32imc gcc"
	@echo "  make hex            Generate word-addressed test.hex firmware image"
	@echo "  make bootrom        Copy compiled test.hex to rtl/soc/bootrom.hex"
	@echo "  make gen            Regenerate 4x4 interconnect RTL wrapper"
	@echo "  make clean          Remove build products"
	@echo ""
	@echo "College Synopsys VCS Targets:"
	@echo "  make run-xbar, run-soc, run-soc-full, run-cru, run-apb, run-ipu, run-loopback"
