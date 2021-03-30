proc AddWaves {} {
    add wave -position end sim:/pipelined_processor/clock
    add wave -position end sim:/pipelined_processor/IF_ID_instruction_data
    add wave -position end sim:/pipelined_processor/ID_EX_instruction
    add wave -position end sim:/pipelined_processor/ID_EX_immediate_data_1
    add wave -position end sim:/pipelined_processor/ID_EX_immediate_data_2
    add wave -position end sim:/pipelined_processor/ID_EX_register_reference
    add wave -position end sim:/pipelined_processor/EX_MEM_instruction
    add wave -position end sim:/pipelined_processor/EX_MEM_immediate_data
    add wave -position end sim:/pipelined_processor/EX_MEM_register_reference
    add wave -position end sim:/pipelined_processor/MEM_WB_instruction
    add wave -position end sim:/pipelined_processor/MEM_WB_immediate_data
    add wave -position end sim:/pipelined_processor/MEM_WB_register_reference
    add wave -position end sim:/pipelined_processor/WB_ID_immediate_data
    add wave -position end sim:/pipelined_processor/WB_ID_register_reference
    add wave -position end sim:/pipelined_processor/WB_ID_write_register
}

vlib work

# compile components
vcom IF_stage.vhd
vcom ID_stage.vhd
vcom EX_stage.vhd
vcom MEM_stage.vhd
vcom WB_stage.vhd
vcom pipelined_processor.vhd

# Start simulation
vsim pipelined_processor

# Generate a clock with 1ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

AddWaves

run 10ns
