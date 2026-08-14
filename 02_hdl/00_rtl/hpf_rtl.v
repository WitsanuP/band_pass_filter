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
module fir_hpf15 #(
    parameter integer DATA_W   = 16,
    parameter integer FRAC_MAX = 10,   // จำนวนบิตเศษส่วนมากสุดในบรรดา tap ทั้งหมด
    parameter integer ACC_W    = 46
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       in_valid,
    input  wire signed [DATA_W-1:0]   data_in,

    output reg                        out_valid,
    output reg  signed [DATA_W-1:0]   data_out
);

    // ---------------- coefficient แต่ละ tap: <sign, int, frac> ตัวอย่าง ----------------
    // tap0: <sign=1, int=1, frac=4> width=6 bit  ตัวอย่างค่า = -0.02
    localparam signed [5:0] COEF_0 = 6'sb000000;
    // tap1: <sign=1, int=2, frac=5> width=8 bit  ตัวอย่างค่า = 0.04
    localparam signed [7:0] COEF_1 = 8'sb00000001;
    // tap2: <sign=1, int=2, frac=6> width=9 bit  ตัวอย่างค่า = -0.07
    localparam signed [8:0] COEF_2 = 9'sb111111100;
    // tap3: <sign=1, int=3, frac=7> width=11 bit  ตัวอย่างค่า = 0.1
    localparam signed [10:0] COEF_3 = 11'sb00000001101;
    // tap4: <sign=1, int=3, frac=8> width=12 bit  ตัวอย่างค่า = -0.18
    localparam signed [11:0] COEF_4 = 12'sb111111010010;
    // tap5: <sign=1, int=3, frac=9> width=13 bit  ตัวอย่างค่า = 0.28
    localparam signed [12:0] COEF_5 = 13'sb0000010001111;
    // tap6: <sign=1, int=3, frac=10> width=14 bit  ตัวอย่างค่า = -0.6
    localparam signed [13:0] COEF_6 = 14'sb11110110011010;
    // tap7: <sign=1, int=3, frac=9> width=13 bit  ตัวอย่างค่า = 1.0
    localparam signed [12:0] COEF_7 = 13'sb0001000000000;
    // tap8: <sign=1, int=3, frac=8> width=12 bit  ตัวอย่างค่า = -0.6
    localparam signed [11:0] COEF_8 = 12'sb111101100110;
    // tap9: <sign=1, int=3, frac=7> width=11 bit  ตัวอย่างค่า = 0.28
    localparam signed [10:0] COEF_9 = 11'sb00000100100;
    // tap10: <sign=1, int=2, frac=6> width=9 bit  ตัวอย่างค่า = -0.18
    localparam signed [8:0] COEF_10 = 9'sb111110100;
    // tap11: <sign=1, int=2, frac=5> width=8 bit  ตัวอย่างค่า = 0.1
    localparam signed [7:0] COEF_11 = 8'sb00000011;
    // tap12: <sign=1, int=1, frac=4> width=6 bit  ตัวอย่างค่า = -0.07
    localparam signed [5:0] COEF_12 = 6'sb111111;
    // tap13: <sign=1, int=1, frac=4> width=6 bit  ตัวอย่างค่า = 0.04
    localparam signed [5:0] COEF_13 = 6'sb000001;
    // tap14: <sign=1, int=1, frac=4> width=6 bit  ตัวอย่างค่า = -0.02
    localparam signed [5:0] COEF_14 = 6'sb000000;

    // ---------------- shift amount ต่อ tap เพื่อ align frac ให้ตรงกับ FRAC_MAX ----------------
    localparam integer SHIFT_0 = 6;
    localparam integer SHIFT_1 = 5;
    localparam integer SHIFT_2 = 4;
    localparam integer SHIFT_3 = 3;
    localparam integer SHIFT_4 = 2;
    localparam integer SHIFT_5 = 1;
    localparam integer SHIFT_6 = 0;
    localparam integer SHIFT_7 = 1;
    localparam integer SHIFT_8 = 2;
    localparam integer SHIFT_9 = 3;
    localparam integer SHIFT_10 = 4;
    localparam integer SHIFT_11 = 5;
    localparam integer SHIFT_12 = 6;
    localparam integer SHIFT_13 = 6;
    localparam integer SHIFT_14 = 6;

    // ---------------- tapped delay line (D -> D -> ... -> D) ----------------
    reg signed [DATA_W-1:0] tap [0:14];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 15; i = i + 1)
                tap[i] <= {DATA_W{1'b0}};
        end else if (in_valid) begin
            tap[0] <= data_in;
            for (i = 1; i < 15; i = i + 1)
                tap[i] <= tap[i-1];
        end
    end

    // ---------------- multiply (แต่ละ tap x coefficient เฉพาะของตัวเอง) ----------------
    wire signed [DATA_W+6-1:0] mult_0 = tap[0] * COEF_0;
    wire signed [DATA_W+8-1:0] mult_1 = tap[1] * COEF_1;
    wire signed [DATA_W+9-1:0] mult_2 = tap[2] * COEF_2;
    wire signed [DATA_W+11-1:0] mult_3 = tap[3] * COEF_3;
    wire signed [DATA_W+12-1:0] mult_4 = tap[4] * COEF_4;
    wire signed [DATA_W+13-1:0] mult_5 = tap[5] * COEF_5;
    wire signed [DATA_W+14-1:0] mult_6 = tap[6] * COEF_6;
    wire signed [DATA_W+13-1:0] mult_7 = tap[7] * COEF_7;
    wire signed [DATA_W+12-1:0] mult_8 = tap[8] * COEF_8;
    wire signed [DATA_W+11-1:0] mult_9 = tap[9] * COEF_9;
    wire signed [DATA_W+9-1:0] mult_10 = tap[10] * COEF_10;
    wire signed [DATA_W+8-1:0] mult_11 = tap[11] * COEF_11;
    wire signed [DATA_W+6-1:0] mult_12 = tap[12] * COEF_12;
    wire signed [DATA_W+6-1:0] mult_13 = tap[13] * COEF_13;
    wire signed [DATA_W+6-1:0] mult_14 = tap[14] * COEF_14;

    // ---------------- align frac (shift ซ้ายตาม SHIFT_x) ก่อนบวกรวม ----------------
    wire signed [ACC_W-1:0] mult_aligned_0 = mult_0 <<< SHIFT_0;
    wire signed [ACC_W-1:0] mult_aligned_1 = mult_1 <<< SHIFT_1;
    wire signed [ACC_W-1:0] mult_aligned_2 = mult_2 <<< SHIFT_2;
    wire signed [ACC_W-1:0] mult_aligned_3 = mult_3 <<< SHIFT_3;
    wire signed [ACC_W-1:0] mult_aligned_4 = mult_4 <<< SHIFT_4;
    wire signed [ACC_W-1:0] mult_aligned_5 = mult_5 <<< SHIFT_5;
    wire signed [ACC_W-1:0] mult_aligned_6 = mult_6 <<< SHIFT_6;
    wire signed [ACC_W-1:0] mult_aligned_7 = mult_7 <<< SHIFT_7;
    wire signed [ACC_W-1:0] mult_aligned_8 = mult_8 <<< SHIFT_8;
    wire signed [ACC_W-1:0] mult_aligned_9 = mult_9 <<< SHIFT_9;
    wire signed [ACC_W-1:0] mult_aligned_10 = mult_10 <<< SHIFT_10;
    wire signed [ACC_W-1:0] mult_aligned_11 = mult_11 <<< SHIFT_11;
    wire signed [ACC_W-1:0] mult_aligned_12 = mult_12 <<< SHIFT_12;
    wire signed [ACC_W-1:0] mult_aligned_13 = mult_13 <<< SHIFT_13;
    wire signed [ACC_W-1:0] mult_aligned_14 = mult_14 <<< SHIFT_14;

    // ---------------- adder chain (sum ทุก tap ที่ align แล้ว) ----------------
    reg signed [ACC_W-1:0] acc;
    always @(*) begin
        acc = mult_aligned_0 + mult_aligned_1 + mult_aligned_2 + mult_aligned_3 + mult_aligned_4 + mult_aligned_5 + mult_aligned_6 + mult_aligned_7 + mult_aligned_8 + mult_aligned_9 + mult_aligned_10 + mult_aligned_11 + mult_aligned_12 + mult_aligned_13 + mult_aligned_14;
    end

    // ---------------- output register ----------------
    // หมายเหตุ: ผลรวม acc มี frac = FRAC_MAX (+ frac ของ data_in ถ้ามี)
    //           ปรับตำแหน่ง shift ตรงนี้ให้ตรงกับ Q-format ที่ต้องการของ data_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {DATA_W{1'b0}};
            out_valid <= 1'b0;
        end else begin
            data_out  <= acc[DATA_W+FRAC_MAX-1 -: DATA_W]; // *** ปรับ shift ตรงนี้ตาม Q-format จริง ***
            out_valid <= in_valid;
        end
    end

endmodule
