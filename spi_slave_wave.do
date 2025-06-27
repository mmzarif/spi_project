# spi_slave_wave.do

# Compile the design and testbench
vlog ../rtl/spi_slave.sv
vlog ../tb/spi_slave_tb.sv

# Simulate the testbench
vsim spi_slave_tb

# Add all signals to the waveform
add wave -position insertpoint sim:/spi_slave_tb/*

# Run the simulation long enough to capture all activity
run 1000ns

# Zoom to fit waveform
wave zoom full
