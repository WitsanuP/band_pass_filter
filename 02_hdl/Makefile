#all: clean compile sim wave
rerun: compile sim 
compile:
	mkdir -p 03_sim/00_pre_sim
	cd 03_sim/00_pre_sim && vcs -full64 -sverilog -file ../../02_filelist/filelist.f -debug_access -o simv -l compile.log
sim:
	cd 03_sim/00_pre_sim && ./simv -l sim.log
wave:
	cd 03_sim/00_pre_sim && nWave *.fsdb &
#clean:
	#@cd 03_sim && rm -rf *
	#@echo "it's clean"
