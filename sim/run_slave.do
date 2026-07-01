vlib work
vlog apb_slave.v apb_slave_tb.sv
vsim -voptargs=+acc work.APV_SLAVE_tb
add wave -r sim:/APV_SLAVE_tb/dut/*
add wave -position insertpoint  \
sim:/APV_SLAVE_tb/dut/mem
run -all