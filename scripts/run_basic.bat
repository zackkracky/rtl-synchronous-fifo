@echo off

iverilog -o sim/fifo_sim rtl/fifo.v tb/fifo_tb.v

if errorlevel 1 (
    echo Compilation Failed.
    pause
    exit /b
)

vvp sim/fifo_sim

gtkwave wave/fifo.vcd