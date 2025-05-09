module fir #(
    parameter DATA_WIDTH = 32,
    parameter NUM_TAPS = 11,
    parameter ADDR_WIDTH = 12
) (
    input wire clk,
    input wire rst_n,
    input wire valid_i,                    // Valid input sample
    input wire [DATA_WIDTH-1:0] data_i,    // Input sample
    output reg [DATA_WIDTH-1:0] data_o,    // Output sample
    output reg ready_o,                    // Output ready
    // Coefficient BRAM interface
    output wire [3:0] coef_we,
    output wire coef_en,
    output wire [ADDR_WIDTH-1:0] coef_addr,
    input wire [DATA_WIDTH-1:0] coef_data,
    // Sample BRAM interface
    output wire [3:0] sample_we,
    output wire sample_en,
    output wire [ADDR_WIDTH-1:0] sample_addr,
    output wire [DATA_WIDTH-1:0] sample_data_i,
    input wire [DATA_WIDTH-1:0] sample_data_o
);
    // State machine states
    localparam IDLE = 2'd0,
               LOAD = 2'd1,
               COMPUTE = 2'd2,
               OUTPUT = 2'd3;

    reg [1:0] state, next_state;
    reg [ADDR_WIDTH-1:0] tap_idx;
    reg [DATA_WIDTH-1:0] acc; // Accumulator for MAC
    reg [ADDR_WIDTH-1:0] sample_idx; // Current sample index
    reg [ADDR_WIDTH-1:0] output_idx; // Output array index
    reg [DATA_WIDTH-1:0] output_buffer [0:NUM_TAPS-1]; // Store 11 outputs

    // Memory control signals
    assign coef_we = 4'b0000; // Coefficients pre-loaded via Wishbone
    assign coef_en = (state == COMPUTE);
    assign coef_addr = tap_idx;
    assign sample_we = (state == LOAD) ? 4'b1111 : 4'b0000; // Full 32-bit write
    assign sample_en = (state == LOAD || state == COMPUTE);
    assign sample_addr = (state == LOAD) ? sample_idx : (sample_idx - tap_idx - 1);
    assign sample_data_i = data_i;

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (valid_i)
                    next_state = LOAD;
            end
            LOAD: begin
                next_state = COMPUTE;
            end
            COMPUTE: begin
                if (tap_idx == NUM_TAPS - 1)
                    next_state = OUTPUT;
            end
            OUTPUT: begin
                if (output_idx == NUM_TAPS - 1)
                    next_state = IDLE;
                else
                    next_state = LOAD;
            end
        endcase
    end

    // Control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tap_idx <= 0;
            acc <= 0;
            sample_idx <= 0;
            output_idx <= 0;
            data_o <= 0;
            ready_o <= 0;
            for (integer i = 0; i < NUM_TAPS; i = i + 1)
                output_buffer[i] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tap_idx <= 0;
                    acc <= 0;
                    ready_o <= 0;
                end
                LOAD: begin
                    sample_idx <= sample_idx + 1;
                end
                COMPUTE: begin
                    // MAC: acc += coef * sample
                    acc <= acc + ($signed(coef_data) * $signed(sample_data_o));
                    tap_idx <= tap_idx + 1;
                end
                OUTPUT: begin
                    output_buffer[output_idx] <= acc;
                    data_o <= output_buffer[output_idx];
                    ready_o <= 1;
                    output_idx <= output_idx + 1;
                    sample_idx <= sample_idx - (NUM_TAPS - 1); // Reset for next sample
                    tap_idx <= 0;
                    acc <= 0;
                end
            endcase
        end
    end
endmodule