// Pilot A formal baseline: 5 properties written from the FIFO spec (prompt text),
// not from the RTL. Black-box: only DUT ports are observed.
// Same file runs in JasperGold (concurrent SVA) and in Yosys (-DYOSYS, immediate).
module fifo_formal #(parameter int DATA_WIDTH = 8, parameter int DEPTH = 4) (
  input logic clk, rst, wr_en, rd_en,
  input logic [DATA_WIDTH-1:0] din,
  input logic pick                      // free: which accepted write to track
);
  localparam int AW = $clog2(DEPTH);
  logic [DATA_WIDTH-1:0] dout;
  logic full, empty, overflow, underflow;

  fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (.*);

  // spec model: occupancy and acceptance rules
  logic [AW:0] occ;
  wire wr_acc = wr_en && (occ < DEPTH || rd_en);          // spec: !full || rd_en
  wire rd_acc = rd_en && (occ > 0);                        // spec: !empty
  logic exp_ovf, exp_udf;
  always_ff @(posedge clk)
    if (rst) begin occ <= '0; exp_ovf <= 0; exp_udf <= 0; end
    else begin
      occ     <= occ + wr_acc - rd_acc;
      exp_ovf <= wr_en && !wr_acc;
      exp_udf <= rd_en && !rd_acc;
    end

  // data integrity: track one arbitrary accepted write through the queue
  logic armed, done, chk;
  logic [AW:0] ahead;                                      // items in front of it
  logic [DATA_WIDTH-1:0] tag;
  always_ff @(posedge clk)
    if (rst) begin armed <= 0; done <= 0; chk <= 0; ahead <= '0; tag <= '0; end
    else begin
      chk <= 0;
      if (armed && rd_acc) begin
        if (ahead == 0) begin armed <= 0; chk <= 1; end  // it leaves now
        else ahead <= ahead - 1;
      end
      if (!armed && !done && wr_acc && pick) begin
        armed <= 1; done <= 1; tag <= din;
        ahead <= occ - rd_acc;
      end
    end

  wire c_full  = full  == (occ == DEPTH);
  wire c_empty = empty == (occ == 0);
  wire c_ovf   = overflow  == exp_ovf;
  wire c_udf   = underflow == exp_udf;
  wire c_data  = !chk || dout == tag;

`ifdef YOSYS
  logic past_valid = 0;
  always_ff @(posedge clk) past_valid <= 1;
  always_comb if (!past_valid) assume (rst);              // start in reset
  always_comb if (past_valid && !rst) begin
    f_full:  assert (c_full);
    f_empty: assert (c_empty);
    f_ovf:   assert (c_ovf);
    f_udf:   assert (c_udf);
    f_data:  assert (c_data);
  end
`else
  f_full:  assert property (@(posedge clk) disable iff (rst) c_full);
  f_empty: assert property (@(posedge clk) disable iff (rst) c_empty);
  f_ovf:   assert property (@(posedge clk) disable iff (rst) c_ovf);
  f_udf:   assert property (@(posedge clk) disable iff (rst) c_udf);
  f_data:  assert property (@(posedge clk) disable iff (rst) c_data);
  // reachability witnesses: a proof that never reaches these is vacuous
  w_full:  cover property (@(posedge clk) disable iff (rst) full && rd_en && wr_en);
  w_data:  cover property (@(posedge clk) disable iff (rst) chk);
`endif
endmodule
