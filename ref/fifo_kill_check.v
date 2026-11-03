`timescale 1ns/1ps
// Reference self-checking TB (plain Verilog). Purpose: prove every mutant is
// killable, i.e. non-equivalent. NOT one of the six LLM rows.
// Model: flags, overflow/underflow and read data checked every cycle.
module fifo_kill_check;
  parameter DATA_WIDTH = 8, DEPTH = 16, N_CYCLES = 4000;

  reg clk = 0, rst = 1, wr_en = 0, rd_en = 0;
  reg  [DATA_WIDTH-1:0] din = 0;
  wire [DATA_WIDTH-1:0] dout;
  wire full, empty, overflow, underflow;

  fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst(rst), .wr_en(wr_en), .rd_en(rd_en), .din(din),
    .dout(dout), .full(full), .empty(empty),
    .overflow(overflow), .underflow(underflow));

  always #5 clk = ~clk;

  // reference model: circular queue
  reg [DATA_WIDTH-1:0] q [0:DEPTH-1];
  integer head = 0, tail = 0, cnt = 0, errors = 0, cyc = 0;
  reg exp_valid = 0, exp_ovf = 0, exp_udf = 0;
  reg [DATA_WIDTH-1:0] exp_data;
  reg wr_acc, rd_acc;

  task check(input cond, input [8*24-1:0] what);
    if (!cond) begin
      errors = errors + 1;
      if (errors <= 5) $display("ERROR cyc=%0d %0s", cyc, what);
    end
  endtask

  // stimulus phases: fill, hold full with simultaneous R/W, drain, random
  function [1:0] pick;  // {wr,rd}
    input integer c;
    if      (c < 40)   pick = 2'b10;
    else if (c < 120)  pick = 2'b11;
    else if (c < 180)  pick = 2'b01;
    else               pick = {$random % 3 != 0, $random % 2 == 0};
  endfunction

  always @(posedge clk) begin
    if (!rst) begin
      // checks on outputs produced by the previous edge
      check(full  == (cnt == DEPTH), "full flag");
      check(empty == (cnt == 0),     "empty flag");
      check(overflow  == exp_ovf,    "overflow flag");
      check(underflow == exp_udf,    "underflow flag");
      if (exp_valid) check(dout == exp_data, "read data");

      // model update for the inputs applied this edge (DUT semantics)
      wr_acc = wr_en && (cnt < DEPTH || rd_en);
      rd_acc = rd_en && (cnt > 0);
      exp_ovf = wr_en && !wr_acc;
      exp_udf = rd_en && !rd_acc;
      exp_valid = rd_acc;
      if (rd_acc) begin exp_data = q[head]; head = (head + 1) % DEPTH; end
      if (wr_acc) begin q[tail] = din; tail = (tail + 1) % DEPTH; end
      cnt = cnt + wr_acc - rd_acc;
      cyc = cyc + 1;
    end
  end

  // drive on negedge so inputs are stable at posedge
  always @(negedge clk) if (!rst) begin
    {wr_en, rd_en} = pick(cyc);
    din = $random;  // full 8-bit range, MSB toggles
  end

  initial begin
    repeat (2) @(posedge clk);
    @(negedge clk) rst = 0;
    // reset-state check on first post-reset edge happens in the always block
    repeat (N_CYCLES) @(posedge clk);
    if (errors == 0) $display("RESULT PASS");
    else             $display("RESULT FAIL errors=%0d", errors);
    $finish;
  end
endmodule
