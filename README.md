# UART-Transceiver-systemverilog
Synthesizable, parameterized UART Transceiver (TX &amp; RX) implemented in SystemVerilog (IEEE 1800) with loopback verification harness.
# Parameterized UART Transceiver (TX & RX) in SystemVerilog

A synthesizable, parameterized UART (Universal Asynchronous Receiver-Transmitter) core developed using SystemVerilog (IEEE 1800). The architecture integrates a full transmitter path, an asynchronous edge-detecting receiver, dynamic parity handling, and a loopback self-checking verification harness.

---

## Key Architectural Features

* **Configurable Data Bus Width:** Parametric bit-width definition via `#(parameter DATA_W = 8)`.
* **SystemVerilog Implementation Standards:**
  * Clean two-process FSM architectures utilizing `always_ff` for sequential transitions and `always_comb` with full default coverage to avoid latch inference.
  * State tracking defined with type-safe `typedef enum logic [2:0]`.
  * Net and port interconnects declared using explicit `logic` typing.
* **Transmitter (TX) Datapath:**
  * **Serializer:** LSB-first right-shifting register controlled by state machine enable strobes.
  * **Parity Generator:** Combinational block supporting Even Parity, Odd Parity, or Parity-Disabled transmission modes.
  * **Datapath MUX:** Low-latency multiplexer sequencing Start (0), Data, Parity, and Stop (1) intervals onto `o_tx`.
* **Receiver (RX) Datapath:**
  * **Edge Detection:** Single-stage edge detector capturing line fall events (`rx_fall`) to trigger frame processing.
  * **Deserializer (SIPO):** Serial-In Parallel-Out shift register assembling the incoming serial bits into parallel data words.
  * **Error Handling & Delivery:** Real-time framing and parity checking. Implements a flag-and-deliver scheme, issuing `o_valid` alongside `o_frame_err` and `o_parity_err` indicators.

---

## System Architecture

```text
               +-------------------------------------------------------+
               |                  UART TRANSCEIVER                     |
               |                                                       |
               |  +--------------------+       +--------------------+  |
   i_data ---->|  |                    |       |                    |  |
  i_valid ---->|  |      UART_TX       |------>|      UART_RX       |----> o_data
   o_busy <----|  | (Serializer + MUX) | o_tx  |  (Edge + SIPO)     |----> o_valid
               |  +--------------------+       +--------------------+  |
               |             ^                            ^            |
               |             |                            |            |
               |         [TX FSM]                      [RX FSM]        |
               +-------------------------------------------------------+
Repository Structure
├── rtl/
│   ├── uart_tx.sv          # Transmitter top-level wrapper
│   ├── serializer.sv       # TX parallel-to-serial conversion block
│   ├── parity_calc.sv      # Shared combinational parity generator
│   ├── mux_4_1.sv          # TX line output multiplexer
│   ├── fsm_tx.sv           # TX state sequence controller
│   ├── uart_rx.sv          # Receiver top-level wrapper
│   ├── edge_detec.sv       # RX start bit edge detector
│   ├── sipo.sv             # RX serial-to-parallel conversion block
│   └── FSM_rx.sv           # RX state sequence controller
├── tb/
│   ├── uart_tx_tb.sv       # Unit-level stimulus bench for TX
│   └── uart_grading_tb.sv  # Loopback self-checking grading testbench
├── docs/
│   └── UART_TX_RX_project.pdf # Architectural slides and project report
└── README.md
State Machine Operations
​Transmitter Controller (fsm_tx)
​IDLE: Keeps line at Logic 1. Transitions to START upon receiving i_valid.
​START: Drives Start Bit (Logic 0) onto the serial line.
​DATA: Enables shift operations across DATA_W clock ticks.
​PARITY: Transmits calculated parity bit if enabled; otherwise bypassed.
​STOP: Asserts Stop Bit (Logic 1), clears busy flag, and returns to IDLE.
​Receiver Controller (FSM_rx)
​IDLE: Awaits asynchronous start transition flagged by rx_fall.
​DATA: Enables sipo deserialization across DATA_W clock cycles.
​PARITY: Samples incoming parity bit into dedicated register.
​STOP: Evaluates framing integrity (!i_rx), generates status flags (o_valid, o_parity_err, o_frame_err), and resets to IDLE.
Simulation Guide (ModelSim / QuestaSim)
# Map environment
vlib work
vmap work work

# Compile SystemVerilog RTL and Testbench
vlog -sv rtl/*.sv
vlog -sv tb/uart_grading_tb.sv

# Invoke simulation
vsim -voptargs=+acc work.uart_grading_tb

# Run simulation
add wave -position insertpoint sim:/uart_grading_tb/*
run -all
