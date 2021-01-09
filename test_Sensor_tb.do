if {![file exists work]} { 
	vlib work 
}

vcom  UART/Serieller_Empfaenger.vhd
vcom  UART/Serieller_Sender.vhd
vcom  UART/UART.vhd
vcom  UART/UART_interface.vhd
vcom  Divider/Divider.vhd
vcom  Sensor_HC/HC_SR04_Modul.vhd
vcom  Sensor_top.vhd
vcom  txt_util_pack.vhd
vcom  Sensor_top_TB.vhd

vsim -t ns -voptargs=+acc work.Sensor_top_tb

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


add wave /Sensor_top_tb/SYS_CLK
add wave /Sensor_top_tb/PB
add wave /Sensor_top_tb/echo_i
add wave /Sensor_top_tb/trigger_o
add wave /Sensor_top_tb/Tx_o


add wave -divider "Sensor_Top"
add wave /Sensor_top_tb/DUT/Valid_s
add wave /Sensor_top_tb/DUT/Ack_s
add wave /Sensor_top_tb/DUT/sender_rdy_s
add wave /Sensor_top_tb/DUT/value_there_s
add wave -unsigned /Sensor_top_tb/DUT/Data_input_s

#add wave -divider "UART_Interface"
#add wave  -hexadecimal /Sensor_top_tb/DUT/UART_Interface/DataTransmision/Ctrl_Reg_Value_c
#add wave  -hexadecimal /Sensor_top_tb/DUT/UART_Interface/Data_i_s

add wave -divider "HC_SR04_Modul"

add wave /Sensor_top_tb/DUT/HC_SR04_Modul/echo_high_s
add wave /Sensor_top_tb/DUT/HC_SR04_Modul/echo_low_s
add wave /Sensor_top_tb/DUT/HC_SR04_Modul/count_travel_time_s
add wave /Sensor_top_tb/DUT/HC_SR04_Modul/stop_count_travel_time_s
add wave /Sensor_top_tb/DUT/HC_SR04_Modul/start_division_s
add wave -unsigned /Sensor_top_tb/DUT/HC_SR04_Modul/Arithmetic_Unit/Check_result/result
add wave -unsigned /Sensor_top_tb/DUT/HC_SR04_Modul/value_measured_o
add wave /Sensor_top_tb/DUT/HC_SR04_Modul/Steuerwerk/State
add wave /Sensor_top_tb/DUT/HC_SR04_Modul/Steuerwerk/Next_State
add wave /Sensor_top_tb/DUT/HC_SR04_Modul/Steuerwerk/value_there_s


add wave -divider "UART"
add wave -hexadecimal /Sensor_top_tb/DUT/UART_Interface/UART/ADR_I
add wave  /Sensor_top_tb/DUT/UART_Interface/UART/WE_I
add wave /Sensor_top_tb/DUT/UART_Interface/UART/RST_I
add wave -unsigned /Sensor_top_tb/DUT/UART_Interface/UART/DAT_I
add wave /Sensor_top_tb/DUT/UART_Interface/UART/ACK_O
add wave /Sensor_top_tb/DUT/UART_Interface/UART/STB_I
add wave /Sensor_top_tb/DUT/UART_Interface/UART/TX_Interrupt
add wave /Sensor_top_tb/DUT/UART_Interface/UART/TxD

add wave -divider "Serieller_Sender"
add wave /Sensor_top_tb/DUT/UART_Interface/UART/Sender/Steuerwerk/Zustand


run 600 ms
wave zoom full