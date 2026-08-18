// ===================================================================
// fir_hpf15.v
// Direct-Form FIR, 15 taps
// Coefficient ถูก HARDCODE เป็น localparam ในไฟล์นี้เลย (ไม่รับผ่าน port)
// แต่ละ tap มี format <sign, int, frac> ความยาวเฉพาะของตัวเอง
//
// *** ค่า coefficient ด้านล่างเป็นเพียง 'ตัวอย่าง' เท่านั้น ***
// *** ให้แทนที่ตัวเลขใน COEF_x ด้วยค่าจริงของคุณ (บิตไบนารี two's complement) ***
//
// เนื่องจากแต่ละ tap มีจำนวนบิตเศษส่วน (frac) ไม่เท่ากัน ผลคูณแต่ละ tap จึงมี
// สเกล(scale)ไม่เท่ากัน -> ต้อง shift ให้ frac ตรงกัน (เทียบกับ FRAC_MAX) ก่อนบวกรวม
// การ shift นี้เป็นค่าคงที่ตอน compile ไม่เสีย hardware เพิ่ม (แค่การเดินสาย/ปะ 0)
// ===================================================================
module hpf_rtl #(
    parameter integer DATA_W   = 8,
    parameter integer ACC_W    = 13
)(
    input  wire                       clk,
    input  wire                       rst_n,
    //input  wire                       in_valid,
    input  wire signed [DATA_W-1:0]   data_in,

    //output reg                        out_valid,
    output reg  signed [ACC_W-1:0]   data_out
);

    // ---------------- coefficient แต่ละ tap: <sign, int, frac> ตัวอย่าง ----------------

    //tap0:  <sign=1, int=0, frac=6>  dec = -0.0138499
    localparam signed [6:0] COEF_0=7'sb1111111;
    // tap1:  <sign=1, int=0, frac=7>  dec = -0.00270704
    localparam signed [7:0] COEF_1=8'sb11111111;
    // tap2:  <sign=1, int=0, frac=5>  dec = 0.0390404
    localparam signed [5:0] COEF_2=6'sb000001;
    // tap3:  <sign=1, int=0, frac=6>  dec = 0.0782134
    localparam signed [6:0] COEF_3=7'sb0000101;
    // tap4:  <sign=1, int=0, frac=7>  dec = 0.0404444
    localparam signed [7:0] COEF_4=8'sb00000101;
    // tap5:  <sign=1, int=0, frac=6>  dec = -0.106458
    localparam signed [6:0] COEF_5=7'sb1111001;
    // tap6:  <sign=1, int=0, frac=6>  dec = -0.288414
    localparam signed [6:0] COEF_6=7'sb1101101;
    // tap7:  <sign=1, int=0, frac=3>  dec = 0.628445
    localparam signed [3:0] COEF_7=4'sb0101;
    // tap8:  <sign=1, int=0, frac=6>  dec = -0.288414
    localparam signed [6:0] COEF_8=7'sb1101101;
    // tap9:  <sign=1, int=0, frac=6>  dec = -0.106458
    localparam signed [6:0] COEF_9=7'sb1111001;
    // tap10:  <sign=1, int=0, frac=7>  dec = 0.0404444
    localparam signed [7:0] COEF_10=8'sb00000101;
    // tap11:  <sign=1, int=0, frac=6>  dec = 0.0782134
    localparam signed [6:0] COEF_11=7'sb0000101;
    // tap12:  <sign=1, int=0, frac=5>  dec = 0.0390404
    localparam signed [5:0] COEF_12=6'sb000001;
    // tap13:  <sign=1, int=0, frac=7>  dec = -0.00270704
    localparam signed [7:0] COEF_13=8'sb11111111;
    // tap14:  <sign=1, int=0, frac=6>  dec = -0.0138499
    localparam signed [6:0] COEF_14=7'sb1111111;

    // ---------------- tapped delay line (D -> D -> ... -> D) ----------------
    reg signed [DATA_W-1:0] tap [0:14];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 15; i = i + 1)
                tap[i] <= {DATA_W{1'b0}};
        end else begin
            tap[0] <= data_in;
            for (i = 1; i < 15; i = i + 1)
                tap[i] <= tap[i-1];
        end
    end

    // ---------------- multiply (แต่ละ tap x coefficient เฉพาะของตัวเอง) ----------------
    wire signed [DATA_W+7-1:0] mult_0 = tap[0] * COEF_0;
    wire signed [DATA_W+8-1:0] mult_1 = tap[1] * COEF_1;
    wire signed [DATA_W+6-1:0] mult_2 = tap[2] * COEF_2;
    wire signed [DATA_W+7-1:0] mult_3 = tap[3] * COEF_3;
    wire signed [DATA_W+8-1:0] mult_4 = tap[4] * COEF_4;

    wire signed [DATA_W+7-1:0] mult_5 = tap[5] * COEF_5;
    wire signed [DATA_W+7-1:0] mult_6 = tap[6] * COEF_6;
    wire signed [DATA_W+4-1:0] mult_7 = tap[7] * COEF_7;
    wire signed [DATA_W+7-1:0] mult_8 = tap[8] * COEF_8;
    wire signed [DATA_W+7-1:0] mult_9 = tap[9] * COEF_9;

    wire signed [DATA_W+8-1:0] mult_10 = tap[10] * COEF_10;
    wire signed [DATA_W+7-1:0] mult_11 = tap[11] * COEF_11;
    wire signed [DATA_W+6-1:0] mult_12 = tap[12] * COEF_12;
    wire signed [DATA_W+8-1:0] mult_13 = tap[13] * COEF_13;
    wire signed [DATA_W+7-1:0] mult_14 = tap[14] * COEF_14;

    // ---------------- align frac (shift ซ้ายตาม SHIFT_x) ก่อนบวกรวม ----------------
    wire signed [ACC_W-1:0] mult_aligned_0 = {mult_0[DATA_W+7-1],mult_0[DATA_W+7-3:DATA_W+7-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_1 = {mult_1[DATA_W+8-1],mult_1[DATA_W+8-3:DATA_W+8-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_2 = {mult_2[DATA_W+6-1],mult_2[DATA_W+6-3:DATA_W+6-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_3 = {mult_3[DATA_W+7-1],mult_3[DATA_W+7-3:DATA_W+7-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_4 = {mult_4[DATA_W+8-1],mult_4[DATA_W+8-3:DATA_W+8-3-11]};
                                                                 
    wire signed [ACC_W-1:0] mult_aligned_5 = {mult_5[DATA_W+7-1],mult_5[DATA_W+7-3:DATA_W+7-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_6 = {mult_6[DATA_W+7-1],mult_6[DATA_W+7-3:DATA_W+7-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_7 = {mult_7[DATA_W+4-1],mult_7[DATA_W+4-3:DATA_W+4-3-11+2],2'b00};
    wire signed [ACC_W-1:0] mult_aligned_8 = {mult_8[DATA_W+7-1],mult_8[DATA_W+7-3:DATA_W+7-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_9 = {mult_9[DATA_W+7-1],mult_9[DATA_W+7-3:DATA_W+7-3-11]};

    wire signed [ACC_W-1:0] mult_aligned_10 = {mult_10[DATA_W+8-1],mult_10[DATA_W+8-3:DATA_W+8-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_11 = {mult_11[DATA_W+7-1],mult_11[DATA_W+7-3:DATA_W+7-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_12 = {mult_12[DATA_W+6-1],mult_12[DATA_W+6-3:DATA_W+6-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_13 = {mult_13[DATA_W+8-1],mult_13[DATA_W+8-3:DATA_W+8-3-11]};
    wire signed [ACC_W-1:0] mult_aligned_14 = {mult_14[DATA_W+7-1],mult_14[DATA_W+7-3:DATA_W+7-3-11]};

// ---------------- adder tree (Pipelined 4 stages) ----------------
    adder_tree_15 #(
        .W(ACC_W)
    ) u_adder_tree (
        .clk    (clk),
        .rst_n  (rst_n),
        .in0    (mult_aligned_0),
        .in1    (mult_aligned_1),
        .in2    (mult_aligned_2),
        .in3    (mult_aligned_3),
        .in4    (mult_aligned_4),
        .in5    (mult_aligned_5),
        .in6    (mult_aligned_6),
        .in7    (mult_aligned_7),
        .in8    (mult_aligned_8),
        .in9    (mult_aligned_9),
        .in10   (mult_aligned_10),
        .in11   (mult_aligned_11),
        .in12   (mult_aligned_12),
        .in13   (mult_aligned_13),
        .in14   (mult_aligned_14),
        .out_sum(data_out) // ส่งผลรวมออกไปยัง port data_out โดยตรง
    );
endmodule
