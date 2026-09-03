//=============================================================================
// File: fsm_tx_tb.sv
// Description: Unit-Level Testbench for UART TX FSM
//=============================================================================
`default_nettype none
`timescale 1ns / 1ps
module FSM_tb();
logic i_clk_tb, i_rst_n_tb, i_valid_tb, i_par_en_tb;
logic [1:0]mux_sel_tb;
logic sht_en_tb, o_busy_tb;
FSM dut(.i_clk(i_clk_tb), .i_rst_n(i_rst_n_tb), .i_valid(i_valid_tb), .i_par_en(i_par_en_tb),
.mux_sel(mux_sel_tb), .sht_en(sht_en_tb), .o_busy(o_busy_tb));
initial begin
    i_clk_tb <= 1'b0;
    forever begin
        #5 i_clk_tb <= ~i_clk_tb;
    end
end
initial begin
    $monitor("Time=%0t | i_rst_n=%b | i_valid=%b | i_par_en=%b | state=%0d | mux_sel=%b | shift_en=%b | o_busy=%b",
    $time, i_rst_n_tb, i_valid_tb, i_par_en_tb, dut.current_state, mux_sel_tb, sht_en_tb, o_busy_tb);    
    i_rst_n_tb = 1'b0;
    i_valid_tb = 1'b0;
    i_par_en_tb = 1'b0;
    #15;
    @(negedge i_clk_tb);
    i_rst_n_tb = 1'b1;
    $display("\n___ scenario 1 ___"); 
    @(negedge i_clk_tb);
    i_valid_tb = 1'b1;
    i_par_en_tb = 1'b1;
    @(negedge i_clk_tb);
    i_valid_tb = 1'b0;
    repeat (12) @(negedge i_clk_tb);
    $display("\n___ scenario 2 ___"); 
    @(negedge i_clk_tb);
    i_valid_tb = 1'b1;
    i_par_en_tb = 1'b0;
    @(negedge i_clk_tb);
    i_valid_tb = 1'b0;
    repeat(11) @(negedge i_clk_tb);
    #20
    $finish;
end
    
endmodule
`default_nettype wire