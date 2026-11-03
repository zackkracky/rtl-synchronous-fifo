#!/usr/bin/env bash
# Pilot A runner. Serial on purpose: one xrun licence seat at a time.
#   ./scripts/run_pilot.sh compile tb3        # elaborate only, for the fix loop
#   ./scripts/run_pilot.sh full    tb1 tb2 .. # golden (with coverage) + 5 mutants
# Each tbs/tbN/ holds fifo_tb_pkg.sv, tb_top.sv, files.f, meta.txt.
set -u
cd "$(dirname "$0")/.."
MODE=${1:?compile|full}; shift
TIMEOUT=${TIMEOUT:-300}  # s per run; a hang counts as a kill, logged as timeout
mkdir -p logs

xr() {  # xr <run_name> <rtl_file> <tbdir> [extra xrun args...]
  local run=$1 rtl=$2 tb=$3; shift 3
  timeout "$TIMEOUT" xrun -64bit -sv -uvm -timescale 1ns/1ps -top tb_top \
    "$rtl" ref/fifo_ref_cov.sv -F "tbs/$tb/files.f" \
    -xmlibdirname "xcelium.d/$run" -svseed 1 \
    +UVM_TESTNAME=fifo_test +UVM_VERBOSITY=UVM_LOW \
    -l "logs/$run.log" "$@" >/dev/null 2>&1
  local rc=$?
  echo "EXIT $rc" > "logs/$run.status"
  printf '%-16s exit=%s\n' "$run" "$rc"
}

[ -d mutants ] && ls mutants/fifo_m*.v >/dev/null 2>&1 \
  || python3 -I mutants/make_mutants.py rtl/fifo.v mutants/

for tb in "$@"; do
  [ -f "tbs/$tb/files.f" ] || { echo "skip $tb: no tbs/$tb/files.f"; continue; }
  case $MODE in
    compile) xr "${tb}_compile" rtl/fifo.v "$tb" -elaborate ;;
    full)
      xr "${tb}_golden" rtl/fifo.v "$tb" \
         -coverage all -covdut fifo -covworkdir cov_work \
         -covscope pilotA -covtest "${tb}_golden" -covoverwrite
      for m in mutants/fifo_m*.v; do
        id=$(basename "$m" .v); id=${id#fifo_}
        xr "${tb}_${id}" "$m" "$tb"
      done ;;
    *) echo "mode must be compile or full"; exit 2 ;;
  esac
done
