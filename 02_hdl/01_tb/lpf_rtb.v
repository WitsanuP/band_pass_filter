`timescale 1ns / 1ps

module tb_lpf_hpf_top();

    // =========================================================================
    // Parameters
    // =========================================================================
    //parameter integer DATA_W   = 10;
    //parameter integer FRAC_MAX = 12;
    //parameter integer ACC_W    = 16;
    
    // ????? Scale Factor ?????????? float ???? integer (Fixed-point)
    localparam real SCALE_FACTOR = 128.0; // ??????????????????? 2^8

    // =========================================================================
    // Signals
    // =========================================================================
    logic                     clk;
    logic                     rst_n;
    logic signed [9-1:0] data_in;
    logic signed [12-1:0]  data_out;

    // ?????????????????????? Input
    int  fd;
    int  scan_status;
    real data_real;

    // ?????????????????????? Output (?????????)
    int  fd_out;

    // =========================================================================
    // Device Under Test (DUT)
    // =========================================================================
    lpf_rtl uut (
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
        $fsdbDumpvars(0, tb_lpf_hpf_top);
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

endmodule
