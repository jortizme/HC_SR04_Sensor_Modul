if {![file exists work]} { 
	vlib work 
}

vcom  ../Divider/Divider.vhd
vcom  HC_SR04_Modul.vhd
vcom txt_util_pack.vhd
vcom  HC_SR04_Modul_TB.vhd

vsim -t ns -voptargs=+acc work.HC_SR04_tb

configure wave -namecolwidth 173
configure wave -valuecolwidth 106
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms


add wave /HC_SR04_tb/clk_i
add wave /HC_SR04_tb/rst_i
add wave /HC_SR04_tb/start_sensor_i
add wave /HC_SR04_tb/trigger_sensor_o
add wave /HC_SR04_tb/echo_sensor_i
add wave /HC_SR04_tb/value_there_o
add wave -unsigned /HC_SR04_tb/value_measured_o


add wave -divider "Control_Unit"
add wave 			  /HC_SR04_tb/DUT/Steuerwerk/State
add wave 			  /HC_SR04_tb/DUT/Steuerwerk/Next_State
add wave 			  /HC_SR04_tb/DUT/count_travel_time_s
add wave 		      /HC_SR04_tb/DUT/stop_count_travel_time_s
add wave 		      /HC_SR04_tb/DUT/echo_high_s
add wave 		      /HC_SR04_tb/DUT/echo_low_s
add wave 		      /HC_SR04_tb/DUT/start_division_s
add wave 		      /HC_SR04_tb/DUT/send_pulse_s
add wave 		      /HC_SR04_tb/DUT/pulse_sent_s

add wave -divider "Arithmetic-Unit"
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/time_measured_s
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/result_div_s


if {0} {
add wave -divider "Divider"
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/Divider/CONST_VAL
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/Divider/CONST_VAL_LENGTH
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/Divider/VAR_VAL_LENTH
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/Divider/Dividor/const_value_c
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/Divider/Dividor/const_summand_c
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/Divider/val_i
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/Divider/Dividor/const_result_s
add wave -unsigned /HC_SR04_tb/DUT/Arithmetic_Unit/Divider/result_o
}

run 500 ms
wave zoom full