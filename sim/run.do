vlib work
vlog apb_wrapper.v apb_wrapper_tb.sv
vsim -voptargs=+acc work.APV_WRAPPER_tb
add wave -position insertpoint sim:/APV_WRAPPER_tb/dut/*
add wave -position insertpoint  \
sim:/APV_WRAPPER_tb/dut/slave0/mem
add wave -position insertpoint  \
sim:/APV_WRAPPER_tb/dut/slave1/mem
run -all