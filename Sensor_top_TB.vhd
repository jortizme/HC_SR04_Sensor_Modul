library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Sensor_top_tb is
end entity;

use work.txt_util_pack.all;

architecture behavior of Sensor_top_tb is

    constant CLOCK_PERIOD       : time      := 20 ns;  -- 50 MHz clock frequency
    constant CONST_VAL          : integer  := 2946347; -- (2^32*34300)/clock frequency rounded -> 34300 cm/s 
    constant CONST_VAL_LENGTH   : integer  := 32;
    constant DATA_WIDTH         : integer  := 16;
    constant BitWidthM1_g       : integer := 194; --(SYS_FREQUENCY / BAUDRATE - 1) Baudrate -> 256000
    constant BitsM1_g           : integer := 8;
    constant Parity_on_c        : integer := 0;
    constant Parity_odd_c       : integer := 0;
    constant StopBits_c         : integer := 0;


    -----------------Inputs--------------------
    signal SYS_CLK      : std_logic;
    signal PB           : std_logic_vector(3 downto 0) := (others => '1');
    signal echo_i       : std_logic := '0';

    
    -----------------Outputs--------------------
    signal trigger_o    : std_logic;
    signal Tx_o         : std_logic;


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

                PB(0) <= '1';

                --To make sure that the sensor doens't trigger
                --unless the signal start_sensor_i tells it to
                wait for CLOCK_PERIOD * (i+1);
    
                PB(0) <= '0';

                wait on trigger_o;

                PB(0) <= '1';

            end if;

            --wait until the trigger comes
            wait until trigger_o = '0';

            --in this time the sensor should send the sound wave
            --to vary it, it is being multiplied by the i value
            --WARINING-> is should not wait longer than 450 us
            wait for 40 us * i;

            --Start the simulation of the wait time for the reflected wave
            echo_i <= '1';

            --wait for the specified travel time 
            wait for tests(i).travel_time;

            --Stop the simulation of the wait time for the reflected wave
            echo_i <= '0';

            if con_measu = '1' then
                wait until trigger_o = '1';
            end if;

        end procedure;
        
    begin

        --Reset the sensor module
        wait until falling_edge(SYS_CLK);
        PB(3) <= '0';
        wait until falling_edge(SYS_CLK);
        PB(3) <= '1';

        echo_i <= '0';

        for i in tests'range loop

            execute_test(i, '0');
            report "Normal Test " & str(i) & " completed";
        end loop;


        --Reset the sensor module again
        wait until falling_edge(SYS_CLK);
        PB(3) <= '0';
        wait until falling_edge(SYS_CLK);
        PB(3) <= '1';

        echo_i <= '0';

        --the start signal remains high during this second test
        PB(0) <= '0';

        for i in tests'range loop
            execute_test(i, '1');
            report "Continuous Test " & str(i) & " completed";
        end loop;

        wait;

    end process;

    clocking: process
    begin
        SYS_CLK <= '0';
        wait for CLOCK_PERIOD / 2;
        SYS_CLK <= '1';
        wait for CLOCK_PERIOD / 2;
    end process;

    DUT: entity work.Sensor_top
    generic map(
        DATA_WIDTH      => DATA_WIDTH,
        BitWidthM1_g    => BitWidthM1_g,
        BitsM1_g        => BitsM1_g,
        Parity_on_c     => Parity_on_c,
        Parity_odd_c    => Parity_odd_c,
        StopBits_c      => StopBits_c,
        CONST_VAL       => CONST_VAL,
        CONST_VAL_LENGTH => CONST_VAL_LENGTH
    )
    port map(
        SYS_CLK     => SYS_CLK, 
        --Buttons for start_sensor (1) and reset (4)
        PB          => PB,
        --TX output
        GPIO_J3_40  => Tx_o,
        --Trigger output 
        GPIO_J3_25  => trigger_o,
        --Echo input
        GPIO_J3_15  => echo_i
    );

end architecture behavior ; -- behavior