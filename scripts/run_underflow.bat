@echo off

cd /d "%~dp0.."

iverilog -o sim/fifo_underflow rtl/fifo.v tb/fifo_tb_underflow.v

if errorlevel 1 (
    pause
    exit /b
)

vvp sim/fifo_underflow
gtkwave wave/fifo_underflow.vcd