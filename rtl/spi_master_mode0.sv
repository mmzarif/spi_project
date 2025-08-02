module spi_master_mode0 (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [7:0]  data2send,
    input  logic        miso,

    output logic        done,
    output logic        sclk,
    output logic        mosi,
    output logic        cs,
    output logic [7:0]  data2receive
);

    // FSM States
    typedef enum logic [2:0] {
        IDLE, ASSERT_CS, LOAD_BIT, SCLK_LOW, SCLK_HIGH, NEXT_BIT, FINISH
    } state_t;

    state_t state, next_state;

    logic [7:0] shift_reg;
    logic [7:0] recv_reg;
    logic [2:0] bit_cnt;

    // Control Signals
    logic done_reg;
    logic sclk_reg;
    logic mosi_reg;
    logic cs_reg;

    assign done         = done_reg;
    assign sclk         = sclk_reg;
    assign mosi         = mosi_reg;
    assign cs           = cs_reg;
    assign data2receive = recv_reg;

    // FSM Sequential Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            shift_reg <= 8'b0;
            recv_reg  <= 8'b0;
            bit_cnt   <= 3'd7;
            sclk_reg  <= 1'b0;
            mosi_reg  <= 1'b0;
            cs_reg    <= 1'b1;  // inactive
            done_reg  <= 1'b0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    done_reg <= 1'b0;
                end

                ASSERT_CS: begin
                    cs_reg    <= 1'b0;         // pull CS low
                    shift_reg <= data2send;
                    bit_cnt   <= 3'd7;
                end

                LOAD_BIT: begin
                    mosi_reg <= shift_reg[7]; // MSB first
                end

                SCLK_LOW: begin
                    sclk_reg <= 1'b0;
                end

                SCLK_HIGH: begin
                    sclk_reg <= 1'b1;
                    recv_reg <= {recv_reg[6:0], miso}; // shift in MISO bit
                end

                NEXT_BIT: begin
                    shift_reg <= {shift_reg[6:0], 1'b0}; // shift left
                    bit_cnt   <= bit_cnt - 1;
                end

                FINISH: begin
                    cs_reg   <= 1'b1;  // deselect slave
                    done_reg <= 1'b1;
                end
            endcase
        end
    end

    // FSM Combinational Logic
    always_comb begin
        next_state = state;

        case (state)
            IDLE:        next_state = start ? ASSERT_CS : IDLE;
            ASSERT_CS:   next_state = LOAD_BIT;
            LOAD_BIT:    next_state = SCLK_LOW;
            SCLK_LOW:    next_state = SCLK_HIGH;
            SCLK_HIGH:   next_state = NEXT_BIT;
            NEXT_BIT:    next_state = (bit_cnt == 0) ? FINISH : LOAD_BIT;
            FINISH:      next_state = IDLE;
        endcase
    end

endmodule