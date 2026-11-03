# Pilot A formal column: prove 5 spec properties on the golden FIFO, then
# show which mutants each property catches. Run from the pilotA/ root:
#   jg -batch -tcl formal/pilotA_fpv.tcl -proj formal/jgproject |& tee logs/pilotA_jg.log
# Introspection calls are wrapped in catch: their API moves between releases.

set DUTS {rtl/fifo.v mutants/fifo_m1.v mutants/fifo_m2.v mutants/fifo_m3.v mutants/fifo_m4.v mutants/fifo_m5.v}
file mkdir formal/out
set csv [open formal/out/pilotA_formal.csv w]
puts $csv "dut,property,status,wall_s"

foreach d $DUTS {
  set name [file rootname [file tail $d]]
  clear -all
  analyze -sv12 $d
  analyze -sv12 formal/fifo_formal.sv
  elaborate -top fifo_formal                      ;# DEPTH 4 by default
  clock clk
  reset -expression {rst}
  set t0 [exec date +%s]                          ;# Jasper's 'clock' shadows Tcl's
  prove -all -time_limit 5m
  set dt [expr {[exec date +%s] - $t0}]
  puts "=== $name : wall ${dt}s"
  report -summary
  if {[catch {
        foreach p [get_property_list -include {type {assert cover}}] {
          puts $csv "$name,$p,[get_status $p],$dt"
        }
      } err]} {
    puts $csv "$name,INTROSPECTION_FAILED,see log,$dt"
    puts "introspection failed ($err); read statuses from report -summary above"
  }
}
close $csv
exit
