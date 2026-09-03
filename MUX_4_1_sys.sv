//=============================================================================
// File: mux_4_1.sv
// Description: 4-to-1 Multiplexer for TX Output Routing
//=============================================================================
`default_nettype none

module MUX_4_1(serial_out_in_MUX, sel, i_par_odd_MUX, o_tx);
input logic [1:0] sel; 
input logic serial_out_in_MUX;
input logic i_par_odd_MUX;
output logic o_tx;
always_comb begin
    case (sel)
        2'b00: o_tx = 1'B0;
        2'b01: o_tx = serial_out_in_MUX;
        2'b10: o_tx = i_par_odd_MUX;
        2'b11: o_tx = 1'b1; 
        default: o_tx = 1'b1; 
    endcase
end
endmodule
`default_nettype wire