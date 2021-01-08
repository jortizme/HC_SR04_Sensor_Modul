# Input signal von außen mussen hier synchrnoiwist werden

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Sensor_top is
    generic(
        DATA_WIDTH      : integer := 16;
        BitWidthM1_g    : integer := 194; --(SYS_FREQUENCY / BAUDRATE - 1) Baudrate -> 256000 
        BitsM1_g        : integer := 8;
        Parity_on_c     : integer := 0;
        Parity_odd_c    : integer := 0;
        StopBits_c      : integer := 0;
        CONST_VAL       : integer := 86; --First try would be (2^32 / clk) = 86
        CONST_VAL_LENGTH : integer := 32
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
    signal str_s        : std_logic;

    signal echo_dly_s   : std_logic;
    signal echo_s       : std_logic;

    signal sender_rdy_s     : std_logic;
    signal value_measured_s : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal value_there_s    : std_logic;
    signal value_there_dly_s : std_logic := '0';
    signal Ack_s            : std_logic;
    signal Data_input_s     : std_logic_vector(31 downto 0) := (others => '0');

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
        BitWidthM1_g    => BitWidthM1_g, 
        BitsM1_g        => BitsM1_g,   
        Parity_on_c     => Parity_on_c, 
        Parity_odd_c    => Parity_odd_c,
        StopBits_c      => StopBits_c 
    ) 
    port map(
        --Clock ins, SYS_CLK = 50 MHz
        clk_i           => clk_i,
        rst_i           => rst_s,

        Data_i          => Data_input_s,
        Data_o          => open,

        WEn_i           => '1',
        Valid_i         => value_there_dly_s,
        Ack_o           => Ack_s,
        Tx_Ready_o      => sender_rdy_s,
        Rx_Ready_o      => open,

        TX_o            => --gpio,
        RX_i            => '1'
    );

    HC_SR04_Modul: entity work.HC_SR04_Modul
    generic map(
        CONST_VAL           => CONST_VAL, --First try would be (2^32 / clk) = 86
        CONST_VAL_LENGTH    => CONST_VAL_LENGTH,
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

    --only the lower 16 bits are gone be written
    Data_input_s(DATA_WIDTH - 1 downto 0) <= value_measured_s

    Send_Value: process(clk_i)

    begin

        if rising_edge(clk_i) then

            if rst_s = '1' then
                value_there_dly_s <= '0';

            elsif value_there_s = '1' then
                value_there_dly_s <= value_there_s;

            else
                if Ack_s = '1' then
                    value_there_dly_s <= '0';
                else
                    value_there_dly_s <= value_there_dly_s;
                end if;
                
            end if;

        end if;

    end process;

end architecture rtl ; -Sensor_top