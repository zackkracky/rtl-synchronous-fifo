@echo off

cd /d "%~dp0.."

iverilog -o sim/fifo_wraparound rtl/fifo.v tb/fifo_tb_wraparound.v

if errorlevel 1 (
    pause
    exit /b
)

vvp sim/fifo_wraparound
gtkwave wave/fifo_wraparound.vcd
