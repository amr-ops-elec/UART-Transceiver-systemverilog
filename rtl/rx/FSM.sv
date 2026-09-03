//=============================================================================
// File: FSM_rx.sv
// Description: Finite State Machine Controller for UART RX
//=============================================================================
`default_nettype none

module FSM_rx (
    input logic i_clk,
    input logic i_rst_n,
    input logic i_rx,
    input logic i_rx_fall,
    input logic i_par_en,
    input logic i_par_err_calc,
    output logic o_sht_en,
    output logic o_par_sample_en,
    output logic o_busy,
    output logic o_valid,
    output logic o_parity_err,
    output logic o_frame_err
);

parameter DATA_W = 8;
typedef enum logic [2:0]{ idle, start, data, parity, stop } state;
state crnt_st, next_st;
logic [4:0]count;

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        crnt_st <= idle;
    end
    else begin
        crnt_st <= next_st;
        if(crnt_st == data)begin
            count <= count + 1'b1;
        end
        else begin
            count <= 5'b0;
        end
    end
end

always_comb begin
    next_st = crnt_st;
    o_sht_en = 1'b0;
    o_par_sample_en = 1'b0;
    o_busy = 1'b1;
    o_valid = 1'b0;
    o_parity_err = 1'b0;
    o_frame_err = 1'b0;
    case (crnt_st)
        idle: begin
            o_busy = 1'b0;
            if(i_rx_fall) begin
                next_st = data;
	            o_busy = 1'b1;
            end
            else begin
               next_st = idle;
            end
        end
        start: begin
            next_st = data;
        end
        data: begin
            o_sht_en = 1'b1;
            if(count == DATA_W -1 ) begin
                if(i_par_en) begin
                    next_st = parity;
                end
                else begin
                    next_st = stop;
                end
            end
            else next_st = data;
        end
        parity: begin
            next_st = stop;
            o_par_sample_en = 1'b1;
        end 
        stop: begin
            o_valid = 1'b1;
            o_frame_err = !i_rx;
            o_parity_err = i_par_en && i_par_err_calc;
            next_st = idle;
        end
        default: next_st = idle;
    endcase
end
    
endmodule
`default_nettype wire
