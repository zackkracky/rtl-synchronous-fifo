`timescale 1ns/1ps
//======================================================================
// Self-checking testbench for the parameterised synchronous FIFO.
//
// Replaces the earlier visual testbench: every output is compared against
// a reference model on every clock, and the run ends with TEST PASSED or
// TEST FAILED and a non-zero exit on failure, so it can gate CI.
//
// Covers the same scenarios as the five directed testbenches in one run:
// fill to full, drain to empty, overflow, underflow, pointer wrap-around,
// and simultaneous read/write, followed by a randomised soak.
//======================================================================
module fifo_tb;

  parameter DATA_WIDTH = 8;
  parameter DEPTH      = 16;
  parameter SOAK_OPS   = 2000;

  reg                   clk = 0;
  reg                   rst;
  reg                   wr_en, rd_en;
  reg  [DATA_WIDTH-1:0] din;
  wire [DATA_WIDTH-1:0] dout;
  wire                  full, empty, overflow, underflow;

  fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst(rst), .wr_en(wr_en), .rd_en(rd_en), .din(din),
    .dout(dout), .full(full), .empty(empty),
    .overflow(overflow), .underflow(underflow));

  always #5 clk = ~clk;

  //--------------------------------------------------------------------
  // Reference model: a circular queue plus the DUT's own acceptance rules.
  //--------------------------------------------------------------------
  reg [DATA_WIDTH-1:0] model [0:DEPTH-1];
  integer head = 0, tail = 0, cnt = 0;
  integer errors = 0, checks = 0;

  reg                   exp_valid = 0;    // a read was accepted last edge
  reg [DATA_WIDTH-1:0]  exp_data  = 0;    // data that read should return
  reg                   exp_ovf = 0, exp_udf = 0; // expected error pulses
  reg                   wr_acc, rd_acc;

  task check(input cond, input [255:0] what);
    begin
      checks = checks + 1;
      if (!cond) begin
        errors = errors + 1;
        if (errors <= 10)
          $display("  FAIL t=%0t: %0s (full=%b empty=%b ovf=%b udf=%b dout=%0d cnt=%0d)",
                   $time, what, full, empty, overflow, underflow, dout, cnt);
      end
    end
  endtask

  // Compare DUT outputs against the model on every posedge, then update
  // the model for the inputs sampled this edge (same timing as the DUT).
  always @(posedge clk) begin
    if (!rst) begin
      check(full      === (cnt == DEPTH), "full flag");
      check(empty     === (cnt == 0),     "empty flag");
      check(overflow  === exp_ovf,        "overflow pulse");
      check(underflow === exp_udf,        "underflow pulse");
      if (exp_valid) check(dout === exp_data, "read data/order");

      wr_acc  = wr_en && (cnt < DEPTH || rd_en);
      rd_acc  = rd_en && (cnt > 0);
      exp_ovf = wr_en && !wr_acc;
      exp_udf = rd_en && !rd_acc;
      exp_valid = rd_acc;
      if (rd_acc) begin exp_data = model[head]; head = (head + 1) % DEPTH; end
      if (wr_acc) begin model[tail] = din;      tail = (tail + 1) % DEPTH; end
      cnt = cnt + wr_acc - rd_acc;
    end
  end

  //--------------------------------------------------------------------
  // Drivers. Inputs change on negedge so they are stable at the posedge.
  //--------------------------------------------------------------------
  task step; begin @(negedge clk); end endtask

  task do_write(input [DATA_WIDTH-1:0] d);
    begin @(negedge clk); wr_en = 1; rd_en = 0; din = d; end
  endtask
  task do_read;
    begin @(negedge clk); wr_en = 0; rd_en = 1; end
  endtask
  task do_both(input [DATA_WIDTH-1:0] d);
    begin @(negedge clk); wr_en = 1; rd_en = 1; din = d; end
  endtask
  task idle;
    begin @(negedge clk); wr_en = 0; rd_en = 0; end
  endtask

  integer i;

  initial begin
    $dumpfile("wave/fifo.vcd");
    $dumpvars(0, fifo_tb);

    rst = 1; wr_en = 0; rd_en = 0; din = 0;
    repeat (2) @(negedge clk);
    rst = 0;

    // 1. fill to full, then one extra write -> overflow
    for (i = 0; i < DEPTH; i = i + 1) do_write(i[DATA_WIDTH-1:0]);
    do_write(8'hAA);          // rejected, overflow expected
    idle;

    // 2. drain to empty, then one extra read -> underflow
    for (i = 0; i < DEPTH; i = i + 1) do_read;
    do_read;                  // rejected, underflow expected
    idle;

    // 3. pointer wrap-around: partial fill past the DEPTH-1 boundary
    for (i = 0; i < DEPTH - 2; i = i + 1) do_write(i[DATA_WIDTH-1:0]);
    for (i = 0; i < DEPTH - 2; i = i + 1) do_read;
    do_write(8'h11); do_write(8'h22); do_write(8'h33);
    do_read; do_read; do_read;
    idle;

    // 4. simultaneous read/write while full (exercises write_ok on full)
    for (i = 0; i < DEPTH; i = i + 1) do_write(i[DATA_WIDTH-1:0]);
    for (i = 0; i < 8; i = i + 1) do_both((8'h40 + i));
    idle;

    // 5. randomised soak
    for (i = 0; i < SOAK_OPS; i = i + 1) begin
      @(negedge clk);
      wr_en = $random;
      rd_en = $random;
      din   = $random;
    end
    idle; idle;

    // let the final sampled operation be checked
    @(posedge clk); @(posedge clk);

    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else begin $display("TEST FAILED"); $finish(1); end
    $finish;
  end

  // watchdog
  initial begin #1000000; $display("TEST FAILED (timeout)"); $finish(1); end

endmodule
