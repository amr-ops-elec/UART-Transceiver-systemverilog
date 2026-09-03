//-----------------------------------------------------------------------------
// Testbench : uart_grading_tb   (Testbench B - advanced / grading)
// Purpose   : Instructor-side grading harness (spec section 5.2). Not shown to
//             students before submission. Instantiates the student's uart_tx and
//             uart_rx, wires TX_OUTPUT -> RX_INPUT on a testbench-owned wire, and
//             drives traffic through it:
//               - many randomized bytes, parity disabled
//               - many randomized bytes, even and odd parity
//               - one injected parity error  (wire flipped on the parity cycle)
//               - one injected framing error (wire flipped on the stop cycle)
//               - back-to-back frames
//               - a load attempt while BUSY (must be ignored)
//             It touches only the module PORTS - no hierarchical references into
//             the DUT - so any spec-compliant TX/RX grades correctly regardless
//             of internal structure or naming.
//
//             Basic SystemVerilog only: module, initial/always, task, $display,
//             $random. No clocking blocks, assertions or classes.
// Author    : <author>
// Date      : <date>
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module uart_grading_tb;

  localparam int unsigned DATA_W   = 8;
  localparam time         CLK_PER  = 10ns;
  localparam int unsigned N_RAND   = 20;    // random bytes per parity mode
  localparam int unsigned MAX_XACT = 512;

  // DUT interconnect
  logic              clk;
  logic              rst_n;

  logic [DATA_W-1:0] tx_data;
  logic              tx_valid;
  logic              par_en;
  logic              par_odd;
  logic              tx_busy;

  wire               line;   // TX_OUTPUT -> RX_INPUT (wire so force/release works)

  logic [DATA_W-1:0] rx_data;
  logic              rx_valid;
  logic              rx_busy;
  logic              parity_err;
  logic              frame_err;

  // Scoreboard
  logic [DATA_W-1:0] exp_data [0:MAX_XACT-1];
  logic              exp_perr [0:MAX_XACT-1];
  logic              exp_ferr [0:MAX_XACT-1];
  int unsigned       wr_idx     = 0;
  int unsigned       rd_idx     = 0;
  int unsigned       pass_cnt   = 0;
  int unsigned       unexpected = 0;

  logic              inj_val;   // static holder for the injected bit value

  //-------------------------------------------------------------------------
  // Clock
  //-------------------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #(CLK_PER/2) clk = ~clk;
  end

  //-------------------------------------------------------------------------
  // Devices under test - student files, connected here in the testbench
  //-------------------------------------------------------------------------
  uart_tx #(.DATA_W(DATA_W)) u_tx (
    .i_clk     (clk),
    .i_rst_n   (rst_n),
    .i_data    (tx_data),
    .i_valid   (tx_valid),
    .i_par_en  (par_en),
    .i_par_odd (par_odd),
    .o_busy    (tx_busy),
    .o_tx      (line)
  );

  uart_rx #(.DATA_W(DATA_W)) u_rx (
    .i_clk        (clk),
    .i_rst_n      (rst_n),
    .i_rx         (line),
    .i_par_en     (par_en),
    .i_par_odd    (par_odd),
    .o_data       (rx_data),
    .o_valid      (rx_valid),
    .o_busy       (rx_busy),
    .o_parity_err (parity_err),
    .o_frame_err  (frame_err)
  );

  //-------------------------------------------------------------------------
  // Scoreboard checker - every RX valid pulse is matched against the queue.
  // One correctly delivered frame (data + both error flags) = one point.
  //-------------------------------------------------------------------------
  always @(negedge clk) begin
    if (rst_n && rx_valid) begin
      if (rd_idx >= wr_idx) begin
        unexpected = unexpected + 1;
        $display("FAIL: unexpected RX byte 0x%02h (no frame was queued)", rx_data);
      end else begin
        if ((rx_data    === exp_data[rd_idx]) &&
            (parity_err === exp_perr[rd_idx]) &&
            (frame_err  === exp_ferr[rd_idx])) begin
          pass_cnt = pass_cnt + 1;
          $display("ok[%0d]: d=0x%02h pe=%0b fe=%0b", rd_idx, rx_data, parity_err, frame_err);
        end else begin
          $display("FAIL[%0d]: got d=0x%02h pe=%0b fe=%0b | exp d=0x%02h pe=%0b fe=%0b",
                   rd_idx, rx_data, parity_err, frame_err,
                   exp_data[rd_idx], exp_perr[rd_idx], exp_ferr[rd_idx]);
        end
        rd_idx = rd_idx + 1;
      end
    end
  end

  //-------------------------------------------------------------------------
  // Stimulus helpers
  //-------------------------------------------------------------------------
  task automatic queue_expect(input logic [DATA_W-1:0] d,
                              input logic               pe,
                              input logic               fe);
    begin
      exp_data[wr_idx] = d;
      exp_perr[wr_idx] = pe;
      exp_ferr[wr_idx] = fe;
      wr_idx = wr_idx + 1;
    end
  endtask

  // Load one byte into TX, respecting BUSY. Returns right after the 1-cycle
  // V_INPUT pulse so the caller can corrupt the frame still in flight.
  task automatic tx_send(input logic [DATA_W-1:0] d);
    begin
      @(negedge clk);
      while (tx_busy) @(negedge clk);
      tx_data  = d;
      tx_valid = 1'b1;
      @(negedge clk);
      tx_valid = 1'b0;
    end
  endtask

  // Flip one bit slot of the frame currently starting on the wire, for exactly
  // one cycle. Call this immediately after tx_send() returns - at that point the
  // start bit is already on the line (slot 0). Slots: 0 = start, 1..8 = data,
  // 9 = the slot right after the last data bit (parity when P_EN=1, otherwise
  // stop), 10 = stop when P_EN=1. Black box: keyed off the serial line only.
  task automatic corrupt_next_frame(input int unsigned bit_slot);
    begin
      if (line !== 1'b0) begin
        $display("WARN: corrupt_next_frame called but start bit not on the wire");
      end
      repeat (bit_slot) @(negedge clk);       // advance from slot 0 to target slot
      inj_val = ~line;                        // inverse of what TX drives there
      force line = inj_val;                   // hold it for exactly one cycle
      @(negedge clk);
      release line;
    end
  endtask

  task automatic wait_drain();
    int unsigned guard;
    begin
      guard = 0;
      while ((rd_idx < wr_idx) && (guard < 10000)) begin
        @(negedge clk);
        guard = guard + 1;
      end
    end
  endtask

  //-------------------------------------------------------------------------
  // Test sequence
  //-------------------------------------------------------------------------
  logic [DATA_W-1:0] b;
  int unsigned       i;
  int unsigned       total;

  initial begin
    $dumpfile("sim/waves/uart_grading_tb.vcd");
    $dumpvars(0, uart_grading_tb);

    rst_n    = 1'b0;
    tx_data  = '0;
    tx_valid = 1'b0;
    par_en   = 1'b0;
    par_odd  = 1'b0;
    repeat (4) @(negedge clk);
    rst_n = 1'b1;
    repeat (4) @(negedge clk);

    // 1) random bytes, parity disabled
    $display("=== 1) random data, P_EN=0 ===");
    par_en = 1'b0; par_odd = 1'b0;
    for (i = 0; i < N_RAND; i = i + 1) begin
      b = $random;
      queue_expect(b, 1'b0, 1'b0);
      tx_send(b);
    end
    wait_drain();   // let frames land before changing the shared parity config

    // 2) random bytes, even parity
    $display("=== 2) random data, P_EN=1 P_BIT=0 (even) ===");
    par_en = 1'b1; par_odd = 1'b0;
    for (i = 0; i < N_RAND; i = i + 1) begin
      b = $random;
      queue_expect(b, 1'b0, 1'b0);
      tx_send(b);
    end
    wait_drain();

    // 3) random bytes, odd parity
    $display("=== 3) random data, P_EN=1 P_BIT=1 (odd) ===");
    par_en = 1'b1; par_odd = 1'b1;
    for (i = 0; i < N_RAND; i = i + 1) begin
      b = $random;
      queue_expect(b, 1'b0, 1'b0);
      tx_send(b);
    end
    wait_drain();

    // 4) injected parity error - flip the parity-bit slot (slot 9 with P_EN=1)
    $display("=== 4) injected parity error ===");
    par_en = 1'b1; par_odd = 1'b0;
    b = 8'hC3;
    queue_expect(b, 1'b1, 1'b0);   // byte still delivered, PARITY_ERR set
    tx_send(b);
    corrupt_next_frame(9);
    wait_drain();

    // 5) injected framing error - flip the stop-bit slot (slot 9 with P_EN=0)
    $display("=== 5) injected framing error ===");
    par_en = 1'b0; par_odd = 1'b0;
    b = 8'h5C;
    queue_expect(b, 1'b0, 1'b1);   // byte still delivered, FRAME_ERR set
    tx_send(b);
    corrupt_next_frame(9);
    wait_drain();

    // 6) back-to-back frames - reload the cycle BUSY clears
    $display("=== 6) back-to-back frames ===");
    par_en = 1'b1; par_odd = 1'b1;
    b = 8'hA5; queue_expect(b, 1'b0, 1'b0); tx_send(b);
    b = 8'h5A; queue_expect(b, 1'b0, 1'b0); tx_send(b);
    b = 8'hFF; queue_expect(b, 1'b0, 1'b0); tx_send(b);
    wait_drain();

    // 7) busy-reject - a load attempt while BUSY must be ignored
    $display("=== 7) busy-reject ===");
    par_en = 1'b0; par_odd = 1'b0;
    b = 8'h39; queue_expect(b, 1'b0, 1'b0); tx_send(b);
    @(negedge clk);
    while (!tx_busy) @(negedge clk);
    tx_data  = 8'hAA;          // this load must NOT take effect
    tx_valid = 1'b1;
    @(negedge clk);
    tx_valid = 1'b0;
    wait_drain();
    repeat (30) @(negedge clk); // give any spurious frame time to appear

    // Verdict
    total = wr_idx;
    $display("");
    $display("frames sent      : %0d", wr_idx);
    $display("frames delivered : %0d", rd_idx);
    $display("unexpected frames: %0d", unexpected);
    $display("SCORE %0d %0d", pass_cnt, total);
    $display("GRADING: %0d / %0d frames correct", pass_cnt, total);
    if ((pass_cnt == total) && (unexpected == 0)) begin
      $display("RESULT: PASS");
    end else begin
      $display("RESULT: FAIL");
    end
    $finish;
  end

  //-------------------------------------------------------------------------
  // Safety timeout
  //-------------------------------------------------------------------------
  initial begin
    #500000;
    $display("SCORE %0d %0d", pass_cnt, wr_idx);
    $display("RESULT: FAIL - simulation timeout");
    $finish;
  end

endmodule

`default_nettype wire
