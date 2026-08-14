CXX = g++
BIN_DIR = bin
SRC_DIR = src
LOG_FILE = tests/log/input_bit.txt

all: compile run sqnr

setup:
	@mkdir -p bin
	@mkdir -p tests
	@cp ../assets/input_data.txt tests/input.txt

compile:
	$(CXX) $(SRC_DIR)/band_pass_filter.cpp -o $(BIN_DIR)/band_pass_filter

run: 
	cd tests && ../$(BIN_DIR)/band_pass_filter

sqnr:
	cd tests && ../../tool/bin/sqnr


sweep:
	#@cd $(TEST) && echo "sweep0" >> $(LOG_FILE)
	#echo "node  lpf" >> tests/log.log
	@echo > $(LOG_FILE)
	@for i in $$(seq 0 15); do \
		echo -n "Compiling and running with SWEEP0=$$i  "; \
		$(CXX) $(SRC_DIR)/band_pass_filter.cpp -o $(BIN_DIR)/band_pass_filter -DSWEEP0=$$i || exit 1; \
		(cd tests && ../$(BIN_DIR)/band_pass_filter); \
		(cd tests && ../../tool/bin/sqnr | tee -a ../$(LOG_FILE)); \
	done
	@echo "---"
	#@cd $(TEST) && echo " " >> $(LOG_FILE)
