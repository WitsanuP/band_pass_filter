// =====================================================================
// lpf_hpf_top.v
// Top module: INPUT -> LPF (17 taps, coef hardcode) -> HPF (15 taps, coef hardcode) -> OUTPUT
// coefficient ทั้งหมดถูกฝัง (localparam) อยู่ภายใน fir_lpf17.v / fir_hpf15.v แล้ว
// จึงไม่ต้องส่ง coefficient เข้ามาจากภายนอกอีก
// =====================================================================
`timescale 1ns/1ps
module top_rtl 
(
    input  wire                     clk,
    input  wire                     rst_n,
    //input  wire                     in_valid,
    input  wire signed [8:0] data_in,

    //output wire                     out_valid,
    output wire signed [12:0] data_out
);

    wire signed [10:0] lpf_data_out;
    wire signed [7:0] input_hpf;
    assign input_hpf = lpf_data_out[10:3];
    //assign input_hpf = {lpf_data_out[10],{0},lpf_data_out[9:2]};

    lpf_rtl  u_lpf (
        .clk       (clk),
        .rst_n     (rst_n),
        //.in_valid  (in_valid),
        .data_in   (data_in),
        //.out_valid (lpf_out_valid),
        .data_out  (lpf_data_out)
    );

    hpf_rtl u_hpf (
        .clk       (clk),
        .rst_n     (rst_n),
        //.in_valid  (lpf_out_valid),
        .data_in   (input_hpf),
        //.out_valid (out_valid),
        .data_out  (data_out)
    );

endmodule
