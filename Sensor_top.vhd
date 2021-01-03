# Input signal von außen mussen hier synchrnoiwist werden

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Sensor_top is
    generic(
        DATA_WIDTH : positive := 16;
    );
    port (
        clock_i     : std_logic;
        
        --reset BUTTON
        --start sensor BUTTON

        --TRANMITTER GPIO

        --TRIGGER GPIO
        --ECHO GPIO


    );
end entity Sensor_top;

architecture rtl of Sensor_top is

    signal rst_dly_s  : std_logic;
    signal rst_s        : std_logic;

    signal str_dly_s    : std_logic;
    signal str_s    : std_logic;

    signal echo_dly_s   : std_logic;
    signal echo_s       : std_logic;

    signal sender_rdy_s : std_logic;
    signal value_measured_s : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal value_there_s    : std_logic;
    signal Ack_s            : std_logic;
    signal Valid_s          : std_logic;
    signal Data_input_s     : std_logic_vector(31 downto 0) := (others => '0');
    signal Config_done_s    : std_logic;

begin

    --Synchronise the input
    Synchronise: process( clk_i )
    begin
        if rising_edge(clk_i) then

            --delay assignment
            rst_dly_s <= --gpio
            str_dly_s <= --gpio
            echo_dly_s <= --input

            --signals to be used
            rst_s <= rst_dly_s;
            str_s <= str_dly_s;
            echo_s <= echo_dly_s;
        end if ;
    end process ; 


    UART_Interface: entity work.UART_Interface
    generic map(
        BitWidthM1_g    => 433, --(SYS_CLK/BAUDRATE - 1) in this case  115200 -> Baudrate
        BitsM1_g        => 7,   -- Databits (8) - 1
        Parity_on_c     => 0, -- no parity
        Parity_odd_c    => 0,
        StopBits_c      => 0 --0: 1.0 Stoppbits, 1: 1.5 Stoppbits, 2: 2.0 Stoppbits, 3: 2.5 Stoppbits
    ) 
    port map(
        --Clock ins, SYS_CLK = 50 MHz
        clk_i           => clk_i,
        rst_i           => rst_s,

        Data_i          => Data_input_s,
        Data_o          => open,

        WEn_i           => '1',
        Valid_i         => Valid_s,
        Ack_o           => Ack_s,
        Tx_Ready_o      => sender_rdy_s,
        Rx_Ready_o      => open,

        Cfg_done_o      => Config_done_s,

        TX_o            => --gpio,
        RX_i            => '1'

    );

    HC_SR04_Modul: entity work.HC_SR04_Modul
    generic map(
        CONST_VAL           => 86, --First try would be (2^32 / clk) = 86
        CONST_VAL_LENGTH    => 32,
        DATA_WIDTH          => DATA_WIDTH
    )
    port map(
        clk_i               => clk_i,
        rst_i               => rst_s,
        start_sensor_i      => str_s,
        echo_sensor_i       => echo_s,
        trigger_sensor_o    => --gpio,
        value_measured_o    => value_measured_s,
        value_there_o       => value_there_s
    );
    

    Sende_Data: process( clk_i )
    begin

        if rising_edge(clk_i) then

            if Config_done_s = '1' then 
            
                if value_there_s = '1' then
                    Data_input_s(DATA_WIDTH - 1 downto 0) <= value_measured_s
                end if;

                if str_s = '1' and sender_rdy_s = '1' then
                    Valid_s <= '1';
                end if;

                if Valid_s = '1' and Ack_s = '1' then
                    Valid_s <= '0';
                end if;

            end if;

        end if ;

    end process; -- Sende_Data

end architecture rtl ; -Sensor_top