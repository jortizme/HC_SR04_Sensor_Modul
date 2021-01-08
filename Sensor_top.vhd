
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
        SYS_CLK     : std_logic;
        --Buttons for start_sensor (1) and reset (4)
        PB : in std_logic_vector(4 downto 1);
        --TX output
        GPIO_J3_40 : out std_logic;
        --Trigger output
        GPIO_J3_37 : out std_logic;
        --Echo input
        GPIO_J3_34 : in std_logic
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
    signal Valid_s          : std_logic := '0';
    signal Ack_s            : std_logic;
    signal Data_input_s     : std_logic_vector(31 downto 0) := (others => '0');

begin

    --Synchronise the input
    Synchronise: process( clk_i )
    begin
        if rising_edge(clk_i) then

            --delay assignment
            rst_dly_s <= PB(4);
            str_dly_s <= PB(1);
            echo_dly_s <= GPIO_J3_34;

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
        clk_i           => SYS_CLK,
        rst_i           => rst_s,

        Data_i          => Data_input_s,
        Data_o          => open,

        WEn_i           => '1',
        Valid_i         => Valid_s,
        Ack_o           => Ack_s,
        Tx_Ready_o      => sender_rdy_s,
        Rx_Ready_o      => open,

        TX_o            => GPIO_J3_40,
        RX_i            => '1'
    );

    HC_SR04_Modul: entity work.HC_SR04_Modul
    generic map(
        CONST_VAL           => CONST_VAL, --First try would be (2^32 / clk) = 86
        CONST_VAL_LENGTH    => CONST_VAL_LENGTH,
        DATA_WIDTH          => DATA_WIDTH
    )
    port map(
        clk_i               => SYS_CLK,
        rst_i               => rst_s,
        start_sensor_i      => str_s,
        echo_sensor_i       => echo_s,
        trigger_sensor_o    => GPIO_J3_37,
        value_measured_o    => value_measured_s,
        value_there_o       => value_there_s
    );

    --only the lower 16 bits are gone be written
    Data_input_s(DATA_WIDTH - 1 downto 0) <= value_measured_s

    Send_Value: process(clk_i)
    variable value_there_v  : std_logic := '0';
    begin

        if rising_edge(clk_i) then

            if rst_s = '1' then
                Valid_s <= '0';

            elsif value_there_s = '1' then
                value_there_v := value_there_s;

            else
                if sender_rdy_s = '1' then
                    Valid_s <= value_there_v;
                    value_there_v := '0';
                end if;

                if Ack_s = '1' then
                    Valid_s <= '0';
                end if;
                
            end if;

        end if;

    end process;

end architecture rtl ; -Sensor_top