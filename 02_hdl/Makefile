# --- Directories -------------------------------------------------------------
RTL_DIR      := 00_rtl
TB_DIR       := 01_tb
FL_DIR       := 02_filelist
PRE_DIR      := 03_sim/00_pre_sim
SYN_DIR      := 03_sim/01_synthesis
POST_DIR     := 03_sim/02_post_sim

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

