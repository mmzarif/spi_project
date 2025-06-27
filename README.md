# SPI Slave - SystemVerilog

This repository contains a simple SPI slave implementation in SystemVerilog that supports **single-byte (8-bit)** SPI communication. It is designed to work with SPI Mode 0 (CPOL = 0, CPHA = 0), and can be simulated using ModelSim and synthesized in Quartus.

## 📦 Features

- SPI slave with:
  - 8-bit shift-in on `MOSI`
  - 8-bit shift-out on `MISO`
  - Finite State Machine (FSM) control
  - `done` signal indicates a full byte received
- Edge detection of `SCLK` for proper timing
- Works with external SPI master (e.g., Arduino, STM32)

## 🔧 Files

- `spi_slave.sv` — Main RTL module
- `spi_slave_tb.sv` — Testbench (ModelSim compatible)
- `spi_slave_wave.do` — Optional waveform script for ModelSim

## 🔌 SPI Interface

| Signal | Direction | Description                  |
|--------|-----------|------------------------------|
| `clk`  | Input     | System clock                 |
| `rst`  | Input     | Active-high reset            |
| `cs`   | Input     | Chip select (active low)     |
| `sclk` | Input     | SPI clock from master        |
| `mosi` | Input     | Master Out, Slave In         |
| `miso` | Output    | Master In, Slave Out         |
| `done` | Output    | High when 8 bits are received|
| `received_data` | Output | Received byte on MOSI |

## 🧪 Simulation

To simulate using ModelSim:
```tcl
vsim work.spi_slave_tb
do spi_slave_wave.do

The simulation:
  Sends a single byte 0x3C from the master.
  Observes received_data = 0x3C on the slave.
  Monitors signal transitions on sclk, mosi, miso.

## RTL view
![image](https://github.com/user-attachments/assets/41595262-8576-4ed3-a36e-59186549cf9b)

## FSM
![image](https://github.com/user-attachments/assets/7aba84fc-94ef-411e-a800-e08bc3e9ea96)
![image](https://github.com/user-attachments/assets/8ac1e3fc-24dd-43e2-88c8-b19b8eecf24a)

## Resource usage summary
![image](https://github.com/user-attachments/assets/65e139f4-7c3f-493d-b6b8-51fdf9dd9245)

## Waveform
![image](https://github.com/user-attachments/assets/06edb1c1-fd7c-45f5-abcb-9e8c55741cea)




