module adder_tree_17 #(
    parameter W = 11 // ความกว้างของบิต (ตั้งค่าเริ่มต้นให้ตรงกับ ACC_W)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [W-1:0] in0,  in1,  in2,  in3, 
    input  wire signed [W-1:0] in4,  in5,  in6,  in7, 
    input  wire signed [W-1:0] in8,  in9,  in10, in11,
    input  wire signed [W-1:0] in12, in13, in14, in15, 
    input  wire signed [W-1:0] in16,
    output reg  signed [W-1:0] out_sum
);

    // ==========================================
    // Stage 1: 17 Inputs -> 8 Adders + 1 Pass-through
    // ==========================================
    reg signed [W-1:0] stg1_0, stg1_1, stg1_2, stg1_3;
    reg signed [W-1:0] stg1_4, stg1_5, stg1_6, stg1_7, stg1_8;

    // ==========================================
    // Stage 2: 9 Inputs -> 4 Adders + 1 Pass-through
    // ==========================================
    reg signed [W-1:0] stg2_0, stg2_1, stg2_2, stg2_3, stg2_4;

    // ==========================================
    // Stage 3: 5 Inputs -> 2 Adders + 1 Pass-through
    // ==========================================
    reg signed [W-1:0] stg3_0, stg3_1, stg3_2;

    // ==========================================
    // Stage 4: 3 Inputs -> 1 Adder + 1 Pass-through
    // ==========================================
    reg signed [W-1:0] stg4_0, stg4_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stg1_0 <= 0; stg1_1 <= 0; stg1_2 <= 0; stg1_3 <= 0;
            stg1_4 <= 0; stg1_5 <= 0; stg1_6 <= 0; stg1_7 <= 0; stg1_8 <= 0;
            stg2_0 <= 0; stg2_1 <= 0; stg2_2 <= 0; stg2_3 <= 0; stg2_4 <= 0;
            stg3_0 <= 0; stg3_1 <= 0; stg3_2 <= 0;
            stg4_0 <= 0; stg4_1 <= 0;
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
            stg1_7 <= in14 + in15;
            stg1_8 <= in16; // รอเพื่อน

            // --- Stage 2 ---
            stg2_0 <= stg1_0 + stg1_1;
            stg2_1 <= stg1_2 + stg1_3;
            stg2_2 <= stg1_4 + stg1_5;
            stg2_3 <= stg1_6 + stg1_7;
            stg2_4 <= stg1_8; // รอเพื่อน

            // --- Stage 3 ---
            stg3_0 <= stg2_0 + stg2_1;
            stg3_1 <= stg2_2 + stg2_3;
            stg3_2 <= stg2_4; // รอเพื่อน

            // --- Stage 4 ---
            stg4_0 <= stg3_0 + stg3_1;
            stg4_1 <= stg3_2; // รอเพื่อน

            // --- Stage 5 (Output) ---
            out_sum <= stg4_0 + stg4_1;
        end
    end
endmodule