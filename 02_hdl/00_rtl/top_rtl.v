// =====================================================================
// lpf_hpf_top.v
// Top module: INPUT -> LPF (17 taps, coef hardcode) -> HPF (15 taps, coef hardcode) -> OUTPUT
// coefficient ทั้งหมดถูกฝัง (localparam) อยู่ภายใน fir_lpf17.v / fir_hpf15.v แล้ว
// จึงไม่ต้องส่ง coefficient เข้ามาจากภายนอกอีก
// =====================================================================
module lpf_hpf_top #(
    parameter integer DATA_W = 16
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     in_valid,
    input  wire signed [DATA_W-1:0] data_in,

    output wire                     out_valid,
    output wire signed [DATA_W-1:0] data_out
);

    wire                     lpf_out_valid;
    wire signed [DATA_W-1:0] lpf_data_out;

    fir_lpf17 #(
        .DATA_W (DATA_W)
    ) u_lpf (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (in_valid),
        .data_in   (data_in),
        .out_valid (lpf_out_valid),
        .data_out  (lpf_data_out)
    );

    fir_hpf15 #(
        .DATA_W (DATA_W)
    ) u_hpf (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (lpf_out_valid),
        .data_in   (lpf_data_out),
        .out_valid (out_valid),
        .data_out  (data_out)
    );

endmodule
