//=============================================================================
// File: uart_rx.sv
// Description: Top-Level UART Receiver Module
//=============================================================================
`default_nettype none

module uart_rx #(parameter DATA_W = 8)(
    input logic i_clk,
    input logic i_rst_n,
    input logic i_par_en,
    input logic i_par_odd,
    input logic i_rx,
    output logic  [DATA_W-1:0] o_data,
    output logic o_busy,
    output logic o_frame_err,
    output logic o_parity_err,
    output logic o_valid
);

logic rx_fall;
logic par_err_calc;
logic sht_en;
logic par_sample_en;
logic par_calc_out;
logic received_par_bit;
logic [DATA_W-1:0] rx_data_internal;
edge_detec u_edge_detect(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_a(i_rx), .o_pos_edge(), .o_neg_edge(rx_fall), .o_edge());
sipo #(.DATA_W(DATA_W)) u_sipo (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_en(sht_en), .i_ser(i_rx), .o_par(rx_data_internal));

parity_calc u_parity_calc (.PARITY_EO(i_par_odd), .i_data(rx_data_internal), .par_calc(par_calc_out));
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        received_par_bit <= 1'b0;
    end
    else if(par_sample_en)begin
        received_par_bit <= i_rx; 
    end
end
assign par_err_calc = (par_calc_out != received_par_bit);

FSM_rx #(.DATA_W(DATA_W)) u_FSM(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_rx(i_rx), .i_rx_fall(rx_fall), .i_par_en(i_par_en), .i_par_err_calc(par_err_calc),
.o_sht_en(sht_en), .o_par_sample_en(par_sample_en), .o_busy(o_busy), .o_valid(o_valid), .o_parity_err(o_parity_err),
.o_frame_err(o_frame_err));
assign o_data = rx_data_internal;
endmodule
`default_nettype wire
