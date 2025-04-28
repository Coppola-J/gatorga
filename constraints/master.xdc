###################################################
# FPGA Revolution Open Bootcamp
# Episode 33 - Pong game over HDMI 1280x720p @60fps
#
# Design constraints for pynq-z1
###################################################

#125 MHz clock from Ethernet PHY
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk125]
create_clock -period 8.000 -name clk125 -waveform {0.000 4.000} -add [get_ports clk125]

# TMDS interface to HDMI
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports tmds_tx_clk_p_0]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports tmds_tx_clk_n_0]

set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p_0[0]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n_0[0]}]

set_property -dict {PACKAGE_PIN K19 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p_0[1]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n_0[1]}]

set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p_0[2]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n_0[2]}]

# Buttons 
set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports p1_right]
set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS33 } [get_ports p1_left]

set_property -dict { PACKAGE_PIN L20 IOSTANDARD LVCMOS33 } [get_ports p2_right]
set_property -dict { PACKAGE_PIN L19 IOSTANDARD LVCMOS33 } [get_ports p2_left]

## LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports led_kawser]
#set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[1]}]
#set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[2]}]
#set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[3]}]

# Switches (Reset)
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports rst_trig]