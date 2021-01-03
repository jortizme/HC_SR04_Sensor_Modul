library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HC_SR04_tb is
end entity;

architecture behavior of HC_SR04_tb is

    constant CLOCK_PERIOD       : time      := 20 ns;  -- 50 MHz clock frequency
    constant CONST_VAL          : positive  := 86;     -- 2^32/clock frequency rounded
    constant CONST_VAL_LENGTH   : positive  := 32;
    constant DATA_WIDTH         : positive  := 16;
        


    -----------------Inputs--------------------
    signal clk_i            : std_logic;
    signal rst_i            : std_logic;
    signal start_sensor_i   : std_logic;
    signal echo_sensor_i    : std_logic;
    
    -----------------Outputs--------------------
    signal trigger_sensor_o     : std_logic;
    signal value_measured_o     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal value_there_o     : std_logic;

    type textcase_record is record
    travel_time     : time;
    dist_ref        : unsigned(DATA_WIDTH - 1 downto 0);
    end record;

    type testcase_vector is array(natural range <>) of textcase_record;

    constant tests : testcase_vector(0 to 11) := (
    0=>(20 ms, 343),
    1=>(10 ms, 171),
    2=>(5 ms, 85),
    3=>(4 ms, 68),
    4=>(17 ms, 291),
    5=>(12 ms, 205),
    6=>(7 ms, 120),
    7=>(2 ms, 34),
    8=>(1 ms, 17),
    9=>(500 us,8),
    10=>(150 us, 2),
    11=>(3 ms, 51)
    );

begin


    Stimulate: process

        function value_in_range(value_ref : unsigned(DATA_WIDTH - 1 downto 0);
                                value_measured :  : unsigned(DATA_WIDTH - 1 downto 0)
                                ) return integer is
        variable low_threshold  : unsigned(DATA_WIDTH - 1 downto 0) := value_ref - 5;
        variable high_threshold : unsigned(DATA_WIDTH - 1 downto 0) := value_ref + 5;
        begin
            if value_measured > low_threshold and value_measured < high_threshold then
                return 1;
            else
                return 0;
            end if;
        end function;

        --Simulate the a measure cycle's behavior 
        procedure execute_test(i: integer) is

        begin

            start_sensor_i <= '0';
            echo_sensor_i <= '0';

            --To make sure that the sensor doens't trigger
            --unless the signal start_sensor_i tells it to
            wait for tests(i) * 2;
            wait until falling_edge(clk_i);

            --Verify
            assert trigger_sensor_o = '1' and value_there_o  = '0' report "The sensor triggers without autorisation" severity failure


            --start the sensor and wait until the trigger comes
            start_sensor_i <= '1';
            wait until trigger_sensor_o = '0'

            --in this time the sensor should send the sound wave
            --to vary it, it is being multiplied by the i value
            --WARINING-> is should not wait longer than 450 us
            wait for 40 us * i;

            --Verify
            assert trigger_sensor_o = '0' and value_there_o  = '0' report "The trigger should stay low during the measurement period (20ms)" severity failure;

            --Start the simulation of the wait time for the reflected wave
            echo_sensor_i <= '1';

            --wait for the specified travel time 
            wait for tests(i).travel_time;

            --Verify
            assert trigger_sensor_o = '0' and value_there_o  = '0' report "The trigger should stay low during the measurement period (20ms)" severity failure;

            --Stop the simulation of the wait time for the reflected wave
            echo_sensor_i <= '0';

            --wait until the measured distance is available
            wait until value_there_o = '1'

            assert value_in_range(tests(i).dist_ref, unsigned(value_measured_o)) = 1 "The sensor module measured a distance out of the boundaries" severity failure;

            --wait until the trigger goes high
            wait until trigger_sensor_o = '1';

        end procedure;
        
        --NOCH EINE PROZEDUR ZUM PRÜFEN VON KONTINUERLICHE MESSUNGEN

    begin

        for i in tests'range loop

            --Reset the sensor module
            wait until falling_edge(clk_i);
            rst_i <= '1';
            wait until falling_edge(clk_i);
            rst_i <= '0';

            execute_test(i);
            report "Test " & str(i) & " completed";
        end loop;

        wait;

    end process

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
        rst_i               => rst_i,       --MACH DEN RESET ERST VOR BEGIN DER FOR SCHLEIFE
        start_sensor_i      => start_sensor_i,
        echo_sensor_i       => echo_sensor_i,
        trigger_sensor_o    => trigger_sensor_o,
        value_measured_o    => value_measured_o,
        value_there_o       => value_there_o

    );

end architecture behavior ; -- behavior