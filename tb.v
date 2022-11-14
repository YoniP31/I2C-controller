`timescale 1ns/1ns
`include "master.v"
`include "slave.v"

module tb;
logic clk;
logic sdata;
logic [6:0] address_in;
logic address_r_w;
logic [7:0] master_sdata_in;
logic [7:0] slave_sdata_in;
logic sclk_out;
logic sdata_out;

master master_DUT
(
    .i_sclk (clk),
    .i_sdata(sdata),
    .i_address_in(address_in),
    .i_address_r_w(address_r_w),
    .i_sdata_in(master_sdata_in),
    .o_sclk(sclk_out),
    .o_sdata(sdata_out)
);

slave slave_DUT
(
    .i_sclk(sclk_out),
    .i_sdata(sdata_out),
    .i_data_out(slave_sdata_in),
    .o_sdata(sdata)
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
end

initial begin
    clk = 0;
    address_in = 'd0;
    address_r_w = 0;
    master_sdata_in = 'd0;
    slave_sdata_in = 'd0;
    
    repeat(2) @(posedge clk);
    address_in = 'b1011001;
    address_r_w = 1'b1;
    master_sdata_in = 'b10101010;
    slave_sdata_in = 'b10101010;
    #130
    address_in = 'b0;
    #2000
    $display("test complete");
    $finish;
end

endmodule