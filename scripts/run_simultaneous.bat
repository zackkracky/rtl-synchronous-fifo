@echo off

cd /d "%~dp0.."

iverilog -o sim/fifo_simultaneous rtl/fifo.v tb/fifo_tb_simultaneous.v

if errorlevel 1 (
    pause
    exit /b
)

vvp sim/fifo_simultaneous
gtkwave wave/fifo_simulataneous.vcd
