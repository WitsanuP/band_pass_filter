# --- Directories -------------------------------------------------------------
RTL_DIR      := 00_rtl
TB_DIR       := 01_tb
FL_DIR       := 02_filelist
PRE_DIR      := 04_sim/00_pre_sim
SYN_DIR      := 04_sim/01_synthesis
POST_DIR     := 04_sim/02_post_sim

#  # --- Filelists ----------------------------------------------------------------
FL_RTL       := $(FL_DIR)/rtl.f
FL_TB        := $(FL_DIR)/tb.f
FL_GATE      := $(FL_DIR)/gate.f

# =============================================================================
# #  PRE-SIM  (RTL simulation)
# # =============================================================================
.PHONY: pre_sim pre_compile pre_run pre_wave
 
pre_sim: pre_compile pre_run         ## full pre-sim: compile + simulate
 
pre_compile:                         ## VCS compile (RTL)
	mkdir -p $(PRE_DIR)
	cd $(PRE_DIR) && vcs  -full64 -sverilog \
	    -file ../../$(FL_RTL) \
	    -file ../../$(FL_TB) \
	    -debug_access \
	    -o simv \
	    -l compile.log
 
pre_run:                             ## run simulation
	cd $(PRE_DIR) && ./simv -l sim.log
	@echo "[pre] sim done"
 
pre_wave:                            ## open waveform
	cd $(PRE_DIR) && nWave $$(ls *.fsdb | head -1) &


# =============================================================================
#  SYNTHESIS
# =============================================================================
.PHONY: syn syn_check

syn:                                 ## run synthesis (DC/Genus via TCL)
	mkdir -p $(SYN_DIR)
	cp 03_script/env/.synopsys_dc.setup $(SYN_DIR)
	cd $(SYN_DIR) && dc_shell -f ../../03_script/default.tcl | tee dc_shell.log
	@echo "[syn] done"
	#@echo "[syn] done - netlist: $(NETLIST)"

syn_check:                           ## quick lint before synthesis
	cd $(SYN_DIR) && hal -f ../../$(FL_RTL) | tee lint.log






# =============================================================================
#  POST-SIM  (gate-level simulation with SDF back-annotation)
# =============================================================================
.PHONY: post_sim post_compile post_run post_wave

post_sim: post_compile post_run      ## full post-sim: compile + simulate
 
post_compile:                        ## VCS compile (netlist + SDF)
	mkdir -p $(POST_DIR)
	cd $(POST_DIR) && vcs -full64 -sverilog  -f ../../02_filelist/gate.f \
		-P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab \
		$(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a
	@echo "[post] compile and sim done"
	#@echo "[post] compile done"
 
post_run:                            ## run gate-level simulation
	cd $(POST_DIR) && ./simv -l sim.log
	@echo "[post] sim done"
 
post_wave:                           ## open post-sim waveform
	cd $(POST_DIR) && nWave $$(ls *.fsdb | head -1) &

tmp:
	cd 04_sim/02_post_sim && vcs -full64 -f ../../02_filelist/gate.f -o simv -l compile.log
