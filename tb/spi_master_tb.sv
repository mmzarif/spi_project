`timescale 1ns/1ps

module spi_master_tb;

    // Testbench signals
    logic clk = 0;
    logic rst;
    logic start;
    logic [7:0] data2send;
    logic miso;
    logic done;
    logic sclk;
    logic mosi;
    logic cs;
    logic [7:0] data2receive;

    // Instantiate DUT
    spi_master_mode0 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data2send(data2send),
        .miso(miso),
        .done(done),
        .sclk(sclk),
        .mosi(mosi),
        .cs(cs),
        .data2receive(data2receive)
    );

    // Clock generator
    always #5 clk = ~clk; // 10 ns period

    // Test stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        start = 0;
        miso = 0;
        data2send = 8'b1010_1101; // Send this byte

        #20;
        rst = 0;

        #20;
        start = 1;

        #10;
        start = 0; // Pulse start for 1 cycle

        // Simulate slave returning 8'b01010101 over MISO
        // Return 1 bit per rising edge of sclk
        fork
            // Stimulate miso on each SCLK rising edge (mode 0)
            begin
                wait (cs == 0); // wait for CS low
                repeat (8) begin
                    @(posedge sclk);
                    miso <= $random % 2; // or manually set a pattern
                end
            end
        join

        // Wait for transaction to complete
        wait (done);

        // Print results
        $display("SPI Transaction complete!");
        $display("Sent:    %b", data2send);
        $display("Received:%b", data2receive);

        #50;
        $finish;
    end

endmodule
