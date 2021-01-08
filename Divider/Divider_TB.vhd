library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divider_tb is
end entity;

use work.txt_util_pack.all;

architecture behavior of Divider_tb is

    constant CLOCK_PERIOD       : time      := 20 ns;  -- 50 MHz clock frequency
    constant CONST_VAL          : positive := 273; --2^12/15
    constant CONST_VAL_LENGTH   : positive := 12;
    constant VAR_VAL_LENTH      : positive := 9; -- max 435 

    signal clk_i    : std_logic;
    signal divide_i : std_logic := '0';
    signal val_i    : std_logic_vector(VAR_VAL_LENTH - 1 downto 0);
    signal result_o : std_logic_vector(VAR_VAL_LENTH - 1 downto 0);

    type textcase_record is record
    variable_val     : positive;
    expected_result  : positive;    
    end record;

    type testcase_vector is array(natural range <>) of textcase_record;

    constant tests : testcase_vector(0 to 4)    := (
    0=> (34,2),
    1=> (265,18),
    2=> (426,28),
    3=> (168,11),
    4=> (377,25)
    );

begin

    Stimuli: process
    begin

        for i in tests'range loop

            wait until falling_edge(clk_i);
            divide_i <= '1';
            val_i <= std_logic_vector(to_unsigned(tests(i).variable_val,VAR_VAL_LENTH));

            wait until falling_edge(clk_i);
            assert unsigned(result_o) = to_unsigned(tests(i).expected_result,VAR_VAL_LENTH) report "False result" severity error;
            report "Test " & str(i) & " completed";

            wait until falling_edge(clk_i);
            divide_i <= '0';

        end loop;

        wait;

    end process ; 


    clocking: process
    begin
        clk_i <= '0';
        wait for CLOCK_PERIOD / 2;
        clk_i <= '1';
        wait for CLOCK_PERIOD / 2;
    end process;

    DUT: entity work.Divider
    generic map(
        --Equals the 2^CONST_VAL_LENGTH number divided by the number in the denominator
        CONST_VAL           => CONST_VAL,
        CONST_VAL_LENGTH    => CONST_VAL_LENGTH,
        --Variable value length
        VAR_VAL_LENTH       => VAR_VAL_LENTH
    )
    port map(
        clock_i     => clk_i,
        divide_i    => divide_i,
        val_i       => val_i,
        result_o    => result_o
    );

end architecture behavior ; 