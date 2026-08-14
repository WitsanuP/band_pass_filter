// =====================================================================
// tb_lpf_hpf_top.v
// Testbench สำหรับ lpf_hpf_top (LPF 17 taps -> HPF 15 taps)
//
// ทดสอบ 2 แบบ:
//   1) Impulse response  : ป้อน 1 sample แล้วปล่อยศูนย์ ดู response ที่ไหลออกมา
//   2) Step response      : ป้อนค่าคงที่ต่อเนื่อง ดูว่า settle เป็นค่าเท่าไร
//
// ผลลัพธ์จะ:
//   - print ออกทาง console ($display)
//   - dump เป็น waveform (.vcd) ดูด้วย GTKWave ได้
//   - เขียนเป็นไฟล์ .csv (time, phase, sample_index, data_in, data_out)
//     เอาไป plot ต่อใน Python/MATLAB/Excel ได้
// =====================================================================
`timescale 1ns/1ps

module tb_lpf_hpf_top;

    // ---------------- parameter ของ testbench ----------------
    localparam integer DATA_W    = 16;
    localparam integer CLK_PERIOD = 10;      // ns
    localparam integer N_IMPULSE_SAMPLES = 60;
    localparam integer N_STEP_SAMPLES    = 80;
    localparam signed [DATA_W-1:0] IMPULSE_AMPLITUDE = 16'sd10000;
    localparam signed [DATA_W-1:0] STEP_AMPLITUDE    = 16'sd5000;

    // ---------------- DUT signals ----------------
    reg                      clk;
    reg                      rst_n;
    reg                      in_valid;
    reg  signed [DATA_W-1:0] data_in;
    wire                     out_valid;
    wire signed [DATA_W-1:0] data_out;

    integer                  fd;          // file handle สำหรับ csv
    integer                  sample_idx;
    integer                  k;

    // ---------------- instantiate DUT ----------------
    lpf_hpf_top #(
        .DATA_W (DATA_W)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (in_valid),
        .data_in   (data_in),
        .out_valid (out_valid),
        .data_out  (data_out)
    );

    // ---------------- clock generation ----------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------- monitor: print + log ทุกครั้งที่ out_valid ----------------
    always @(posedge clk) begin
        if (out_valid) begin
            $display("[t=%0t] sample=%0d  data_out=%0d", $time, sample_idx, data_out);
            if (fd) $fwrite(fd, "%0t,%0d,%0d\n", $time, sample_idx, data_out);
            sample_idx = sample_idx + 1;
        end
    end

    // ---------------- task: ป้อน 1 sample เข้า DUT ----------------
    task send_sample(input signed [DATA_W-1:0] val);
        begin
            @(negedge clk);
            in_valid = 1'b1;
            data_in  = val;
        end
    endtask

    task hold_idle(input integer n_cycles);
        integer j;
        begin
            for (j = 0; j < n_cycles; j = j + 1) begin
                @(negedge clk);
                in_valid = 1'b0;
                data_in  = {DATA_W{1'b0}};
            end
        end
    endtask

    // ---------------- main stimulus ----------------
    initial begin
        // เปิดไฟล์ VCD สำหรับดู waveform
        $dumpfile("tb_lpf_hpf_top.vcd");
        $dumpvars(0, tb_lpf_hpf_top);

        // เปิดไฟล์ CSV สำหรับเก็บผลลัพธ์
        fd = $fopen("lpf_hpf_output.csv", "w");
        $fwrite(fd, "time_ns,sample_index,data_out\n");

        // ---------------- reset ----------------
        rst_n      = 1'b0;
        in_valid   = 1'b0;
        data_in    = {DATA_W{1'b0}};
        sample_idx = 0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        // =========================================================
        // TEST 1: Impulse response
        // =========================================================
        $display("\n===== TEST 1: Impulse Response =====");
        send_sample(IMPULSE_AMPLITUDE);   // ส่ง impulse 1 sample
        hold_idle(N_IMPULSE_SAMPLES);     // ปล่อยศูนย์ต่อไปเรื่อย ๆ ให้ response ไหลออกจนหมด
        in_valid = 1'b0;

        // เว้นช่วงพักก่อนเทสต์ถัดไป
        repeat (5) @(negedge clk);

        // =========================================================
        // TEST 2: Step response
        // =========================================================
        $display("\n===== TEST 2: Step Response =====");
        for (k = 0; k < N_STEP_SAMPLES; k = k + 1) begin
            send_sample(STEP_AMPLITUDE);  // ป้อนค่าคงที่ต่อเนื่องทุก cycle
        end
        in_valid = 1'b0;
        hold_idle(20);                    // ปล่อย pipeline ไหลจนหมด (flush)

        $display("\n===== Testbench เสร็จสิ้น =====");
        $fclose(fd);
        $finish;
    end

    // ---------------- timeout guard กันจำลองค้าง ----------------
    initial begin
        #200000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
