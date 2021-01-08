if {![file exists work]} { 
	vlib work 
}

vcom  Divider.vhd
vcom txt_util_pack.vhd
vcom  Divider_TB.vhd

vsim -t ns -voptargs=+acc work.Divider_tb

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


add wave /Divider_tb/clk_i
add wave /Divider_tb/divide_i
add wave -unsigned /Divider_tb/val_i
add wave -unsigned /Divider_tb/result_o

run 500 ns
wave zoom full