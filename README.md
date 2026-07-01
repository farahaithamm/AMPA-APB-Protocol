# APB-Protocol

A Verilog implementation of the **AMBA APB (Advanced Peripheral Bus)** protocol, with SystemVerilog testbenches and ModelSim/Questa simulation scripts. The design follows the ARM AMBA APB Protocol Specification ([IHI0024C](IHI0024C_amba_apb_protocol_spec.pdf)).

## Overview

This project implements a minimal APB interconnect with one master and two memory-mapped slaves. The master drives standard APB signals (`PADDR`, `PSEL`, `PENABLE`, `PWRITE`, `PWDATA`, `PSTRB`) and handles the IDLE → SETUP → ACCESS state sequence. Each slave provides a 128-word register file with byte strobing and asserts `PSLVERR` for out-of-range addresses.

```
                    ┌─────────────┐
  User interface    │ APB_MASTER  │
  (addr, sel,       │             │──── PADDR, PSEL[1:0], PENABLE,
   transfer, ...)   │             │     PWRITE, PWDATA, PSTRB
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
        ┌─────▼─────┐             ┌─────▼─────┐
        │ APB_SLAVE │             │ APB_SLAVE │
        │  slave0   │             │  slave1   │
        └───────────┘             └───────────┘
```

## Project Structure

```
APB-Protocol/
├── rtl/
│   ├── apb_master.v      # APB master FSM (IDLE / SETUP / ACCESS)
│   ├── apb_slave.v       # Memory-mapped slave with PSTRB and PSLVERR
│   └── apb_wrapper.v     # Top-level: 1 master + 2 slaves
├── tb/
│   ├── apb_wrapper_tb.sv # Integration tests (master + dual slaves)
│   └── apb_slave_tb.sv   # Standalone slave tests (random + directed)
├── sim/
│   ├── run.do            # Wrapper-level simulation script
│   ├── run_slave.do      # Slave-only simulation script
│   └── mem.dat           # Initial memory contents (hex)
└── IHI0024C_amba_apb_protocol_spec.pdf
```

## Modules

### `APB_MASTER`

Parameterized APB master with a three-state FSM:

| State  | Description                                      |
|--------|--------------------------------------------------|
| IDLE   | Waits for `transfer`; moves to SETUP on request  |
| SETUP  | Asserts address/control; enters ACCESS next cycle |
| ACCESS | Asserts `PENABLE`; completes when `PREADY` is high |

The master exposes a simple user interface (`addr`, `sel`, `transfer`, `wr_en`, `wdata`, `strb`) and drives `PSEL[1:0]` to select slave 0 or slave 1.

### `APB_SLAVE`

Memory-mapped slave backed by a `MEM_DEPTH`-word array (default 128). Features:

- **Byte strobes** (`PSTRB`) for partial-word writes
- **`PREADY`** asserted when selected and enabled
- **`PSLVERR`** asserted when `PADDR >= MEM_DEPTH`

### `APB_WRAPPER`

Integrates one `APB_MASTER` with two `APB_SLAVE` instances. The `sel` input routes the active slave's `PREADY`, `PRDATA`, and `PSLVERR` back to the master.

## Parameters

All RTL modules share these defaults:

| Parameter    | Default | Description              |
|--------------|---------|--------------------------|
| `ADDR_WIDTH` | 32      | Address bus width        |
| `DATA_WIDTH` | 32      | Data bus width           |
| `MEM_DEPTH`  | 128     | Slave memory depth       |

## Simulation

### Prerequisites

- [ModelSim](https://www.intel.com/content/www/us/en/software-kit/750666/modelsim-intel-fpgas-standard-edition-software-version-18-1.html) or [Questa Sim](https://www.intel.com/content/www/us/en/software-kit/750811/questa-intel-fpgas-standard-edition-software-version-2021-2.html)

### Wrapper test (master + dual slaves)

From the `sim/` directory:

```tcl
cd sim
vsim -do run.do
```

Before running, ensure `run.do` compiles all required RTL files. A working compile sequence is:

```tcl
vlib work
vlog ../rtl/apb_master.v ../rtl/apb_slave.v ../rtl/apb_wrapper.v ../tb/apb_wrapper_tb.sv
vsim -voptargs=+acc work.APV_WRAPPER_tb
add wave -position insertpoint sim:/APV_WRAPPER_tb/dut/*
run -all
```

Run from `sim/` so that `mem.dat` is found by `$readmemh` in the testbench.

### Slave-only test

```tcl
cd sim
vsim -do run_slave.do
```

Or manually:

```tcl
vlib work
vlog ../rtl/apb_slave.v ../tb/apb_slave_tb.sv
vsim -voptargs=+acc work.APV_SLAVE_tb
add wave -r sim:/APV_SLAVE_tb/dut/*
run -all
```

### Test coverage

**`apb_wrapper_tb.sv`** exercises:

- Partial-word writes and reads on slave 0 and slave 1
- `PSLVERR` on out-of-range write and read
- Back-to-back write-then-read (`write_read_data`) without deasserting `transfer`

**`apb_slave_tb.sv`** exercises:

- Random write, read, and combined read/write sequences against a reference model
- Out-of-range address error handling

## User Interface Signals

| Signal     | Direction | Description                                      |
|------------|-----------|--------------------------------------------------|
| `PCLK`     | Input     | APB clock                                        |
| `PRESETn`  | Input     | Active-low reset                                 |
| `addr`     | Input     | Target address                                   |
| `sel`      | Input     | Slave select (`0` = slave0, `1` = slave1)        |
| `transfer` | Input     | Start or hold an APB transfer                    |
| `wr_en`    | Input     | `1` = write, `0` = read                          |
| `wdata`    | Input     | Write data                                       |
| `strb`     | Input     | Byte strobe (one bit per byte lane)              |
| `OUTDATA`  | Output    | Read data (valid when transfer completes)        |

