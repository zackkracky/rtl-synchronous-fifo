@echo off

cd /d "%~dp0.."

iverilog -o sim/fifo_overflow rtl/fifo.v tb/fifo_tb_overflow.v

if errorlevel 1 (
    pause
    exit /b
)

vvp sim/fifo_overflow
gtkwave wave/fifo_overflow.vcd