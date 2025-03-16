module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11,
        // AXI parameters for states
    parameter AXILITE_FSM_RESET    = 3'b000,
    parameter AXILITE_FSM_IDLE     = 3'b001,
    parameter AXILITE_FSM_AWREADY  = 3'b010,
    parameter AXILITE_FSM_WREADY   = 3'b011,
    parameter AXILITE_FSM_ARREADY  = 3'b100,
    parameter AXILITE_FSM_RREADY   = 3'b101,
    
    //AXI stream FSM parameters
    parameter AXISTREAM_FSM_RESET  = 3'b000,
    parameter AXISTREAM_FSM_IDLE   = 3'b001,
    parameter AXISTREAM_FSM_INIT   = 3'b010,
    parameter AXISTREAM_FSM_UPDATE = 3'b011,
    parameter AXISTREAM_FSM_MULT   = 3'b100,
    parameter AXISTREAM_FSM_SUM    = 3'b101,
    parameter AXISTREAM_FSM_OUT    = 3'b110
)
(
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
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);


    // write your code here!
    // WE based on data width
    wire [3:0]                       WE_sel;
        // AP Config
    wire                             AP_WE;
    wire                             AP_EN;
    wire [2:0]                       AP_Di;
    wire [(pDATA_WIDTH-1):0]         AP_Do;
    reg  [2:0]                       AP_reg;//ap register for later configurations
// Length Configuration Register
    wire [3:0]                       len_WE;
    wire                             len_EN;
    wire [(pDATA_WIDTH-1):0]         len_Di;
    wire [(pDATA_WIDTH-1):0]         len_Do;
    reg  [(pDATA_WIDTH-1):0]         len_reg;
 // Tap Number Configuration Register
    wire [3:0]                       tapnum_WE;
    wire                             tapnum_EN;
    wire [(pDATA_WIDTH-1):0]         tapnum_Di;
    wire [(pDATA_WIDTH-1):0]         tapnum_Do;
    reg  [(pDATA_WIDTH-1):0]         tapnum_reg;

//axilite stuff
    reg  [2:0]                       axilite_fsm;
    reg  [(pADDR_WIDTH-1):0]         axilite_A_pre;
    reg  [(pDATA_WIDTH-1):0]         axilite_Di_pre;
    reg                              axilite_rr;
    wire                             axilite_active;
    wire                             axilite_ap;
    wire                             axilite_len;
    wire                             axilite_num;
    wire                             axilite_tap;
    wire [(pDATA_WIDTH-1):0]         axilite_Do;
    wire [(pADDR_WIDTH-1):0]         axilite_A;
    wire [(pDATA_WIDTH-1):0]         axilite_Di;

    reg  [2:0]                       axistream_fsm;
    reg  [(pADDR_WIDTH-1):0]         axistream_A;
    reg  [(pDATA_WIDTH-1):0]         axistream_data_Di;
    reg  [(pDATA_WIDTH-1):0]         axistream_data_Do;
    reg  [(pDATA_WIDTH-1):0]         axistream_mul;
    reg  [(pDATA_WIDTH-1):0]         axistream_sum;
    reg                              axistream_sent;
    reg                              axistream_lastreg;
    wire                             axistream_active;
    wire                             axistream_ap;
    wire                             axistream_tap;
    wire [(pADDR_WIDTH-1):0]         axistream_tap_A;
    
    
    


endmodule
