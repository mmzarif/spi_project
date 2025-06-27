module spi_slave (
    input logic clk, // logic allows sv to infer what logic type to use, e.g. wire or reg
    input logic rst,
    input logic sclk,
    input logic cs,
    input logic mosi,
    output logic miso, //bit by bit data out of the slave
    output logic done,
    output logic [7:0] received_data //8-bit value produced by the slave and exposed outward
);

    logic sclk_delayed;
    logic sclk_rising; //rising edge of sclk
    logic sclk_falling; //falling edge of sclk

    logic [7:0] shift_reg_in;
    logic [7:0] shift_reg_out; //8-bit shift register to hold the received data
    logic [2:0] bit_count; //3-bit counter to keep track of the number of bits received

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        RECEIVING = 2'b01,
        DONE = 2'b10
    } state_t;

    state_t current_state, next_state;

    //update current state based on clk or rst
    //if rst is high, reset to IDLE state, otherwise update to next_state
    //update sclk_delayed to the current value of sclk
    //sclk_delayed is used to detect the rising and falling edges of sclk
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            sclk_delayed <= 1'b0;
            bit_count <= 3'b0; //reset bit count to 0
            shift_reg_in <= 8'b0; //reset shift register input to 0
            shift_reg_out <= 8'hA5; //reset shift register output to dummy value
            miso <= 1'b0; //reset miso to 0
            done <= 1'b0; //reset done to 0
        end else begin
            current_state <= next_state;
            sclk_delayed <= sclk; //delay sclk by one clock cycle

            case (current_state)
                IDLE: begin
                    bit_count <= 3'b0; //reset bit count to 0
                    shift_reg_out <= 8'hA5; //reset shift register output to dummy value
                end

                RECEIVING: begin
                    if (sclk_rising) begin //on rising edge of sclk, shift in data from mosi
                        shift_reg_in <= {shift_reg_in[6:0], mosi}; //shift in the new bit from mosi
                        bit_count <= bit_count + 1; //increment bit count
                    end
                    if (sclk_falling) begin //on falling edge of sclk, prepare miso output
                        miso <= shift_reg_out[7]; //output the most significant bit of the shift register
                        shift_reg_out <= {shift_reg_out[6:0], 1'b0}; //shift out the data to miso
                    end
                end

                DONE: begin
                    received_data <= shift_reg_in; //output the received data when done
                    //done <= 1'b1; //set done signal high to indicate completion. THIS WONT WORK SINCE WE NEED TO LET THE CLK RUN FOR ONE MORE CYCLE
                end
                
            endcase

            // if (current_state == DONE) begin
            //     done <= 1'b1; //set done signal high to indicate completion
            // end else begin
            //     done <= 1'b0; //reset done signal in other states
            // end
            done <= (current_state == DONE); //set done signal high only in DONE state

        end
    end

    //Continuously drive these signals with these expressions.
    assign sclk_rising = (sclk && !sclk_delayed); //detect rising edge of sclk (1 after 0). At all times, evaluate this condition and set sclk_rising accordingly.
    assign sclk_falling = (!sclk && sclk_delayed); //detect falling edge of sclk (0 after 1)
    //assigns are used outside always blocks for continous combinational logic.
    // = is used for blocking assignments, whereas <= is used for non-blocking assignments in always blocks.

    //state transition FSM
    always_comb begin
        next_state = current_state; //default to current state
        case (current_state)
            IDLE: begin
                if (!cs) //event based so no sclk in parameter
                    next_state = RECEIVING; //if chip select is low, move to RECEIVING state
            end

            RECEIVING: begin
                if (bit_count == 3'd7 && sclk_rising) //Since we're indexing from 0, the 8th bit corresponds to bit_count == 7. 
                                                        //we concerned with how many bits have been clocked in using sclk. end at 8th rising edge
                    next_state = DONE; //if received data is complete, move to DONE stat
            end

            DONE: begin
                if (cs) //if chip select goes high, return to IDLE state. //event based so no sclk in parameter
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE; //default case to handle unexpected states
            end
        endcase
    end

endmodule