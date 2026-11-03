# Formal results

Date: 28 Oct 2026. Tool: JasperGold (Jasper Apps 2022.09p001), FPV licence. Design: `rtl/fifo.v`, DEPTH 4, DATA_WIDTH 8. Properties: `formal/fifo_formal.sv`. Script: `formal/pilotA_fpv.tcl`.

P = proven (unbounded). C = counterexample found.

| Design | f_full | f_empty | f_ovf | f_udf | f_data | Killed | Shortest counterexample |
|---|---|---|---|---|---|---|---|
| unmodified | P | P | P | P | P | - | - |
| m1 full off-by-one | C | C | C | C | C | yes | 4 cycles (f_full) |
| m2 early write-pointer wrap | P | P | P | P | C | yes | 6 cycles (f_data) |
| m3 write dropped, full + read | C | C | C | C | C | yes | 6 cycles (f_full) |
| m4 count resets to 1 | C | C | C | C | C | yes | 1 cycle (f_empty) |
| m5 MSB of din dropped | P | P | P | P | C | yes | 3 cycles (f_data) |

- Mutants killed: 5 of 5.
- Unmodified design: all five assertions proven, slowest f_data in 0.55 s. Wall time about 1 s per design.
- Both cover properties are reachable (`w_data` in 3 cycles, `w_full` in 5), so the proofs are not vacuous.
- m2 and m5 are caught only by the data-integrity property `f_data`; the four flag and occupancy properties stay proven on them.

## Caveats
- The properties were written from the specification text, but after the mutant list existed.
- Formal runs at DEPTH 4. Simulation testbenches use DEPTH 16.
- The five mutants were chosen by hand. This is a pilot, not a benchmark.
- Only the table is published. Raw tool logs and the `jgproject/` directory are not.
