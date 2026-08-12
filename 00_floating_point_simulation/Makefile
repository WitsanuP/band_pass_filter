CXX = g++
BIN_DIR = bin
SRC_DIR = src

all: compile run

setup:
	@mkdir -p bin
	@mkdir -p tests
	@cp ../assets/input_data.txt tests/input.txt

compile:
	$(CXX) $(SRC_DIR)/band_pass_filter.cpp -o $(BIN_DIR)/band_pass_filter

run: 
	cd tests && ../$(BIN_DIR)/band_pass_filter
