###################################################
# FPGA Revolution Open Bootcamp
# Episode 33 - Pong game over HDMI 1280x720p @60fps
#
# Design constraints for pynq-z1
###################################################

# TMDS interface to HDMI
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports tmds_tx_clk_p_0]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports tmds_tx_clk_n_0]

set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p_0[0]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n_0[0]}]

set_property -dict {PACKAGE_PIN K19 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p_0[1]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n_0[1]}]

set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_p_0[2]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {tmds_tx_data_n_0[2]}]

# Push button 0 -> Paddle 1 Right
# set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports gpio_io_i_0[0]]
# Push button 3 -> Paddle 1 Left
# set_property -dict { PACKAGE_PIN L19 IOSTANDARD LVCMOS33 } [get_ports gpio_io_i_0[0]]

## LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led_kawser_0}]
#set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[1]}]
#set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[2]}]
#set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[3]}]