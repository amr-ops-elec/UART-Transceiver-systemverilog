//=============================================================================
// File: serializer_tb.sv
// Description: Unit-Level Testbench for TX Serializer
//=============================================================================
`default_nettype none
`timescale 1ns / 1ps

module serializer_tb();
parameter DATA_W = 8;
logic [DATA_W-1:0]i_data_tb;
logic sht_en_tb, i_valid_tb, i_clk_tb, i_rst_n_tb;
logic serial_out_tb;
serializer dut(.i_data(i_data_tb), .i_valid(i_valid_tb), .sht_en(sht_en_tb), .i_clk(i_clk_tb), .i_rst_n(i_rst_n_tb), .serial_out(serial_out_tb));
initial begin
    i_clk_tb = 0;
    forever #5 i_clk_tb = ~i_clk_tb;
end
initial begin 
$monitor ("Time=%0t | sht_en=%b , i_valid_tb , i_rst_n=%b , i_data=%b | serial_out=%b",
$time, sht_en_tb, i_valid_tb, i_rst_n_tb, i_data_tb, serial_out_tb);
i_rst_n_tb = 0;
i_valid_tb = 1'b0;
i_data_tb = 8'b1011_0110;
sht_en_tb = 1'b0;
#15;
i_rst_n_tb = 1;
@(negedge i_clk_tb);
i_data_tb = 8'b1011_0110;
i_valid_tb = 1'b1;
#10;
i_valid_tb = 1'b0;
sht_en_tb = 1'b1;
#80;
sht_en_tb = 1'b0;
$finish;
end
endmodule
`default_nettype wire