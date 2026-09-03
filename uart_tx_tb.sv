//=============================================================================
// File: uart_tx_tb.sv
// Description: Unit-Level Testbench for UART Transmitter
//=============================================================================
`default_nettype none
`timescale 1ns/1ps

module uart_tx_tb ();
parameter DATA_W = 8;
logic [DATA_W-1:0]i_data_tb;
logic i_valid_tb, i_clk_tb, i_rst_n_tb, i_par_en_tb, i_par_odd_tb;
logic o_tx_tb, o_busy_tb;
UART_TX dut(.i_data(i_data_tb), .i_valid(i_valid_tb), .i_clk(i_clk_tb), .i_rst_n(i_rst_n_tb), .i_par_en(i_par_en_tb),
.i_par_odd(i_par_odd_tb), .o_tx(o_tx_tb), .o_busy(o_busy_tb));
initial begin
    i_clk_tb = 1'B0;
    forever begin
        #5 i_clk_tb = ~i_clk_tb; 
    end
end
initial begin
    $monitor("TIME=%0t | i_data=%b , i_valid=%b , i_par_en=%b , i_par_bit=%b | o_tx=%b , o_busy=%b", $time , i_data_tb,
    i_valid_tb, i_par_en_tb, i_par_bit_tb, o_tx_tb, o_busy_tb);

    i_rst_n_tb = 1'b0;
    i_valid_tb = 1'b0;
    i_par_en_tb = 1'b0;
    i_par_odd_tb = 1'b0;
    i_data_tb = 8'b0;
    #15;
    @(negedge i_clk_tb);
    i_rst_n_tb = 1'b1;
    @(negedge i_clk_tb);
    i_data_tb = {N{1'b1010_0110}};
    i_valid_tb = 1'b1;
    i_par_en_tb = 1'b1;
    i_par_odd_tb = 1'b0;
    @(negedge i_clk_tb);
    i_valid_tb = 1'b0;
    repeat (12) @(negedge i_clk_tb);
    @(negedge i_clk_tb);
    i_data_tb = {N{1'b1010_0100}};
    i_valid_tb = 1'b1;
    i_par_en_tb = 1'b1;
    i_par_odd_tb = 1'b1;
    @(negedge i_clk_tb);
    i_valid_tb = 1'b0;
    repeat (12) @(negedge i_clk_tb);
    @(negedge i_clk_tb);
    i_data_tb = {N{1'b1011_0010}};
    i_valid_tb = 1'b1;
    i_par_en_tb = 1'b0;
    i_par_odd_tb = 1'b0;
    @(negedge i_clk_tb);
    i_valid_tb = 1'b0;
    repeat (11) @(negedge i_clk_tb);
    $finish;
end
endmodule
`default_nettype wire