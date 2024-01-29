SHELL=/bin/bash -o pipefail

# PKG_SRCS := $(PWD)/pkg/rv32i_mux_types.sv $(PWD)/pkg/rv32i_types.sv $(PWD)/pkg/my_types.sv
PKG_SRCS := $(PWD)/m_type.sv
HDL_SRCS := $(shell find $(PWD)/m_extension -name '*.sv')
# HVL_SRCS := $(shell find $(PWD)/hvl -name '*.sv' -o -name '*.v')
# SRCS := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS)

# HDL_SRCS :=$(PWD)/dadda_tree.sv
HVL_SRCS :=$(PWD)/m_extension_top_tb.sv
SRCS := $(PKG_SRCS) $(HDL_SRCS) $(HVL_SRCS)


VCS_FLAGS= -full64 -lca -sverilog +lint=all,noNS -timescale=1ns/1ns -debug_acc+all -kdb -fsdb

sim/dadda_tree_dut_tb : $(SRCS)
	mkdir -p sim
	cd sim && vcs $(SRCS) $(VCS_FLAGS) -msg_config=$(PWD)/vcs_warn.config -l compile_dut.log -top dadda_tree_dut_tb -o dadda_tree_dut_tb

.PHONY: run
run: sim/dadda_tree_dut_tb
	cd sim && ./dadda_tree_dut_tb -l simulation_dut.log

.PHONY: clean
clean: 
	rm -rf sim verdi
