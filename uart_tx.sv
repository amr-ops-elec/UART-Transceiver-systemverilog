//=============================================================================
// File: uart_tx.sv
// Description: Top-Level UART Transmitter Module
//=============================================================================             
`default_nettype none

module uart_tx #(parameter DATA_W = 8) (i_data, i_valid, i_clk, i_rst_n, i_par_en, i_par_odd, o_tx, o_busy);

input logic [DATA_W-1:0]i_data;
input logic i_valid, i_clk, i_rst_n, i_par_en, i_par_odd;
output logic o_tx, o_busy;
logic sht_en;
logic [1:0] mux_sel;
logic serial_out;
logic par_calc;
serializer #(.DATA_W (DATA_W)) ser_dut(.i_data(i_data), .i_valid(i_valid), .sht_en(sht_en), .i_clk(i_clk), .i_rst_n(i_rst_n), .serial_out(serial_out));
FSM #(.DATA_W (DATA_W)) FSM_dut(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_valid(i_valid), .i_par_en(i_par_en), .mux_sel(mux_sel), .sht_en(sht_en), .o_busy(o_busy));
parity_calc #(.DATA_W (DATA_W)) par_dut(.PARITY_EO(i_par_odd), .par_calc(par_calc), .i_data(i_data));
MUX_4_1 mux_dut(.serial_out_in_MUX(serial_out), .sel(mux_sel), .i_par_odd_MUX(par_calc), .o_tx(o_tx));    
endmodule
`default_nettype wire
