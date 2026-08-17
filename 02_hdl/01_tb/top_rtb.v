`timescale 1ns / 1ps

module top_rtb();

    // =========================================================================
    // Parameters
    // =========================================================================
    parameter integer DATA_W   = 10;
    parameter integer FRAC_MAX = 12;
    parameter integer ACC_W    = 16;
    
    // ????? Scale Factor ?????????? float ???? integer (Fixed-point)
    localparam real SCALE_FACTOR = 256.0; // ??????????????????? 2^8

    // =========================================================================
    // Signals
    // =========================================================================
    logic                     clk;
    logic                     rst_n;
    logic signed [DATA_W-1:0] data_in;
    logic signed [ACC_W-1:0]  data_out;

    // ?????????????????????? Input
    int  fd;
    int  scan_status;
    real data_real;

    // ?????????????????????? Output (?????????)
    int  fd_out;

    // =========================================================================
    // Device Under Test (DUT)
    // =========================================================================
    //fir_lpf17 #(
    //    .DATA_W(DATA_W),
    //    .FRAC_MAX(FRAC_MAX),
    //    .ACC_W(ACC_W)
    //) uut (
    //    .clk(clk),
    //    .rst_n(rst_n),
    //    .data_in(data_in),
    //    .data_out(data_out)
    //);
    lpf_hpf_top uut(
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );
    // =========================================================================
    // Clock Generation
    // =========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Clock period = 10ns (100MHz)
    end

    // =========================================================================
    // Reset Generation
    // =========================================================================
    initial begin
        rst_n = 0;
        data_in = '0;
        #20;
        rst_n = 1;
    end

    // =========================================================================
    // Dump Waveform
    // =========================================================================
    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, top_rtb);
    end

    // =========================================================================
    // Open Output File & Write Output Data (????????????????)
    // =========================================================================
    initial begin
        fd_out = $fopen("output_rtl.txt", "w");
        if (fd_out == 0) begin
            $display("ERROR: Could not open output_rtl.txt for writing");
            $finish;
        end
    end

    // ????????? data_out ?????????? ???????????? Clock ?????????? Reset
    always @(posedge clk) begin
        if (rst_n) begin
            $fdisplay(fd_out, "%d", data_out);
        end
    end

    // =========================================================================
    // Read Input Data & Feed to DUT
    // =========================================================================
    initial begin
        // ????????????????? Reset
        @(posedge rst_n);
        @(posedge clk);

        // ??????????????????
        fd = $fopen("input_data.txt", "r");
        if (fd == 0) begin
            $display("ERROR: Could not open input_data.txt");
            $finish;
        end

        $display("START: Reading data from input_data.txt ...");

        // ????????????? ?????????????? (EOF)
        while (!$feof(fd)) begin
            scan_status = $fscanf(fd, "%e", data_real);
            
            if (scan_status == 1) begin
                // ???? float ???? integer (Fixed-point)
                data_in = $floor(data_real * SCALE_FACTOR);
                
                // ?? 1 Clock cycle ??????????????????? DUT
                @(posedge clk);
            end
        end

        // ??????? Input
        $fclose(fd);
        $display("FINISH: All input data processed.");
        
        // ???????????????????????? Pipeline ??? Filter ?????
        #200; 

        // ??????? Output ??????????????
        $fclose(fd_out);
        $display("FINISH: Output data successfully written to output_rtl.txt.");
        
        $finish;
    end
    // =========================================================================
    // check output
    // =========================================================================
    integer int_ref_output;
    integer diff_data;
    integer fo;
    integer int_scan_status; // 1. ???????????????????? scan_status
    integer error_count=0;

    initial begin
        @(posedge rst_n);
        repeat(3)@(posedge clk);
        //@(posedge clk);

        fo = $fopen("ref_output.txt", "r");
        if (fo == 0) begin
            $display("ERROR: Could not open ref_output.txt");
            $finish;
        end

        $display("START: Reading data from ref_output.txt ...");

        while (!$feof(fo)) begin
            int_scan_status = $fscanf(fo, "%d\n", int_ref_output);

            if (int_scan_status == 1) begin
                @(posedge clk); // ????? Clock ????????
                #1;             // ???????????????????? data_out ????
                
                diff_data = int_ref_output - $signed(data_out);

                if (diff_data == 0) begin
                    //$display("[PASS] Expected: %0d, Actual: %0d", int_ref_output, data_out);
                end else begin
                    $display("[FAIL] Expected: %0d, Actual: %0d (Diff: %0d)", int_ref_output, data_out, diff_data);
                    error_count++;
                end
            end
        end

        $fclose(fo);
        $display("FINISH: All read ref_data processed.\n");
        $display("Error count : %d ", error_count);

        #200;
        $finish;
    end

endmodule
