`timescale 1ns/1ps

module tb_spi_master;

reg clk;
reg rst;
reg start;
reg miso;
reg [7:0] tx_data;

wire mosi;
wire sclk;
wire cs;
wire done;
wire [7:0] rx_data;

reg [7:0] slave_data;

/////////////////////////////////////////////////
// DUT
/////////////////////////////////////////////////

spi_master dut
(
    .clk(clk),
    .rst(rst),
    .tx_data(tx_data),
    .miso(miso),
    .start(start),

    .mosi(mosi),
    .sclk(sclk),
    .cs(cs),
    .rx_data(rx_data),
    .done(done)
);

/////////////////////////////////////////////////
// 100 MHz Clock
/////////////////////////////////////////////////

initial
begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

/////////////////////////////////////////////////
// Reset
/////////////////////////////////////////////////

initial
begin
    rst = 1'b1;

    #50;
    rst = 1'b0;
end

/////////////////////////////////////////////////
// Stimulus
/////////////////////////////////////////////////

initial
begin
    start = 1'b0;
    tx_data = 8'hAA;      // Master sends 10101010

    slave_data = 8'hAA;      // Slave sends 10101010
    miso  = slave_data[7]; // Preload first bit

    @(negedge rst);

    #20;
    start = 1'b1;

    #10;
    start = 1'b0;

    #20000;

    $display("RX_DATA = %h", rx_data);

    if(rx_data == 8'hAA)
        $display("TEST PASSED");
    else
        $display("TEST FAILED");

    $finish;
end

/////////////////////////////////////////////////
// Slave Model (SPI Mode-0)
/////////////////////////////////////////////////

always @(negedge sclk)
begin
    if(cs == 1'b0)
    begin
        slave_data <= slave_data << 1;
        miso <= slave_data[6];
    end
end

endmodule
