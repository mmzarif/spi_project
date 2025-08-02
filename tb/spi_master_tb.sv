`timescale 1ns/1ps

module spi_master_tb;

  // Parameters
  parameter DIVIDER = 4; // small for simulation
  parameter CLK_PERIOD = 10;

  // DUT inputs
  logic clk, rst, start, miso;
  logic [7:0] data_to_send;
  logic [1:0] mode;

  // DUT outputs
  logic mosi, sclk, cs_n, done;
  logic [7:0] data_received;

  // Instantiate DUT
  spi_master #(.DIVIDER(DIVIDER)) dut (
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

  // Clock generation
  always #(CLK_PERIOD/2) clk = ~clk;

  // Fake MISO behavior: return 0xA5 = 10100101
  logic [7:0] fake_miso_data = 8'hA5;
  integer miso_bit_idx;

  always @(negedge sclk) begin
    if (!cs_n && dut.state == dut.TRANSFER)
      miso <= fake_miso_data[7 - miso_bit_idx];
  end

  // Stimulus
  initial begin
    $display("Starting SPI Master Testbench");

    // Initialize
    clk = 0;
    rst = 1;
    start = 0;
    miso = 1'bZ;
    data_to_send = 8'h3C;
    mode = 2'b00; // Mode 0
    miso_bit_idx = 0;

    #20 rst = 0;
    #30 start = 1;
    #10 start = 0;

    // Wait for transfer
    wait(done);
    #20;

    $display("Received: %h", data_received);
    $finish;
  end

  // Bit counter for MISO simulation
  always @(posedge clk) begin
    if (!cs_n && dut.state == dut.TRANSFER && (dut.sample_edge || dut.shift_edge))
      miso_bit_idx <= miso_bit_idx + 1;
    else if (rst || dut.state == dut.IDLE)
      miso_bit_idx <= 0;
  end

endmodule