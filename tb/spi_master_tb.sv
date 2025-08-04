
`timescale 1ns/1ps

module spi_master_tb;

  // Clock and reset
  logic clk = 0;
  logic rst = 1;

  // SPI signals
  logic start;
  logic miso;
  logic [7:0] data_to_send;
  logic [1:0] mode;
  logic mosi;
  logic sclk;
  logic cs_n;
  logic done;
  logic [7:0] data_received;

  // Clock generation
  always #4 clk = ~clk; // 125 MHz clock (8ns period)

  // Instantiate DUT
  spi_master #(
    .SCLK_DIVIDER(4)
  ) dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .miso(miso),
    .data_to_send(data_to_send),
    .mode(mode),
    .mosi(mosi),
    .sclk(sclk),
    .cs_n(cs_n),
    .done(done),
    .data_received(data_received)
  );

  // MISO model (just echoing back bits for testing)
  logic [7:0] slave_data = 8'hA5;
  always_ff @(posedge sclk) begin
    miso <= slave_data[7];
    slave_data <= {slave_data[6:0], 1'b0};
  end

  initial begin
    $dumpfile("spi_master_tb.vcd");
    $dumpvars(0, spi_master_tb);

    mode = 2'b00; // Mode 0
    data_to_send = 8'h3C;
    start = 0;

    #20 rst = 0;
    #20 start = 1;
    #10 start = 0;

    wait(done == 1);
    #20;

    $display("Received data: %h", data_received);
    $finish;
  end

endmodule
