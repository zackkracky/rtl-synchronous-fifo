// Reference functional coverage, bound into every run.
// Same 6-bin yardstick for every LLM testbench; the LLM's own covergroups are
// ignored, so no TB grades itself against targets it wrote (HAVEN's soft spot).
// Prints one parseable REFCOV line at end of sim; no IMC needed for this metric.
module fifo_ref_cov #(parameter int DEPTH = 16,
                      parameter int ADDR_WIDTH = $clog2(DEPTH)) (
  input logic clk, rst, wr_en, rd_en, full, empty,
  input logic [ADDR_WIDTH:0]   count,
  input logic [ADDR_WIDTH-1:0] wr_ptr
);
  covergroup cg @(posedge clk iff !rst);
    option.per_instance = 1;
    cp_full    : coverpoint full                              { bins hit = {1}; }
    cp_drain   : coverpoint count                             { bins hit = (1 => 0); }          // emptied after use
    cp_simul   : coverpoint (wr_en && rd_en && !empty && !full) { bins hit = {1}; }
    cp_wrap    : coverpoint wr_ptr                            { bins hit = (DEPTH-1 => 0); }
    cp_afull   : coverpoint count                             { bins hit = {DEPTH-1}; }
    cp_aempty  : coverpoint count                             { bins hit = {1}; }
  endgroup
  cg cg_i = new();

  final $display("REFCOV total=%0.1f full=%0.0f drain=%0.0f simul=%0.0f wrap=%0.0f afull=%0.0f aempty=%0.0f",
    cg_i.get_inst_coverage(),
    cg_i.cp_full.get_inst_coverage(),  cg_i.cp_drain.get_inst_coverage(),
    cg_i.cp_simul.get_inst_coverage(), cg_i.cp_wrap.get_inst_coverage(),
    cg_i.cp_afull.get_inst_coverage(), cg_i.cp_aempty.get_inst_coverage());
endmodule

// .* picks up clk, rst, wr_en, rd_en, full, empty, count, wr_ptr from fifo's scope
bind fifo fifo_ref_cov #(.DEPTH(DEPTH)) u_ref_cov (.*);
