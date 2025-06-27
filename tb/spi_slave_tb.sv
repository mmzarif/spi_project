// spi_slave_tb.sv

`timescale 1ns / 1ps

module spi_slave_tb;

    // Clock and reset
    logic clk;
    logic rst;

    // SPI signals
    logic sclk;
    logic cs;
    logic mosi;
    logic miso;
    logic done;
    logic [7:0] received_data;

    // Instantiate DUT (Design Under Test)
    spi_slave dut (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .cs(cs),
        .mosi(mosi),
        .miso(miso),
        .done(done),
        .received_data(received_data)
    );

    // Clock generation (50MHz = 20ns period)
    always #10 clk = ~clk;

    // Task to send one bit over SPI
    task spi_send_bit(input logic data_bit);
        begin
            sclk = 0;
            mosi = data_bit;
            #20; // setup time
            sclk = 1;
            #20; // hold time
        end
    endtask


    // Task to send 8 bits MSB first
    task spi_send_byte(input logic [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i--) begin
                spi_send_bit(data[i]);
            end
            sclk = 0;
        end
    endtask

    initial begin
        // Initial conditions
        clk = 0;
        rst = 1;
        cs = 1;
        sclk = 0;
        mosi = 0;
        #40;
        rst = 0;

        // Start SPI transfer
        #40;
        cs = 0; // activate slave

        // Send byte 0x3C
        spi_send_byte(8'h3C);

        // Wait for done
        #100;
        cs = 1; // deactivate slave

        #40;
        $display("Received data = %02h, Done = %b", received_data, done);
        $finish;
    end

endmodule
