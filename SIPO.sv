//=============================================================================
// File: sipo.sv
// Description: Serial-In Parallel-Out (SIPO) Deserializer
//=============================================================================
`default_nettype none

module sipo #(parameter DATA_W = 8)(
    input  logic              i_clk,
    input  logic              i_rst_n,
    input  logic              i_en,
    input  logic              i_ser,
    output logic [DATA_W-1:0] o_par
);


always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_par <= 1'b0;
    end 
    else if (i_en) begin
        o_par <= {i_ser, o_par[DATA_W-1:1]};
    end
end

endmodule
`default_nettype wire