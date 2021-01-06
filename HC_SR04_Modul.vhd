---------------------------------------------------------------------------------
-- HC_SR04 Sensor Controller
---------------------------------------------------------------------------------
--Autor: Joaquin Alejandro Ortiz Meza
--Date:  17.12.2019
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HC_SR04 is
    generic(
        CONST_VAL           : positive;  -- (2^32*34300)/clock frequency rounded -> 34300 cm/s = 2946347
        CONST_VAL_LENGTH    : positive;   -- 32
        DATA_WIDTH          : positive    --Lets start with 16
    );
    port (
        clk_i               : in std_logic;
        rst_i               : in std_logic;
        start_sensor_i      : in std_logic;
        echo_sensor_i       : in std_logic;
        trigger_sensor_o    : out std_logic;            
        value_measured_o    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        value_there_o       : out std_logic
    );
end entity HC_SR04;

architecture rtl of HC_SR04 is

    -- Returns number of bits required to represent val in binary vector
    function bits_amount(val : natural) return natural is
        variable res_v      : natural; --Result
        variable remain_v   : natural; --Remainder used in iteration
    begin
        res_v := 0;
        remain_v := val;
    
        while remain_v > 0 loop
            res_v := res_v + 1;
            remain_v := remain_v / 2;
        end loop;
        return res_v;
    end function;

    --Maximal ticks possible if the max measurable distance is around 300 cm (the correct distance in 600 cm)
    constant max_dist_ticks : unsigned(bits_amount(1099999) - 1 downto 0) := to_unsigned(1099999,bits_amount(1099999));      
    
    --Signals between the Control and Arithmetic Unit
    signal count_travel_time_s      : std_logic;
    signal stop_count_travel_time_s : std_logic;
    signal echo_high_s              : std_logic;
    signal echo_low_s               : std_logic;
    signal time_out_s               : std_logic;
    signal start_division_s : std_logic := '0';
    
begin

    Arithmetic_Unit: block

    --Intern signals from arithmetic unit
    signal time_measured_s  : std_logic_vector(max_dist_ticks'length - 1 downto 0) := (others => '0');
    signal result_div_s     : std_logic_vector(max_dist_ticks'length - 1 downto 0);
    signal trigger_s        : std_logic := '1'; --Idle high
    signal echo_dly_s       : std_logic := '0';

    begin 

        --For this type of measurement, the trigger has to be a square signal with
        --a frequency of 40 ms. Why 40 ms? because the amount of time needed for
        -- the sensor to achieve a complete measuremet is 20 ms. This signal is only
        --activated, whenever the start_sensor_i input reaches the high level
        Trigger_Signal : process( clk_i )
        variable counter_v : unsigned( bits_amount(999999) - 1 downto 0) := to_unsigned(1000000,bits_amount(999999)); --Countdown beginning at 999999 (SYS_FREQ/50Hz)
        begin

            if rising_edge(clk_i) then

                if rst_i = '1' then
                    counter_v := to_unsigned(999999,bits_amount(999999));

                else
                    counter_v := counter_v - 1;

                    if counter_v = 0 then
                        trigger_s <= not trigger_s;
                        counter_v := to_unsigned(999999,bits_amount(999999));
                    end if ;
                end if;
            end if ;
            
        end process ; -- Trigger_Signal

        --Trigger signal assignment at the output
        trigger_sensor_o <= trigger_s when start_sensor_i = '1' else '1';

        --This process detects any edge transiton on the echo_sensor_i input
        Detect_Echo_Changes: process(clk_i)
        begin

            if rising_edge(clk_i) then

                echo_high_s <= '0';
                echo_low_s <= '0';

                echo_dly_s <= echo_sensor_i;

                if echo_dly_s = '1' and echo_sensor_i = '0' then

                    echo_low_s <= '1';

                elsif echo_dly_s = '0' and echo_sensor_i = '1' then

                    echo_high_s <= '1';

                end if;

            end if;

        end process; 

        Count_Travel_Time : process( clk_i )
        variable counter_v   :   unsigned( max_dist_ticks'length - 1 downto 0) := (others => '0');
        begin

            if rising_edge(clk_i) then

                time_out_s <= '0';

                if rst_i = '1' then
                    counter_v := (others => '0');
                
                elsif count_travel_time_s = '1' then

                    counter_v := counter_v + 1;

                    if counter_v = max_dist_ticks then
                        counter_v := (others => '0');
                        time_out_s <= '1';
                    end if;

                elsif stop_count_travel_time_s = '1' then
                    time_measured_s <= std_logic_vector(counter_v);
                    counter_v := (others => '0'); 

                end if;

            end if;

        end process ; -- Count_Travel_Time

        Divider: entity work.Divider
        generic map(
            CONST_VAL           =>  CONST_VAL,
            CONST_VAL_LENGTH    =>  CONST_VAL_LENGTH,
            VAR_VAL_LENTH       =>  time_measured_s'length         
        ) port map(
            clock_i     => clk_i,
            divide_i    => start_division_s,
            val_i       => time_measured_s,
            result_o    => result_div_s
        );
        
        --Signal assignment to output, this musst be divided by to
        --this would be an easy shift to the rigth
        value_measured_o <= result_div_s(DATA_WIDTH downto 1);

    end block;

    Steuerwerk: block

        --Typ for state values
        type state_type is (IDLE, COUNTING_TIME, DIVIDE, DONE, S_ERROR);

        --Intern signals from the control unit
        signal State        : state_type := IDLE;
        signal Next_State   : state_type;

        --Initialize intern signals
        signal value_there_s    : std_logic := '0'; --Moore Output   

    begin
        
        --assign the value of the intern signals to the output port
        process( value_there_s)
        begin
            value_there_o <= value_there_s;
        end process;

        --Process to calculate the next state and the mealy outputs
        Transition : process( State, echo_high_s, echo_low_s, time_out_s)
        begin

            --Default-Values for the next state and mealy-output
            count_travel_time_s      <= '0';
            stop_count_travel_time_s <= '0';
            Next_State              <= S_ERROR;

            case( State ) is
            
                when IDLE =>

                            if echo_high_s = '1' then
                                count_travel_time_s <= '1';
                                Next_State <= COUNTING_TIME;
                            else  
                                Next_State <= IDLE;
                            end if ;

                when COUNTING_TIME  =>
                            if echo_low_s = '0' then
                                count_travel_time_s <= '1';
                                Next_State <= COUNTING_TIME;

                            elsif echo_low_s = '1' then
                                stop_count_travel_time_s <= '1';
                                Next_State <= DIVIDE;

                            elsif time_out_s = '1' then
                                Next_State <= IDLE;

                            end if ;
                            
                when DIVIDE  => Next_State <= DONE;

                when DONE  => Next_State <= IDLE;

                when S_ERROR =>     null;
            
            end case ;
        end process ; -- Transition

        --Register for state and moore-output
        Reg : process( clk_i )
        begin
            if rising_edge(clk_i) then
                if rst_i = '1' then
                    State <= IDLE;
                else
                    State <= Next_State;
                end if ;

                if rst_i = '1' then
                    value_there_s <= '0';
                    start_division_s <= '0';
                else
                    case( Next_State ) is
                    
                        when IDLE           => value_there_s <= '0'; start_division_s <= '0';
                        when COUNTING_TIME  => value_there_s <= '0'; start_division_s <= '0';
                        when DIVIDE         => value_there_s <= '0'; start_division_s <= '1';
                        when DONE           => value_there_s <= '1'; start_division_s <= '0';
                        when S_ERROR        => null;        
                    end case ;
                end if ;
            end if ;
        end process ; 

    end block;

end architecture rtl ; 