//=============================================================================
// File: serializer.sv
// Description: Parallel-to-Serial Shift Register
//=============================================================================
`default_nettype none

module serializer (i_data, i_valid, sht_en, i_clk, i_rst_n, serial_out);
parameter DATA_W = 8;
input logic [DATA_W-1:0]i_data;
input logic i_valid,sht_en, i_clk, i_rst_n;
output logic serial_out;
logic [DATA_W-1:0]sht_reg;
always_ff@(posedge i_clk or negedge i_rst_n)
begin
if(!i_rst_n) begin
    sht_reg <= {DATA_W{1'b0}};
end 
else if(i_valid) begin
    sht_reg <= i_data;
    end
else if(sht_en)begin
    sht_reg <= {1'b0, sht_reg[DATA_W-1:1]};
end
end
assign serial_out = sht_reg[0];
endmodule
`default_nettype wire
