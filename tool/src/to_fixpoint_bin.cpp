 
#include <iostream>
#include <vector>
#include <cmath>
#include <string>

using namespace std;

// ???????????????????????????? Fixed-point Binary (2's Complement)
string to_fixed_point_binary(double value, int frac_bits) {
    int total_bits = 1 + 0 + frac_bits; // 1 (sign) + 0 (int) + x (frac)
    
    // ????????????????????????????? Fixed-point
    //long long int_val = round(value * pow(2, frac_bits));
    long long int_val = floor(value * pow(2, frac_bits));
    
    // ????? String ?????????????
    string binary_str = "";
    
    // ?????? Bit ???????????????????????? (MSB -> LSB)
    for (int i = total_bits - 1; i >= 0; --i) {
        binary_str += ((int_val >> i) & 1) ? '1' : '0';
    }
    
    return binary_str;
}

int main() {
    int num_coef;
    
    // Input 1 : ????? Coefficient
    cout << "Input 1 (How many coef): ";
    cin >> num_coef;
    
    if (num_coef <= 0) {
        cout << "Number of coef must be greater than 0.\n";
        return 1;
    }

    vector<double> coefs(num_coef);
    vector<int> fracs(num_coef);
    
    // Input 2 : ??? Coefficient ????? n ???
    cout << "Input 2 (Enter " << num_coef << " coefficients, space separated): ";
    for (int i = 0; i < num_coef; ++i) {
        cin >> coefs[i];
    }
    
    // Input 3 : ????? frac ????? n ???
    cout << "Input 3 (Enter " << num_coef << " frac values, space separated): ";
    for (int i = 0; i < num_coef; ++i) {
        cin >> fracs[i];
    }
    
    cout << "\n--- Output ---\n";
    
    // ?????????????????????????????
    for (int i = 0; i < num_coef; ++i) {
        double dec = coefs[i];
        int frac = fracs[i];
        int total_bits = 1 + 0 + frac;
        
        string bin_str = to_fixed_point_binary(dec, frac);
        
        cout << "// tap"<< i <<":  <sign=1, int=0, frac=" << frac << ">  dec = " << dec << "\n";
        cout << "localparam signed [" << total_bits-1 << ":0] COEF_" << i << "=" << total_bits << "'sb" << bin_str << ";\n";
    }
    
    return 0;
}
