library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HC_SR04_tb is
end entity;

use work.txt_util_pack.all;

architecture behavior of HC_SR04_tb is

    constant CLOCK_PERIOD       : time      := 20 ns;  -- 50 MHz clock frequency
    constant CONST_VAL          : positive  := 2946347; -- (2^32*34300)/clock frequency rounded -> 34300 cm/s 
    constant CONST_VAL_LENGTH   : positive  := 32;
    constant DATA_WIDTH         : positive  := 16;

    -----------------Inputs--------------------
    signal clk_i            : std_logic;
    signal rst_i            : std_logic;
    signal start_sensor_i   : std_logic;
    signal echo_sensor_i    : std_logic;
    
    -----------------Outputs--------------------
    signal trigger_sensor_o : std_logic;
    signal value_measured_o : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal value_there_o    : std_logic;

    type textcase_record is record
    travel_time     : time;
    dist_ref        : integer;
    end record;

    type testcase_vector is array(natural range <>) of textcase_record;

    constant tests : testcase_vector(0 to 13) := (
    0=>(20 ms, 343),
    1=>(10 ms, 171),
    2=>(5 ms, 85),
    3=>(4 ms, 68),
    4=>(17 ms, 291),
    5=>(12 ms, 206),
    6=>(7 ms, 120),
    7=>(2 ms, 34),
    8=>(1 ms, 17),
    9=>(500 us,8),
    10=>(150 us, 2),
    11=>(3 ms, 51),
    12=>(24 ms, 0),
    13=>(100 ms, 0)
    );

begin

    Stimulate: process

        --Simulate the a measure cycle's behavior 
        procedure execute_test(i: integer; con_measu : std_logic) is
            
        variable value_measured_v   : unsigned(DATA_WIDTH - 1 downto 0);   

        begin

            if con_measu = '0' then

                start_sensor_i <= '0';

                --To make sure that the sensor doens't trigger
                --unless the signal start_sensor_i tells it to
                wait for CLOCK_PERIOD * (i+1);
    
                --Verify
                assert trigger_sensor_o = '0' and value_there_o  = '0' report "The sensor triggers without autorisation" severity failure;
    
                --start the sensor and wait until the trigger comes
                start_sensor_i <= '1';

                wait on trigger_sensor_o;

                assert trigger_sensor_o = '1' and value_there_o  = '0' report "The sensor triggers without autorisation" severity failure;

                start_sensor_i <= '0';

            end if;

            --wait until the trigger comes
            wait until trigger_sensor_o = '0';

            --in this time the sensor should send the sound wave
            --to vary it, it is being multiplied by the i value
            --WARINING-> is should not wait longer than 450 us
            wait for 40 us * i;

            --Start the simulation of the wait time for the reflected wave
            echo_sensor_i <= '1';

            --wait for the specified travel time 
            wait for tests(i).travel_time;

            --Stop the simulation of the wait time for the reflected wave
            echo_sensor_i <= '0';

            --wait until the measured distance is available
            wait until value_there_o = '1';

            value_measured_v    := unsigned(value_measured_o);

            assert value_measured_v = to_unsigned(tests(i).dist_ref,DATA_WIDTH)report "The sensor module measured false distance" severity failure;


            if con_measu = '1' then
                wait until trigger_sensor_o = '1';
            end if;

        end procedure;
        
    begin

        --Reset the sensor module
        wait until falling_edge(clk_i);
        rst_i <= '1';
        wait until falling_edge(clk_i);
        rst_i <= '0';

        echo_sensor_i <= '0';

        for i in tests'range loop

            execute_test(i, '0');
            report "Normal Test " & str(i) & " completed";
        end loop;


        --Reset the sensor module again
        wait until falling_edge(clk_i);
        rst_i <= '1';
        wait until falling_edge(clk_i);
        rst_i <= '0';

        echo_sensor_i <= '0';

        --the start signal remains high during this second test
        start_sensor_i <= '1';

        for i in tests'range loop
            execute_test(i, '1');
            report "Continuous Test " & str(i) & " completed";
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

    DUT: entity work.HC_SR04
    generic map(
        CONST_VAL           => CONST_VAL,
        CONST_VAL_LENGTH    => CONST_VAL_LENGTH,
        DATA_WIDTH          => DATA_WIDTH
    )
    port map (
        clk_i               => clk_i,
        rst_i               => rst_i,       
        start_sensor_i      => start_sensor_i,
        echo_sensor_i       => echo_sensor_i,
        trigger_sensor_o    => trigger_sensor_o,
        value_measured_o    => value_measured_o,
        value_there_o       => value_there_o
    );

end architecture behavior ; -- behavior