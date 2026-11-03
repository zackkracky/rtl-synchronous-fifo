#!/usr/bin/env python3
"""Score Pilot A logs into results.csv and results.md. Stdlib only.

Golden run defines validity: a TB that errors on the unmodified FIFO is a
false fail, and its mutant 'kills' are reported n/a (cannot be told apart
from its own noise). Kill = UVM_ERROR/UVM_FATAL > 0, simulator *E/*F,
non-zero exit, or timeout (exit 124).
Usage: python3 -I scripts/score.py tb1 tb2 ...
"""
import csv, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOGS = ROOT / "logs"
MUTS = ["m1", "m2", "m3", "m4", "m5"]

def last_int(pat, text):
    m = re.findall(pat, text)
    return int(m[-1]) if m else None

def parse(run):
    log = LOGS / f"{run}.log"
    st = LOGS / f"{run}.status"
    if not log.exists():
        return {"ran": False}
    t = log.read_text(errors="replace")
    rc = int(st.read_text().split()[1]) if st.exists() else None
    return {
        "ran": True, "rc": rc,
        "compile_err": bool(re.search(r"^xm(vlog|elab): \*[EF],", t, re.M)),
        "sim_err": bool(re.search(r"^xmsim: \*[EF],", t, re.M)),
        "summary": "UVM Report Summary" in t,
        "uvm_err": last_int(r"UVM_ERROR\s*:\s*(\d+)", t),
        "uvm_fatal": last_int(r"UVM_FATAL\s*:\s*(\d+)", t),
        "refcov": (re.search(r"REFCOV total=([\d.]+)", t) or [None, None])[1],
    }

def failed(r):  # any failure signal on a run that compiled
    return (r["rc"] not in (0, None) or r["sim_err"]
            or (r["uvm_err"] or 0) > 0 or (r["uvm_fatal"] or 0) > 0
            or not r["summary"])

def meta(tb):
    p = ROOT / "tbs" / tb / "meta.txt"
    kv = {}
    if p.exists():
        for line in p.read_text().splitlines():
            if "=" in line:
                k, v = line.split("=", 1); kv[k.strip()] = v.strip()
    return kv

def score(tb):
    md, g = meta(tb), parse(f"{tb}_golden")
    row = {"tb": tb, "model": md.get("model", "?"), "prompt": md.get("prompt", "?"),
           "fix_iters": md.get("fix_iters", "?"), "human_edits": md.get("human_edits", "?"),
           "code_cov": md.get("code_cov", "")}
    if not g["ran"] or g["compile_err"]:
        row.update(compiles="N", false_fail="-", ref_cov="-", killed="-", kill_set="-")
        return row
    row["compiles"] = "Y"
    row["ref_cov"] = g["refcov"] or "?"
    if failed(g):
        row.update(false_fail="Y", killed="n/a", kill_set="n/a")
        return row
    row["false_fail"] = "N"
    kills = []
    for m in MUTS:
        r = parse(f"{tb}_{m}")
        if r["ran"] and not r["compile_err"] and failed(r):
            kills.append(m + ("(t/o)" if r["rc"] == 124 else ""))
    row["killed"] = f"{len(kills)}/5"
    row["kill_set"] = " ".join(kills) or "none"
    return row

def main(tbs):
    rows = [score(tb) for tb in tbs]
    cols = ["tb", "model", "prompt", "compiles", "fix_iters", "human_edits",
            "code_cov", "ref_cov", "killed", "kill_set", "false_fail"]
    with open(ROOT / "results.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols); w.writeheader(); w.writerows(rows)
    hdr = ["TB", "Model", "Prompt", "Compiles", "Fix iters", "Human edits",
           "Code cov %", "Ref func cov %", "Mutants killed", "Which", "False fail"]
    lines = ["| " + " | ".join(hdr) + " |", "|" + "---|" * len(hdr)]
    lines += ["| " + " | ".join(str(r[c]) for c in cols) + " |" for r in rows]
    (ROOT / "results.md").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))

if __name__ == "__main__":
    main(sys.argv[1:] or sorted(p.name for p in (ROOT / "tbs").glob("tb*")))
