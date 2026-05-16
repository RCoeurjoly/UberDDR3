set_property LOC AA28 [get_ports {clk50}]
set_property IOSTANDARD LVCMOS18 [get_ports {clk50}]
create_clock -name clk50 -period 20.000 [get_ports clk50]

set_property LOC R28 [get_ports {rst_n}]
set_property IOSTANDARD LVCMOS18 [get_ports {rst_n}]

set_property LOC P30 [get_ports {led[0]}]
set_property LOC M30 [get_ports {led[1]}]
set_property LOC N30 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[2]}]
