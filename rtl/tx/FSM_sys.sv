//=============================================================================
// File: fsm_tx.sv
// Description: Finite State Machine Controller for UART TX
//=============================================================================
`default_nettype none

module FSM(i_clk, i_rst_n, i_valid, i_par_en, mux_sel, sht_en, o_busy);
parameter DATA_W = 8;
input i_clk, i_rst_n, i_valid, i_par_en;
output logic [1:0]mux_sel;
output logic sht_en, o_busy;
typedef enum logic[2:0]{idle, start, data_in, parity, stop} state_e;
state_e current_state, next_state;
logic [4:0] count;
always_ff@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        current_state <= idle;
        count <= 5'b000_00;
    end
    else begin
        current_state <= next_state;
        if(current_state == data_in)begin
            count <= count + 1'b1;
        end
        else begin
            count <= 5'b000_00;
        end
    end
end
always_comb begin
    case (current_state)
        idle: begin 
        if(i_valid)begin
            next_state = start;
        end
        else begin
            next_state = idle;
        end
        end
        start: next_state = data_in;
        data_in: begin
                if(count == DATA_W - 1)begin
                if(i_par_en)begin
                    next_state = parity;
                end
                else begin
                    next_state = stop;
                end
            end
            else begin
                next_state = data_in;
            end
        end
        parity: next_state = stop;
        stop: next_state = idle; 
        default: next_state = idle;
    endcase
end
always_comb begin
    mux_sel = 2'b11;
    sht_en = 1'b0;
    o_busy = 1'b1;
    case(current_state)
        idle: begin
            mux_sel = 2'b11;
            o_busy = 1'b0;
        end
        start: begin
            mux_sel = 2'b00;
            o_busy = 1'b1;
        end
        data_in: begin
            mux_sel = 2'b01;
            o_busy = 1'b1;
            sht_en = 1'b1;
        end
        parity: begin
            mux_sel = 2'b10;
        end
        stop: begin
            mux_sel = 2'b11;
            o_busy = 1'b1;
            sht_en = 1'b0;
        end
        default: begin
            mux_sel = 2'b11;
            o_busy = 1'b1;
            sht_en = 1'b0;       
        end
        
    endcase
end
endmodule
`default_nettype wire
