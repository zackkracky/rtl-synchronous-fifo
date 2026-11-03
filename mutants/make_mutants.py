#!/usr/bin/env python3
"""Generate the 5 Pilot-A FIFO mutants from rtl/fifo.v. Stdlib only, no sudo.

Each mutant is one exact text replacement that must match exactly once.
Usage: python3 -I mutants/make_mutants.py rtl/fifo.v mutants/
"""
import pathlib, sys

MUTANTS = [  # (id, class, old, new)
    ("m1", "flag: full off-by-one",
     "assign full = (count == DEPTH);",
     "assign full = (count == DEPTH-1);"),
    ("m2", "pointer: early write-pointer wrap",
     "assign wr_ptr_next = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;",
     "assign wr_ptr_next = (wr_ptr == DEPTH-2) ? 0 : wr_ptr + 1;"),
    ("m3", "control: write dropped on simultaneous R/W when full",
     "assign write_ok = wr_en && (!full || rd_en);",
     "assign write_ok = wr_en && !full;"),
    ("m4", "reset: count resets to 1 (empty wrong after reset)",
     "count <= 0;",
     "count <= 1;"),
    ("m5", "datapath: MSB of din dropped on write",
     "memory[wr_ptr] <= din;",
     "memory[wr_ptr] <= din[DATA_WIDTH-2:0];"),
]

def main(src: str, out: str) -> None:
    text = pathlib.Path(src).read_text()
    outdir = pathlib.Path(out); outdir.mkdir(parents=True, exist_ok=True)
    for mid, cls, old, new in MUTANTS:
        n = text.count(old)
        if n != 1:  # guard: RTL drifted, mutant would be silently wrong
            sys.exit(f"{mid}: expected 1 match, found {n}: {old!r}")
        (outdir / f"fifo_{mid}.v").write_text(
            f"// MUTANT {mid}: {cls}\n// - {old}\n// + {new}\n" + text.replace(old, new))
        print(f"{mid}  {cls}")

if __name__ == "__main__":
    main(*sys.argv[1:3])
