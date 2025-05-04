###################################################
# FPGA Revolution Open Bootcamp
# Episode 33 - Pong game over HDMI 1280x720p @60fps
#
# Design constraints for pynq-z1
###################################################

# 125 MHz clock input
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk125]
create_clock -period 8.000 -name clk125 -waveform {0.000 4.000} -add [get_ports clk125]

# TMDS interface to HDMI
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports tmds_tx_clk_p]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports tmds_tx_clk_n]

set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p[0]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n[0]}]

set_property -dict {PACKAGE_PIN K19 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p[1]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n[1]}]

set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p[2]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n[2]}]

# Push button 0 -> Right
set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS33 } [get_ports right]
# Push button 1 -> Left
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports left]
# Push button 2 -> Fire
set_property -dict { PACKAGE_PIN L20 IOSTANDARD LVCMOS33 } [get_ports fire]
# Push button 3 -> Ready up
set_property -dict { PACKAGE_PIN L19 IOSTANDARD LVCMOS33 } [get_ports ready_up]


## Debug LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {debug[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {debug[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {debug[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {debug[3]}]