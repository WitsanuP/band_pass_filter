module adder_tree_15 #(
    parameter W = 13 // ??????????????? (???????????????????????? ACC_W ?? hpf_rtl)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [W-1:0] in0,  in1,  in2,  in3, 
    input  wire signed [W-1:0] in4,  in5,  in6,  in7, 
    input  wire signed [W-1:0] in8,  in9,  in10, in11,
    input  wire signed [W-1:0] in12, in13, in14, 
    output reg  signed [W-1:0] out_sum
);

    // ==========================================
    // Stage 1: 15 Inputs -> 7 Adders + 1 Pass-through
    // ==========================================
    reg signed [W-1:0] stg1_0, stg1_1, stg1_2, stg1_3;
    reg signed [W-1:0] stg1_4, stg1_5, stg1_6, stg1_7;

    // ==========================================
    // Stage 2: 8 Inputs -> 4 Adders
    // ==========================================
    reg signed [W-1:0] stg2_0, stg2_1, stg2_2, stg2_3;

    // ==========================================
    // Stage 3: 4 Inputs -> 2 Adders
    // ==========================================
    reg signed [W-1:0] stg3_0, stg3_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stg1_0 <= 0; stg1_1 <= 0; stg1_2 <= 0; stg1_3 <= 0;
            stg1_4 <= 0; stg1_5 <= 0; stg1_6 <= 0; stg1_7 <= 0;
            stg2_0 <= 0; stg2_1 <= 0; stg2_2 <= 0; stg2_3 <= 0;
            stg3_0 <= 0; stg3_1 <= 0;
            out_sum <= 0;
        end else begin
            // --- Stage 1 ---
            stg1_0 <= in0  + in1;
            stg1_1 <= in2  + in3;
            stg1_2 <= in4  + in5;
            stg1_3 <= in6  + in7;
            stg1_4 <= in8  + in9;
            stg1_5 <= in10 + in11;
            stg1_6 <= in12 + in13;
            stg1_7 <= in14; // in14 ???????? ???????????????? Stage ????????

            // --- Stage 2 ---
            stg2_0 <= stg1_0 + stg1_1;
            stg2_1 <= stg1_2 + stg1_3;
            stg2_2 <= stg1_4 + stg1_5;
            stg2_3 <= stg1_6 + stg1_7;

            // --- Stage 3 ---
            stg3_0 <= stg2_0 + stg2_1;
            stg3_1 <= stg2_2 + stg2_3;

            // --- Stage 4 (Output) ---
            out_sum <= stg3_0 + stg3_1;
        end
    end
endmodule