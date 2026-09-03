//=============================================================================
// File: edge_detec.sv
// Description: Asynchronous Falling Edge Detector for Start Bit
//=============================================================================`default_nettype none
`default_nettype none
module edge_detec (
    input logic i_clk,
    input logic i_rst_n,
    input logic i_a,
    output logic o_pos_edge,
    output logic o_neg_edge,
    output logic o_edge
);
logic a_d;

always_ff@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        a_d <= 1'b1;
    end
    else begin
        a_d <= i_a;
    end
end
always_comb begin
    o_pos_edge = i_a && !a_d;
    o_neg_edge = !i_a && a_d;
    o_edge = i_a ^ a_d;    
end
    
endmodule
`default_nettype wire