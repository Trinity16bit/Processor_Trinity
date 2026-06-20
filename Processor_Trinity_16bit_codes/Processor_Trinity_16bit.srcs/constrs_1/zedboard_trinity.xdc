# Clock (100 MHz)
set_property PACKAGE_PIN Y9 [get_ports clk_100MHz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_100MHz]

# Reset Button (BTNU)
set_property PACKAGE_PIN T18 [get_ports rst_btn]
set_property IOSTANDARD LVCMOS18 [get_ports rst_btn]

# Enter Button (BTND)
set_property PACKAGE_PIN R16 [get_ports enter_btn]
set_property IOSTANDARD LVCMOS18 [get_ports enter_btn]

# Switches (SW0 - SW7)
set_property PACKAGE_PIN F22 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[0]}]
set_property PACKAGE_PIN G22 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[1]}]
set_property PACKAGE_PIN H22 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[2]}]
set_property PACKAGE_PIN F21 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[3]}]
set_property PACKAGE_PIN H19 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[4]}]
set_property PACKAGE_PIN H18 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[5]}]
set_property PACKAGE_PIN H17 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[6]}]
set_property PACKAGE_PIN M15 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[7]}]

# LEDs (LD0 - LD7)
set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN U14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

# Timing Exceptions and Clock Definitions
create_generated_clock -name proc_clk -source [get_ports clk_100MHz] -divide_by 100 [get_pins bufg_inst/O]
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks proc_clk]

set_false_path -from [get_ports enter_btn]
set_false_path -from [get_ports rst_btn]
set_false_path -from [get_ports {sw[*]}]
set_false_path -to [get_ports {led[*]}]
