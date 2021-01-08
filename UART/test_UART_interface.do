if {![file exists work]} { 
	vlib work 
}

vcom  Serieller_Empfaenger.vhd
vcom  Serieller_Sender.vhd
vcom  UART.vhd
vcom  UART_interface.vhd
vcom  txt_util_pack.vhd
vcom  UART_interface_TB.vhd

vsim -t ns -voptargs=+acc work.UART_Interface_tb

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


add wave /UART_Interface_tb/clk_i
add wave /UART_Interface_tb/rst_i
add wave -hexadecimal /UART_Interface_tb/Data_i
add wave /UART_Interface_tb/WEn_i
add wave /UART_Interface_tb/Valid_i
add wave /UART_Interface_tb/Ack_o
add wave /UART_Interface_tb/Tx_Ready_o


add wave -divider "DUT"
add wave /UART_Interface_tb/DUT/WE_s
add wave /UART_Interface_tb/DUT/STB_s
add wave -hexadecimal /UART_Interface_tb/DUT/ADR_s
add wave -hexadecimal /UART_Interface_tb/DUT/Data_i_s
add wave /UART_Interface_tb/DUT/ACK_s

add wave -divider "UART"
add wave /UART_Interface_tb/DUT/UART/CLK_I
add wave /UART_Interface_tb/DUT/UART/RST_I
add wave /UART_Interface_tb/DUT/UART/STB_I
add wave /UART_Interface_tb/DUT/UART/WE_I
add wave -hexadecimal /UART_Interface_tb/DUT/UART/ADR_I
add wave -hexadecimal /UART_Interface_tb/DUT/UART/DAT_I
add wave -hexadecimal /UART_Interface_tb/DUT/UART/DAT_O
add wave /UART_Interface_tb/DUT/UART/ACK_O
add wave /UART_Interface_tb/DUT/UART/TX_Interrupt
add wave /UART_Interface_tb/DUT/UART/RX_Interrupt
add wave /UART_Interface_tb/DUT/UART/RxD
add wave /UART_Interface_tb/DUT/UART/TxD
add wave /UART_Interface_tb/DUT/UART/Schreibe_Daten



add wave -divider "Serieller Sender"

add wave /UART_Interface_tb/DUT/UART/Sender/Steuerwerk/Zustand
add wave /UART_Interface_tb/DUT/UART/Sender/Steuerwerk/Folgezustand
add wave -unsigned /UART_Interface_tb/DUT/UART/Sender/Rechenwerk/ZaehlerBitbreite/Q
add wave /UART_Interface_tb/DUT/TX_o

run 500 us
wave zoom full