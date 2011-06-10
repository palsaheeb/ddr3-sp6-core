project -new 
add_file -vhdl "../rtl/ddr_controller_bank1.vhd"
add_file -vhdl "../rtl/iodrp_controller.vhd"
add_file -vhdl "../rtl/iodrp_mcb_controller.vhd"
add_file -vhdl "../rtl/mcb_raw_wrapper.vhd"
add_file -vhdl "../rtl/mcb_soft_calibration.vhd"
add_file -vhdl "../rtl/mcb_soft_calibration_top.vhd"
add_file -vhdl "../rtl/memc1_infrastructure.vhd"
add_file -vhdl "../rtl/memc1_wrapper.vhd"
add_file -constraint "../synth/mem_interface_top_synp.sdc"
impl -add rev_1
set_option -technology spartan6
set_option -part xc6slx150t
set_option -package fgg676
set_option -speed_grade -2
set_option -default_enum_encoding default
set_option -symbolic_fsm_compiler 1
set_option -resource_sharing 0
set_option -use_fsm_explorer 0
set_option -top_module "ddr_controller_bank1"
set_option -frequency 333.333
set_option -fanout_limit 1000
set_option -disable_io_insertion 0
set_option -pipe 1
set_option -fixgatedclocks 0
set_option -retiming 0
set_option -modular 0
set_option -update_models_cp 0
set_option -verification_mode 0
set_option -write_verilog 0
set_option -write_vhdl 0
set_option -write_apr_constraint 0
project -result_file "../synth/rev_1/ddr_controller_bank1.edf"
set_option -vlog_std v2001
set_option -auto_constrain_io 0
impl -active "../synth/rev_1"
project -run
project -save

