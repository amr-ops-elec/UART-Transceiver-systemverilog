//=============================================================================
// File: parity_calc.sv
// Description: Combinational Parity Calculator
//=============================================================================
`default_nettype none

module parity_calc(PARITY_EO, par_calc, i_data);
parameter DATA_W = 8;
input logic PARITY_EO;
input logic [DATA_W-1:0]i_data;
output logic par_calc;
always_comb begin
    if(!PARITY_EO)begin
        par_calc = ^i_data;
    end
    else begin
         par_calc = ~^i_data;
    end
end 
endmodule
`default_nettype wire