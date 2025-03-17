`timescale 1ns / 1ps

module fir_tb
#(
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11,
    parameter Data_Num    = 600
)();

    // AXI-Lite Interface
    wire                        awready;
    wire                        wready;
    reg                         awvalid;
    reg   [(pADDR_WIDTH-1): 0]  awaddr;
    reg                         wvalid;
    reg signed [(pDATA_WIDTH-1) : 0] wdata;
    wire                        arready;
    reg                         rready;
    reg                         arvalid;
    reg         [(pADDR_WIDTH-1): 0] araddr;
    wire                        rvalid;
    wire signed [(pDATA_WIDTH-1): 0] rdata;

    // AXI-Stream Interface (Slave)
    reg                         ss_tvalid;
    reg signed [(pDATA_WIDTH-1) : 0] ss_tdata;
    reg                         ss_tlast;
    wire                        ss_tready;

    // AXI-Stream Interface (Master)
    reg                         sm_tready;
    wire                        sm_tvalid;
    wire signed [(pDATA_WIDTH-1) : 0] sm_tdata;
    wire                        sm_tlast;

    // Clock and Reset
    reg                         axis_clk;
    reg                         axis_rst_n;

    // BRAM Interface for Tap RAM
    wire [3:0]               tap_WE;
    wire                     tap_EN;
    wire [(pDATA_WIDTH-1):0] tap_Di;
    wire [(pADDR_WIDTH-1):0] tap_A;
    wire [(pDATA_WIDTH-1):0] tap_Do;

    // BRAM Interface for Data RAM
    wire [3:0]               data_WE;
    wire                     data_EN;
    wire [(pDATA_WIDTH-1):0] data_Di;
    wire [(pADDR_WIDTH-1):0] data_A;
    wire [(pDATA_WIDTH-1):0] data_Do;

    // FIR DUT Instantiation
    fir fir_DUT(
        .awready(awready),
        .wready(wready),
        .awvalid(awvalid),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wdata(wdata),
        .arready(arready),
        .rready(rready),
        .arvalid(arvalid),
        .araddr(araddr),
        .rvalid(rvalid),
        .rdata(rdata),
        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tlast(ss_tlast),
        .ss_tready(ss_tready),
        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata),
        .sm_tlast(sm_tlast),
        .tap_WE(tap_WE),
        .tap_EN(tap_EN),
        .tap_Di(tap_Di),
        .tap_A(tap_A),
        .tap_Do(tap_Do),
        .data_WE(data_WE),
        .data_EN(data_EN),
        .data_Di(data_Di),
        .data_A(data_A),
        .data_Do(data_Do),
        .axis_clk(axis_clk),
        .axis_rst_n(axis_rst_n)
    );

    // BRAM Instantiation for Tap RAM
    bram11 tap_RAM (
        .CLK(axis_clk),
        .WE(tap_WE),
        .EN(tap_EN),
        .Di(tap_Di),
        .A(tap_A),
        .Do(tap_Do)
    );

    // BRAM Instantiation for Data RAM
    bram11 data_RAM(
        .CLK(axis_clk),
        .WE(data_WE),
        .EN(data_EN),
        .Di(data_Di),
        .A(data_A),
        .Do(data_Do)
    );

    // Testbench Variables
    reg signed [(pDATA_WIDTH-1):0] Din_list[0:(Data_Num-1)]; // Input data
    reg signed [(pDATA_WIDTH-1):0] golden_list[0:(Data_Num-1)]; // Golden output data
    reg [31:0] data_length; // Data length
    integer Din, golden, input_data, golden_data, m;
    integer i, k;
    reg error;

    // Clock Generation
    initial begin
        axis_clk = 0;
        forever #5 axis_clk = ~axis_clk;
    end

    // Reset Generation
    initial begin
        axis_rst_n = 0;
        repeat(2) @(posedge axis_clk);
        axis_rst_n = 1;
    end

    // Load Input and Golden Data
    initial begin
        data_length = 0;
        Din = $fopen("./samples_triangular_wave.dat", "r");
        golden = $fopen("./out_gold.dat", "r");
        for (m = 0; m < Data_Num; m = m + 1) begin
            input_data = $fscanf(Din, "%d", Din_list[m]);
            golden_data = $fscanf(golden, "%d", golden_list[m]);
            data_length = data_length + 1;
        end
        $fclose(Din);
        $fclose(golden);
    end

    // FIR Configuration and Testing
    initial begin
        $display("------------Start Simulation-----------");
        error = 0;

        // Configure FIR Filter
        $display("----Start Coefficient Input (AXI-Lite)----");
        config_write(12'h10, data_length); // Write data length
        for (k = 0; k < Tape_Num; k = k + 1) begin
            config_write(12'h20 + 4*k, coef[k]); // Write tap coefficients
        end
        $display("----End Coefficient Input (AXI-Lite)----");

        // Start FIR Filter
        $display("Start FIR Filter");
        config_write(12'h00, 32'h0000_0001); // Set ap_start = 1

        // Stream Input Data
        $display("----Start Data Input (AXI-Stream)----");
        for (i = 0; i < data_length; i = i + 1) begin
            ss_tlast = (i == data_length - 1) ? 1 : 0; // Set tlast for the last sample
            ss(Din_list[i]); // Stream input data
        end
        $display("----End Data Input (AXI-Stream)----");

        // Check FIR Output
        $display("----Start Output Verification----");
        sm_tready = 1;
        for (k = 0; k < data_length; k = k + 1) begin
            sm(golden_list[k], k); // Compare output with golden data
        end
        $display("----End Output Verification----");

        // Simulation Result
        if (error == 0) begin
            $display("---------------------------------------------");
            $display("-----------Congratulations! Pass-------------");
        end else begin
            $display("--------Simulation Failed---------");
        end
        $finish;
    end

    // Tasks
    task config_write;
        input [11:0] addr;
        input [31:0] data;
        begin
            awvalid <= 0; wvalid <= 0;
            @(posedge axis_clk);
            awvalid <= 1; awaddr <= addr;
            wvalid  <= 1; wdata <= data;
            @(posedge axis_clk);
            while (!wready) @(posedge axis_clk);
        end
    endtask

    task ss;
        input signed [31:0] in1;
        begin
            ss_tvalid <= 1;
            ss_tdata  <= in1;
            @(posedge axis_clk);
            while (!ss_tready) @(posedge axis_clk);
        end
    endtask

    task sm;
        input signed [31:0] in2; // Golden data
        input [31:0] pcnt; // Pattern count
        begin
            sm_tready <= 1;
            @(posedge axis_clk);
            wait(sm_tvalid);
            while (!sm_tvalid) @(posedge axis_clk);
            if (sm_tdata != in2) begin
                $display("[ERROR] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
                error <= 1;
            end else begin
                $display("[PASS] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
            end
            @(posedge axis_clk);
        end
    endtask

    // FIR Coefficients
    reg signed [31:0] coef[0:10]; // FIR coefficients
    initial begin
        coef[0]  =  32'd0;
        coef[1]  = -32'd10;
        coef[2]  = -32'd9;
        coef[3]  =  32'd23;
        coef[4]  =  32'd56;
        coef[5]  =  32'd63;
        coef[6]  =  32'd56;
        coef[7]  =  32'd23;
        coef[8]  = -32'd9;
        coef[9]  = -32'd10;
        coef[10] =  32'd0;
    end

    // Timeout Prevention
    integer timeout = 1000000;
    initial begin
        while (timeout > 0) begin
            @(posedge axis_clk);
            timeout = timeout - 1;
        end
        $display($time, "Simulation Hang ....");
        $finish;
    end

endmodule
