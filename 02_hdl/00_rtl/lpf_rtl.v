// ===================================================================
// fir_lpf17.v
// Direct-Form FIR, 17 taps
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
module lpf_rtl #(
    parameter integer DATA_W   = 10,
    parameter integer FRAC_MAX = 12,   // จำนวนบิตเศษส่วนมากสุดในบรรดา tap ทั้งหมด
    parameter integer ACC_W    = 16
)(
    input  wire                       clk,
    input  wire                       rst_n,
    //input  wire                       in_valid,
    input  wire signed [DATA_W-1:0]   data_in,

    //output reg                        out_valid,
    output reg  signed [ACC_W-1:0]   data_out
);

    // ---------------- coefficient แต่ละ tap: <sign, int, frac> ตัวอย่าง ----------------
    // tap0:  <sign=1, int=0, frac=6>  dec = -0.0131571
    localparam signed [6:0] COEF_0=7'sb1111111;
    // tap1:  <sign=1, int=0, frac=5>  dec = 0.0315729
    localparam signed [5:0] COEF_1=6'sb000001;
    // tap2:  <sign=1, int=0, frac=5>  dec = -0.0250929
    localparam signed [5:0] COEF_2=6'sb111111;
    // tap3:  <sign=1, int=0, frac=7>  dec = -0.0192813
    localparam signed [7:0] COEF_3=8'sb11111101;
    // tap4:  <sign=1, int=0, frac=4>  dec = 0.0667674
    localparam signed [4:0] COEF_4=5'sb00001;
    // tap5:  <sign=1, int=0, frac=7>  dec = -0.0349004
    localparam signed [7:0] COEF_5=8'sb11111011;
    // tap6:  <sign=1, int=0, frac=6>  dec = -0.108171
    localparam signed [6:0] COEF_6=7'sb1111001;
    // tap7:  <sign=1, int=0, frac=7>  dec = 0.290597
    localparam signed [7:0] COEF_7=8'sb00100101;
    // tap8:  <sign=1, int=0, frac=3>  dec = 0.626626
    localparam signed [3:0] COEF_8=4'sb0101;
    // tap9:  <sign=1, int=0, frac=7>  dec = 0.290597
    localparam signed [7:0] COEF_9=8'sb00100101;
    // tap10:  <sign=1, int=0, frac=6>  dec = -0.108171
    localparam signed [6:0] COEF_10=7'sb1111001;
    // tap11:  <sign=1, int=0, frac=7>  dec = -0.0349004
    localparam signed [7:0] COEF_11=8'sb11111011;
    // tap12:  <sign=1, int=0, frac=4>  dec = 0.0667674
    localparam signed [4:0] COEF_12=5'sb00001;
    // tap13:  <sign=1, int=0, frac=7>  dec = -0.0192813
    localparam signed [7:0] COEF_13=8'sb11111101;
    // tap14:  <sign=1, int=0, frac=5>  dec = -0.0250929
    localparam signed [5:0] COEF_14=6'sb111111;
    // tap15:  <sign=1, int=0, frac=5>  dec = 0.0315729
    localparam signed [5:0] COEF_15=6'sb000001;
    // tap16:  <sign=1, int=0, frac=6>  dec = -0.0131571
    localparam signed [6:0] COEF_16=7'sb1111111;

    // ---------------- shift amount ต่อ tap เพื่อ align frac ให้ตรงกับ FRAC_MAX ----------------
    localparam integer SHIFT_0 = 8;
    localparam integer SHIFT_1 = 7;
    localparam integer SHIFT_2 = 6;
    localparam integer SHIFT_3 = 5;
    localparam integer SHIFT_4 = 4;
    localparam integer SHIFT_5 = 3;
    localparam integer SHIFT_6 = 2;
    localparam integer SHIFT_7 = 1;
    localparam integer SHIFT_8 = 0;
    localparam integer SHIFT_9 = 1;
    localparam integer SHIFT_10 = 2;
    localparam integer SHIFT_11 = 3;
    localparam integer SHIFT_12 = 4;
    localparam integer SHIFT_13 = 5;
    localparam integer SHIFT_14 = 6;
    localparam integer SHIFT_15 = 7;
    localparam integer SHIFT_16 = 8;

    // ---------------- tapped delay line (D -> D -> ... -> D) ----------------
    reg signed [DATA_W-1:0] tap [0:16];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 17; i = i + 1)
                tap[i] <= {DATA_W{1'b0}};
        end else begin
            tap[0] <= data_in;
            for (i = 1; i < 17; i = i + 1)
                tap[i] <= tap[i-1];
        end
    end

    // ---------------- multiply (แต่ละ tap x coefficient เฉพาะของตัวเอง) ----------------
    wire signed [DATA_W+7-1:0] mult_0 = tap[0] * COEF_0;
    wire signed [DATA_W+6-1:0] mult_1 = tap[1] * COEF_1;
    wire signed [DATA_W+6-1:0] mult_2 = tap[2] * COEF_2;
    wire signed [DATA_W+8-1:0] mult_3 = tap[3] * COEF_3;
    wire signed [DATA_W+5-1:0] mult_4 = tap[4] * COEF_4;

    wire signed [DATA_W+8-1:0] mult_5 = tap[5] * COEF_5;
    wire signed [DATA_W+7-1:0] mult_6 = tap[6] * COEF_6;
    wire signed [DATA_W+8-1:0] mult_7 = tap[7] * COEF_7;
    wire signed [DATA_W+4-1:0] mult_8 = tap[8] * COEF_8;
    wire signed [DATA_W+8-1:0] mult_9 = tap[9] * COEF_9;

    wire signed [DATA_W+7-1:0] mult_10 = tap[10] * COEF_10;
    wire signed [DATA_W+8-1:0] mult_11 = tap[11] * COEF_11;
    wire signed [DATA_W+5-1:0] mult_12 = tap[12] * COEF_12;
    wire signed [DATA_W+8-1:0] mult_13 = tap[13] * COEF_13;
    wire signed [DATA_W+6-1:0] mult_14 = tap[14] * COEF_14;

    wire signed [DATA_W+6-1:0] mult_15 = tap[15] * COEF_15;
    wire signed [DATA_W+7-1:0] mult_16 = tap[16] * COEF_16;

    // ---------------- align frac (shift ซ้ายตาม SHIFT_x) ก่อนบวกรวม ----------------
    wire signed [ACC_W-1:0] mult_aligned_0 = mult_0[DATA_W+7-1:1];
    wire signed [ACC_W-1:0] mult_aligned_1 = mult_1[DATA_W+6-1:0];
    wire signed [ACC_W-1:0] mult_aligned_2 = mult_2[DATA_W+6-1:0];
    wire signed [ACC_W-1:0] mult_aligned_3 = mult_3[DATA_W+8-1:2];
    wire signed [ACC_W-1:0] mult_aligned_4 = mult_4 <<< 1 ;
                                                                 
    wire signed [ACC_W-1:0] mult_aligned_5 = mult_5[DATA_W+8-1:2];
    wire signed [ACC_W-1:0] mult_aligned_6 = mult_6[DATA_W+7-1:1];
    wire signed [ACC_W-1:0] mult_aligned_7 = mult_7[DATA_W+8-1:2];
    wire signed [ACC_W-1:0] mult_aligned_8 = mult_8 <<< 2 ;
    wire signed [ACC_W-1:0] mult_aligned_9 = mult_9[DATA_W+8-1:2];

    wire signed [ACC_W-1:0] mult_aligned_10 = mult_10[DATA_W+7-1:1];
    wire signed [ACC_W-1:0] mult_aligned_11 = mult_11[DATA_W+8-1:2];
    wire signed [ACC_W-1:0] mult_aligned_12 = mult_12 << 1 ;
    wire signed [ACC_W-1:0] mult_aligned_13 = mult_13[DATA_W+8-1:2];
    wire signed [ACC_W-1:0] mult_aligned_14 = mult_14[DATA_W+6-1:0];
                                                                   
    wire signed [ACC_W-1:0] mult_aligned_15 = mult_15[DATA_W+6-1:0];
    wire signed [ACC_W-1:0] mult_aligned_16 = mult_16[DATA_W+7-1:1];

    // ---------------- adder chain (sum ทุก tap ที่ align แล้ว) ----------------
    reg signed [ACC_W-1:0] acc;
    always @(*) begin
        acc = mult_aligned_0 + mult_aligned_1 + mult_aligned_2 + mult_aligned_3 + mult_aligned_4 + mult_aligned_5 + mult_aligned_6 + mult_aligned_7 + mult_aligned_8 + mult_aligned_9 + mult_aligned_10 + mult_aligned_11 + mult_aligned_12 + mult_aligned_13 + mult_aligned_14 + mult_aligned_15 + mult_aligned_16;
    end

    // ---------------- output register ----------------
    // หมายเหตุ: ผลรวม acc มี frac = FRAC_MAX (+ frac ของ data_in ถ้ามี)
    //           ปรับตำแหน่ง shift ตรงนี้ให้ตรงกับ Q-format ที่ต้องการของ data_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {DATA_W{1'b0}};
        end else begin
            data_out  <= acc; // *** ปรับ shift ตรงนี้ตาม Q-format จริง ***
        end
    end

endmodule
