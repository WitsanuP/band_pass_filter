#include <iostream>
#include <fstream>
#include <vector>
#include <cmath>
#include <string>

// Function to read floating point values line-by-line from a text file
bool readDataFromFile(const std::string& filename, std::vector<double>& data) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filename << std::endl;
        return false;
    }

    double val;
    while (file >> val) {
        data.push_back(val);
    }

    file.close();
    return true;
}

int main() {
    std::string originalFile = "original.txt";
    std::string quantizedFile = "quantized.txt";

    std::vector<double> x; // Original signal
    std::vector<double> y; // Quantized signal

    if (!readDataFromFile(originalFile, x) || !readDataFromFile(quantizedFile, y)) {
        return 1;
    }

    if (x.size() != y.size()) {
        std::cerr << "Error: File sizes do not match! (" 
                  << x.size() << " vs " << y.size() << " samples)" << std::endl;
        return 1;
    }

    if (x.empty()) {
        std::cerr << "Error: Files are empty." << std::endl;
        return 1;
    }

    double signalPower = 0.0;
    double noisePower = 0.0;

    for (size_t i = 0; i < x.size(); ++i) {
        signalPower += x[i] * x[i];
        double error = x[i] - y[i];
        noisePower += error * error;
    }

    // Check for zero noise (perfect reconstruction)
    if (noisePower == 0.0) {
        std::cout << "Noise power is zero (Perfect reconstruction). SQNR is infinite." << std::endl;
        return 0;
    }

    double sqnrLinear = signalPower / noisePower;
    double sqnrDB = 10.0 * std::log10(sqnrLinear);

    // Output to console
    //std::cout << "Signal Power: " << signalPower << std::endl;
    //std::cout << "Noise Power:  " << noisePower << std::endl;
    //std::cout << "SQNR (dB):    " << sqnrDB << " dB" << std::endl;
    std::cout << sqnrDB << "," << std::endl;

    return 0;
}
