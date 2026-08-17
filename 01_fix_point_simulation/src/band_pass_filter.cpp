#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <iomanip>
#include "../include/band_pass_filter.h"
#include "bit_trunc.cpp"

// Function to apply an FIR filter using Direct Form Discrete Convolution:
// y[n] = sum(k = 0 to M-1) w[k] * x[n - k]
std::vector<double> applyFIRFilter(const std::vector<double>& input, const std::vector<double>& weights, const std::vector<double>& BIT_TRUNC) {
    size_t signalLength = input.size();
    size_t numWeights = weights.size();
    std::vector<double> output(signalLength, 0.0);

    for (size_t n = 0; n < signalLength; ++n) {
        double sum = 0.0;
        for (size_t k = 0; k < numWeights; ++k) {
            // Check boundary to handle zero-padding for initial samples
            if (n >= k) {
                sum += bit_trunc( bit_trunc(weights[k], BIT_TRUNC[k]) * bit_trunc(input[n - k],BIT_INPUT1), BIT_ADDER1);
            }
        }
        output[n] =  bit_trunc(sum, BIT_ADDER1);
    }
    return output;
}
std::vector<double> applyFIRFilter2(const std::vector<double>& input, const std::vector<double>& weights, const std::vector<double>& BIT_TRUNC) {
    size_t signalLength = input.size();
    size_t numWeights = weights.size();
    std::vector<double> output(signalLength, 0.0);

    for (size_t n = 0; n < signalLength; ++n) {
        double sum = 0.0;
        for (size_t k = 0; k < numWeights; ++k) {
            // Check boundary to handle zero-padding for initial samples
            if (n >= k) {
                sum += bit_trunc( bit_trunc(weights[k], BIT_TRUNC[k]) * bit_trunc(input[n - k],BIT_INPUT2), BIT_ADDER2);
            }
        }
        output[n] =  bit_trunc(sum, BIT_ADDER2);
    }
    return output;
}

int main() {
    // 1. Define input and output file paths
    std::string inputFilename = "input.txt";     // Replace with your input file name
    std::string outputFilename = "quantized.txt";   // Output destination file

    // 2. Define High-Pass Filter (HPF) and Low-Pass Filter (LPF) coefficients (15 taps each)
    // Replace these placeholder values with your actual 15-element weight vectors

    // 3. Open and read data from the space-separated input text file
    std::ifstream inputFile(inputFilename);
    if (!inputFile.is_open()) {
        std::cerr << "Error: Could not open input file " << inputFilename << std::endl;
        return 1;
    }

    std::vector<double> inputSignal;
    double sampleValue;
    
    // std::cin operator >> automatically parses space, tab, and newline delimiters
    while (inputFile >> sampleValue) {
        inputSignal.push_back(sampleValue);
    }
    inputFile.close();

    std::cout << "Successfully loaded " << inputSignal.size() << " samples from file." << std::endl;

    if (inputSignal.empty()) {
        std::cerr << "Error: The input file is empty!" << std::endl;
        return 1;
    }

    // 4. Cascade Filtering: Input Signal -> LPF Stage -> HPF Stage -> Final BPF Output
    std::vector<double> bpfOutput = applyFIRFilter(inputSignal, lpfWeights, bit_trunc_lpf );
    std::vector<double> hpfOutput = applyFIRFilter2(bpfOutput, hpfWeights, bit_trunc_hpf );

    // 5. Write the final Band-Pass filtered results to output.txt separated by spaces
    std::ofstream outputFile(outputFilename);
    if (!outputFile.is_open()) {
        std::cerr << "Error: Could not create output file " << outputFilename << std::endl;
        return 1;
    }

    outputFile << std::fixed << std::setprecision(20);
    for (size_t i = 0; i < hpfOutput.size(); ++i) {
        outputFile << hpfOutput[i] << (i == hpfOutput.size() - 1 ? "" : " ");
        outputFile << std::endl;
    }
    outputFile.close();

    std::cout << "Processing complete! Filtered output saved to " << outputFilename << std::endl;

    return 0;
}
