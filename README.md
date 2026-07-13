# Parameterized Synchronous FIFO (Verilog RTL)

![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog-green)
![Waveform](https://img.shields.io/badge/Waveform-GTKWave-orange)
![Status](https://img.shields.io/badge/Project-Completed-success)

---

## Overview

This project implements a **parameterized synchronous FIFO (First-In, First-Out)** in Verilog.

The FIFO is configurable in both **data width** and **memory depth**, making it reusable across different digital designs. It supports synchronous read/write operations, circular buffer implementation, status flag generation, and error detection through overflow and underflow flags.

The project was developed as part of my RTL Design & Verification learning roadmap.

---

## Features

- Parameterized DATA_WIDTH
- Parameterized DEPTH
- Circular buffer implementation
- Synchronous read/write
- Full flag
- Empty flag
- Overflow detection
- Underflow detection
- Simultaneous read/write support
- Industry-style RTL organization
- Comprehensive verification testbenches
- GTKWave waveform verification

---

## Block Diagram


<p align="center">
  <img src="assets/fifo_block_diagram.png" width="500">
</p>

## Internal Architecture

The FIFO uses a circular buffer architecture.

<p align="center">
  <img src="assets/Internal Architecture.png" width="800">
</p>

### Internal Components

| Component | Description |
|-----------|-------------|
| memory[] | Stores FIFO data |
| wr_ptr | Points to next write location |
| rd_ptr | Points to next read location |
| count | Tracks number of valid entries |
| full | Asserted when FIFO is full |
| empty | Asserted when FIFO is empty |
| overflow | Indicates illegal write attempt |
| underflow | Indicates illegal read attempt |

---

## Project Structure

```

FIFO/
│
├── rtl/
│   └── fifo.v
│
├── tb/
│   ├── fifo_tb.v
│   ├── fifo_overflow_tb.v
│   ├── fifo_underflow_tb.v
│   ├── fifo_simultaneous_tb.v
│   └── fifo_wraparound_tb.v
│
├── scripts/
│   ├── run_basic.bat
│   ├── run_overflow.bat
│   ├── run_underflow.bat
│   ├── run_simultaneous.bat
│   └── run_wraparound.bat
│
├── docs/
│
├── wave/
│
├── sim/
│
├── README.md
├── LICENSE
└── .gitignore

```

---

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| DATA_WIDTH | 8 | Width of each FIFO entry |
| DEPTH | 16 | Number of entries in FIFO |

---

## FIFO Interface

### Inputs

| Signal | Description |
|----------|-------------|
| clk | System clock |
| rst | Synchronous reset |
| wr_en | Write enable |
| rd_en | Read enable |
| din | Input data |

### Outputs

| Signal | Description |
|----------|-------------|
| dout | Output data |
| full | FIFO full flag |
| empty | FIFO empty flag |
| overflow | Illegal write detected |
| underflow | Illegal read detected |

---

## Verification

The FIFO has been verified using multiple directed testbenches.

| Test | Description | Status |
|------|-------------|:------:|
| Basic Read/Write | Verify FIFO ordering | ✅ |
| Overflow | Verify writes to full FIFO | ✅ |
| Underflow | Verify reads from empty FIFO | ✅ |
| Simultaneous Read/Write | Verify concurrent operations | ✅ |
| Pointer Wrap-around | Verify circular buffer | ✅ |

---

## Simulation

Compile:

```bash
iverilog -o sim/fifo_basic rtl/fifo.v tb/fifo_basic_tb.v
```

Run:

```bash
vvp sim/fifo_basic
```

Open GTKWave:

```bash
gtkwave wave/fifo_basic.vcd
```

Or simply execute

```

scripts/run_basic.bat

```

---

## Example Waveforms

Check the wave sub folder.

## Design Decisions

### Circular Buffer

Instead of shifting memory after every read, the FIFO uses two pointers:

- Write Pointer (`wr_ptr`)
- Read Pointer (`rd_ptr`)

This allows all operations to complete in **O(1)** hardware complexity.

---

### Count Register

The FIFO occupancy is tracked using a count register.

```

count = writes − reads

```

Using the count register allows straightforward generation of:

- Full flag
- Empty flag

without comparing pointer values.

---

### Simultaneous Read/Write

When both `wr_en` and `rd_en` are asserted during the same clock cycle:

- Read operation succeeds
- Write operation succeeds
- Both pointers advance
- Count remains unchanged

This matches expected synchronous FIFO behavior.

---

## Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- Visual Studio Code
- Git
- GitHub

---

## Future Improvements

- SystemVerilog implementation
- Self-checking testbench
- Assertions (SVA)
- Randomized verification
- UVM verification environment
- Asynchronous FIFO implementation
- Continuous Integration (GitHub Actions)

---

## Lessons Learned

Through this project I gained practical experience with:

- RTL Design
- Parameterized hardware modules
- Circular buffer implementation
- Pointer-based memory management
- Synchronous sequential logic
- Testbench development
- Waveform debugging using GTKWave
- Directed verification methodology

---

## Author

**Arnav Battu**

Electronics Engineering (VLSI Design)

Chaitanya Bharathi Institute of Technology (CBIT)

GitHub: https://github.com/zackkracky

