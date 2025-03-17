module fir 
#(
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    // AXI-Lite Interface
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,    

    // AXI-Stream Interface (Slave)
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 

    // AXI-Stream Interface (Master)
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 

    // BRAM Interface for Tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // BRAM Interface for Data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    // Clock and Reset
    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);

    // Internal Registers and Signals
    reg [pDATA_WIDTH-1:0] tap_coeffs [0:Tape_Num-1]; // Tap coefficients
    reg [pDATA_WIDTH-1:0] data_length;               // Data length
    reg ap_start;                                    // Start signal
    reg ap_done;                                     // Done signal
    reg ap_idle;                                     // Idle signal

    reg [pADDR_WIDTH-1:0] tap_addr;                  // Tap RAM address
    reg [pADDR_WIDTH-1:0] data_addr;                 // Data RAM address
    reg [pDATA_WIDTH-1:0] accumulator;               // FIR accumulator
    reg [pDATA_WIDTH-1:0] input_buffer [0:Tape_Num-1]; // Input data buffer

    // FSM States
    typedef enum logic [2:0] {
        IDLE,
        LOAD_TAPS,
        PROCESS_DATA,
        DONE
    } state_t;

    state_t current_state, next_state;

    // AXI-Lite Interface Logic
    assign awready = (current_state == IDLE);
    assign wready  = (current_state == IDLE);
    assign arready = (current_state == IDLE);

    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            ap_start <= 0;
            data_length <= 0;
            tap_coeffs <= '{default: 0};
        end else if (awvalid && wvalid) begin
            case (awaddr)
                12'h000: ap_start <= wdata[0];
                12'h010: data_length <= wdata;
                12'h020: tap_coeffs[0] <= wdata;
                // Add more cases for other tap coefficients
            endcase
        end
    end

    // FSM Logic
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                if (ap_start) next_state = LOAD_TAPS;
                else next_state = IDLE;
            end
            LOAD_TAPS: begin
                if (tap_addr == Tape_Num-1) next_state = PROCESS_DATA;
                else next_state = LOAD_TAPS;
            end
            PROCESS_DATA: begin
                if (data_addr == data_length-1) next_state = DONE;
                else next_state = PROCESS_DATA;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Tap RAM Interface
    assign tap_EN = (current_state == LOAD_TAPS);
    assign tap_WE = (current_state == LOAD_TAPS) ? 4'b1111 : 4'b0000;
    assign tap_A  = tap_addr;
    assign tap_Di = tap_coeffs[tap_addr];

    // Data RAM Interface
    assign data_EN = (current_state == PROCESS_DATA);
    assign data_WE = 4'b0000; // Read-only for data RAM
    assign data_A  = data_addr;
    assign data_Di = 32'b0;

    // FIR Computation Logic
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (!axis_rst_n) begin
            accumulator <= 0;
            input_buffer <= '{default: 0};
        end else if (current_state == PROCESS_DATA) begin
            accumulator <= 0;
            for (int i = 0; i < Tape_Num; i = i + 1) begin
                accumulator <= accumulator + tap_coeffs[i] * input_buffer[i];
            end
            input_buffer <= {ss_tdata, input_buffer[0:Tape_Num-2]}; // Shift input buffer
        end
    end

    // AXI-Stream Logic
    assign ss_tready = (current_state == PROCESS_DATA);
    assign sm_tvalid = (current_state == DONE);
    assign sm_tdata  = accumulator;
    assign sm_tlast  = (current_state == DONE);

endmodule
