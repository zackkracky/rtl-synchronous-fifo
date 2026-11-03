# Mutation analysis of this FIFO: formal column done, LLM-generated UVM column pending

Goal: measure how well different checkers catch known bugs in this FIFO. Five hand-written mutants are the bug set. Two kinds of checker are compared:

1. **Formal properties** proven in JasperGold. Done, see `formal/RESULTS.md`.
2. **LLM-generated UVM testbenches**, each scored on compile success, code coverage, a fixed reference functional coverage, mutants killed out of 5, and false failures on the unmodified design. Not run yet.

Why mutation score and not coverage alone: coverage says how much of the design the stimulus reached. It says nothing about whether the scoreboard compares the right things. Two of the five mutants (m2, m5) are only visible to a data-integrity check.

## Layout
| Path | Content |
|---|---|
| `rtl/fifo.v` | The design under test, unchanged |
| `mutants/make_mutants.py` | Generates the 5 mutants. Each is one exact text replacement and must match exactly once |
| `mutants/fifo_m1.v` .. `fifo_m5.v` | The generated mutants, committed so no Python is needed on a lab machine |
| `ref/fifo_kill_check.v` | Plain-Verilog self-checking testbench. Its only job is proving every mutant is killable, i.e. not equivalent |

> Not to be confused with `tb/fifo_tb_self.v`, the repo's general self-checking regression testbench. `ref/fifo_kill_check.v` exists only to prove the five mutants are non-equivalent; `tb/fifo_tb_self.v` is the everyday pass/fail check on the unmodified FIFO.
| `ref/fifo_ref_cov.sv` | 6-bin reference covergroup bound into the DUT. Same yardstick for every testbench |
| `formal/fifo_formal.sv` | 5 formal properties + 2 covers, written from the spec text |
| `formal/pilotA_fpv.tcl` | JasperGold script: golden design, then each mutant |
| `formal/RESULTS.md` | Formal results table |
| `prompts/` | Zero-shot and one-shot prompts, frozen before generation |
| `scripts/run_pilot.sh`, `scripts/score.py` | Serial xrun runner and log scorer |
| `tbs/tbN/` | One folder per generated testbench (created when the runs happen) |

## Mutants
| ID | Class | Change |
|---|---|---|
| m1 | flag | `full` asserted at count == DEPTH-1 |
| m2 | pointer | write pointer wraps at DEPTH-2 |
| m3 | control | write dropped on simultaneous read/write when full |
| m4 | reset | count resets to 1 |
| m5 | datapath | MSB of `din` dropped on write |

All five are killed by `ref/fifo_kill_check.v`, so none is equivalent and the denominator is 5. Reproduce with Icarus Verilog:

    python3 -I mutants/make_mutants.py rtl/fifo.v mutants/
    for f in rtl/fifo.v mutants/fifo_m*.v; do iverilog -g2012 -o k.vvp ref/fifo_kill_check.v $f && vvp -n k.vvp | grep -E 'RESULT|ERROR' | head -1; done

## Formal column
Five properties, black-box (ports only), written from the specification text:

- `f_full`, `f_empty`: flags match a spec occupancy model.
- `f_ovf`, `f_udf`: overflow and underflow pulse exactly one cycle after a rejected write or read.
- `f_data`: an arbitrary accepted write comes out in order with the same data (a free input picks which write to track).
- Covers `w_full`, `w_data` guard against vacuous proofs.

Run from the repo root:

    jg -batch -tcl formal/pilotA_fpv.tcl -proj formal/jgproject

Result table and caveats: `formal/RESULTS.md`.

## Simulation column: protocol
Not run yet. Fixed in advance so every testbench is treated identically:

1. Same prompt per column of the grid (`prompts/`), fresh chat each time, DUT source pasted unchanged.
2. Output saved to `tbs/tbN/` exactly as returned.
3. On a compile error, only the first compiler error lines go back to the same chat; at most 3 rounds, counted per testbench. No hand edits. If a hand edit happens, it is recorded and reported.
4. Runs are serial (one licence seat): `scripts/run_pilot.sh full tbN`, then `python3 -I scripts/score.py`.

Scoring rules:

- **Compiles:** no xmvlog/xmelab error within the fix budget.
- **False fail:** UVM_ERROR or UVM_FATAL, or no UVM report summary, on the unmodified FIFO. That testbench's kill count is then reported as n/a.
- **Killed:** on a mutant, UVM_ERROR or UVM_FATAL, a simulator error, a non-zero exit or a timeout.
- **Reference functional coverage:** the `REFCOV` line from the unmodified run. Bins: full, drain to empty, simultaneous read/write, write-pointer wrap, almost full, almost empty. A testbench's own covergroups are ignored.
