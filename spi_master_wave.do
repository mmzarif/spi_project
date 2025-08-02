# spi_master_wave.do

# Compile design and testbench files
vlog ../rtl/spi_master_mode0.sv
vlog ../tb/spi_master_tb.sv

# Launch simulation
vsim spi_master_tb

# Add top-level testbench signals to waveform
add wave -position insertpoint sim:/spi_master_tb/*

# Also add internal DUT signals for debugging
add wave -position insertpoint sim:/spi_master_tb/dut/*

# Run simulation for enough time to capture one full transaction
run 1000ns

# Fit waveform to screen
wave zoom full