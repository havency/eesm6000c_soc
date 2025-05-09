// SPDX-FileCopyrightText: 2020 Efabless Corporation
// Licensed under the Apache License, Version 2.0
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS = 10
)(
`ifdef USE_POWER_PINS
    inout vccd1,    // User area 1 1.8V supply
    inout vssd1,    // User area 1 digital ground
`endif
    // Wishbone Slave ports
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,
    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,
    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,
    // IRQ
    output [2:0] irq
);
    wire clk = wb_clk_i;
    wire rst = wb_rst_i;
    wire valid = wbs_cyc_i && wbs_stb_i;
    wire [3:0] wstrb = wbs_sel_i & {4{wbs_we_i}};
    wire [31:0] wdata = wbs_dat_i;

    // FIR filter signals
    wire [31:0] fir_data_o;
    wire fir_ready;
    wire [31:0] fir_data_i = la_data_in[31:0]; // Input samples from LA
    wire fir_valid = ~la_oenb[64] ? la_data_in[64] : valid; // Controlled by LA or WB
    wire [31:0] coef_data, sample_data_o;
    wire [3:0] coef_we, sample_we;
    wire coef_en, sample_en;
    wire [11:0] coef_addr, sample_addr;
    wire [31:0] sample_data_i;

    // Wishbone registers
    reg [31:0] coef_reg; // For loading coefficients
    reg [3:0] coef_load;
    reg [11:0] coef_addr_reg;
    reg [31:0] rdata;

    assign wbs_ack_o = fir_ready || (|coef_load);
    assign wbs_dat_o = rdata;

    // IO
    assign io_out = fir_data_o;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};
    assign irq = 3'b000; // Unused
    assign la_data_out = {{(127-BITS){1'b0}}, fir_data_o};

    // Wishbone control for coefficient loading
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            coef_reg <= 0;
            coef_load <= 0;
            coef_addr_reg <= 0;
            rdata <= 0;
        end else begin
            if (valid && wbs_we_i && wbs_adr_i[7:0] == 8'h00) begin
                coef_reg <= wdata;
                coef_load <= wstrb;
                coef_addr_reg <= wbs_adr_i[19:8]; // Coefficient index
            end else begin
                coef_load <= 0;
            end
            if (valid && !wbs_we_i) begin
                rdata <= fir_data_o; // Read FIR output
            end
        end
    end

    // Coefficient BRAM
    bram coef_bram (
        .CLK(clk),
        .WE0(coef_load),
        .EN0(coef_en),
        .Di0(coef_reg),
        .Do0(coef_data),
        .A0({20'b0, coef_addr_reg})
    );

    // Sample BRAM
    bram sample_bram (
        .CLK(clk),
        .WE0(sample_we),
        .EN0(sample_en),
        .Di0(sample_data_i),
        .Do0(sample_data_o),
        .A0({20'b0, sample_addr})
    );

    // FIR filter
    fir fir (
        .clk(clk),
        .rst_n(~rst),
        .valid_i(fir_valid),
        .data_i(fir_data_i),
        .data_o(fir_data_o),
        .ready_o(fir_ready),
        .coef_we(coef_we),
        .coef_en(coef_en),
        .coef_addr(coef_addr),
        .coef_data(coef_data),
        .sample_we(sample_we),
        .sample_en(sample_en),
        .sample_addr(sample_addr),
        .sample_data_i(sample_data_i),
        .sample_data_o(sample_data_o)
    );
endmodule

`default_nettype wire