library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_Interface_tb is
end entity;

use work.txt_util_pack.all;

architecture rtl of UART_Interface_tb is

    constant CLOCK_PERIOD   : time      := 20 ns;  -- 50 MHz clock frequency
    constant BitWidthM1_g   : integer := 433; --(SYS_FREQUENCY / BAUDRATE - 1)
    constant BitsM1_g       : integer := 7;
    constant Parity_on_c    : integer := 0;
    constant Parity_odd_c   : integer := 0;
    constant StopBits_c     : integer := 0;

    -----------------Inputs--------------------
    signal clk_i    : std_logic;
    signal rst_i    : std_logic;
    signal Data_i   : std_logic_vector(31 downto 0);
    signal WEn_i    : std_logic;
    signal Valid_i  : std_logic;
    
    -----------------Outputs--------------------
    signal Ack_o        : std_logic;
    signal Tx_Ready_o   : std_logic;
    signal Cfg_done_o   : std_logic;

    type testcase_vector is array(natural range <>) of std_logic_vector(31 downto 0);

    constant tests : testcase_vector(0 to 11) := (
    0=>x"FF00453C",
    1=>x"AD004590",
    2=>x"FFAC45DC",
    3=>x"FF00FC25",
    4=>x"FF00FC23",
    5=>x"FFFD454C",
    6=>x"FF0056B8",
    7=>x"48A7F6F4",
    8=>x"FF34FFAC",
    9=>x"FF350018",
    10=>x"FF3445F8",
    11=>x"0434B04C"
    );

begin

    Simulate: process

        procedure execute_test(i: integer) is
        begin

            Valid_i <= '1';
            Data_i <= tests(i);

            wait until falling_edge(clk_i);

            wait until Ack_o = '1';

            --assert Ack_o = '1' report "UART is not responding" severity failure;

            Valid_i <= '0';

            wait until Tx_Ready_o = '1';

        end procedure;

    begin

        --Reset the sensor module
        wait until falling_edge(clk_i);
        rst_i <= '1';
        wait until falling_edge(clk_i);
        rst_i <= '0';

        wait until Cfg_done_o = '1';

        WEn_i <= '1';

        wait until falling_edge(clk_i);

        for i in tests'range loop

            execute_test(i);
            report "Normal Test " & str(i) & " completed";
        end loop;

        wait;

    end process;

    clocking: process
    begin
        clk_i <= '0';
        wait for CLOCK_PERIOD / 2;
        clk_i <= '1';
        wait for CLOCK_PERIOD / 2;
    end process;

    DUT: entity work.UART_Interface
    generic map(

        BitWidthM1_g    => BitWidthM1_g,
        BitsM1_g        => BitsM1_g,
        Parity_on_c     => Parity_on_c,
        Parity_odd_c    => Parity_odd_c,
        StopBits_c      => StopBits_c
    )
    port map(

            --Clock ins, SYS_CLK = 50 MHz
            clk_i       => clk_i,
            rst_i       => rst_i,
    
            Data_i      => Data_i,
            Data_o      => open,
    
            WEn_i       => WEn_i,
            Valid_i     => Valid_i,
            Ack_o       => Ack_o,
            Tx_Ready_o  => Tx_Ready_o,
            Rx_Ready_o  => open,
    
            Cfg_done_o  => Cfg_done_o,
    
            TX_o        => open,
            RX_i        => '1'
    );

end architecture rtl ; -- rtl