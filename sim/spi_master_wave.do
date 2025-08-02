# spi_master_wave.do

# Compile design and testbench
vlog ../rtl/spi_master.sv
vlog ../tb/spi_master_tb.sv

# Simulate the testbench
vsim spi_master_tb

# Add all signals to waveform
add wave -position insertpoint sim:/spi_master_tb/*
add wave -position insertpoint sim:/spi_master_tb/dut/*

# Run simulation
run 2000ns

# Zoom to fit
wave zoom full
