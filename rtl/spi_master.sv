module spi_master #(
    parameter DIVIDER = 32
)

(
    input logic clk,
    input logic rst,
    input logic start,
    input logic miso,
    input logic [7:0] data_to_send,
    input logic [1:0] mode,
    output logic mosi,
    output logic sclk,
    output logic cs_n,
    output logic done,
    output logic [7:0] data_received
);

typedef enum logic [1:0] {
    MODE0 = 2'b00,
    MODE1 = 2'b01,
    MODE2 = 2'b10,
    MODE3 = 2'b11
} spi_mode_t;

spi_mode_t spi_mode;

typedef enum logic [1:0] {
    IDLE,
    LOAD,
    TRANSFER,
    DONE
} spi_state_t;

spi_state_t state, next_state;

logic [7:0] shift_reg_in, shift_reg_out;

localparam divider_bits = $clog2(DIVIDER);
logic [divider_bits-1:0] clk_divider_count;
logic [2:0] bit_count;

logic sclk_delayed;
logic rising_edge, falling_edge;
logic sample_edge, shift_edge;

assign rising_edge = sclk & ~sclk_delayed;
assign falling_edge = ~sclk & sclk_delayed;
assign sample_edge = (spi_mode == MODE0 || spi_mode == MODE3) ? rising_edge : falling_edge;
assign shift_edge = (spi_mode == MODE0 || spi_mode == MODE3) ? falling_edge : rising_edge;

assign done = (state == DONE);
assign data_received = shift_reg_in;
assign mosi = shift_reg_out[7];
assign cs_n = (state == IDLE || state == DONE) ? 1'b1 : 1'b0;


//always_comb for next state logic
always_comb begin
    next_state = state;
    
    case (state)
        IDLE: begin
            if (start) begin
                next_state = LOAD;
            end
        end

        LOAD: begin
            next_state = TRANSFER;
        end

        TRANSFER: begin
            if ((mode[0] == 0 && bit_count == 0 && sample_edge) ||
                (mode[0] == 1 && bit_count == 0 && shift_edge)) begin
                next_state = DONE;
            end
        end

        DONE: begin
            if (cs_n) begin
                next_state = IDLE; // go back to IDLE when CS is high
            end
        end

        default: next_state = IDLE; // default case to handle unexpected states
    endcase
end

//always_ff for state transition logic
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

//always_ff for clock divider logic
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        clk_divider_count <= DIVIDER - 1; // reset divider count
        sclk <= mode[1]; // set initial SCLK based on mode
        sclk_delayed <= mode[1];
    end else begin
        if (clk_divider_count == 0) begin
            sclk <= ~sclk; // toggle SCLK
            clk_divider_count <= DIVIDER - 1; // reset divider count
        end else begin
            clk_divider_count <= clk_divider_count - 1; // decrement divider count
        end
        sclk_delayed <= sclk; // update delayed SCLK
    end
end

//always_ff for data logic
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_reg_in <= 8'b0;
        shift_reg_out <= 8'b0;
        bit_count <= 3'd7; // counts down from 7 to 0 for 8 bits
    end 
    
    else begin
        case (state)
            IDLE: begin

            end

            LOAD: begin
                shift_reg_out <= data_to_send;
                bit_count <= 3'd7; // reset bit count for 8 bits
                spi_mode <= spi_mode_t'(mode); // set current mode
            end

            TRANSFER: begin
                        if (sample_edge)
                            shift_reg_in <= {shift_reg_in[6:0], miso}; // shift in MISO bit

                        if (shift_edge) 
                            shift_reg_out <= {shift_reg_out[6:0], 1'b0}; // shift out MISO bit

                        if ((mode[0] == 0 && sample_edge) ||
                            (mode[0] == 1 && shift_edge))
                            bit_count <= bit_count - 1;
            end

            DONE: begin

            end

            default: begin
                // Handle unexpected states
            end
        endcase
    end
end

endmodule