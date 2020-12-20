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
        CONST_VAL           : positive;  --First try would be (2^35 / clk) = 21990 
        CONST_VAL_LENGTH    : positive;   -- 35
        DATA_WIDTH          : positive    --Lets start with 16
    );
    port (
        clk_i               : in std_logic;
        rst_i               : in std_logic;
        start_sensor_i      : in std_logic;
        echo_sensor_i       : in std_logic;
        sender_ready_i      : in std_logic;
        trigger_sensor_o    : out std_logic;            
        value_measured_o    : out std_logic_vector(DATA_WIDTH - 1 downto 0)
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

    constant sound_speed    : unsigned(bits_amount(34300) - 1 downto 0)  := 34300; --in cm/s (34300 cm/s)
    --Maximal ticks possible if the max measurable distance is 3 m (the correct distance in 6 m)
    constant max_dist_ticks : unsigned(bits_amount(899999) - 1 downto 0) := 899999;      
    
    --Signals between the Control and Arithmetic Unit
    signal count_10us_s             : std_logic;
    signal trigger_done_s           : std_logic := '0';
    signal next_measure_allowed_s   : std_logic := '0';
    signal wait_sound_sending_s     : std_logic;
    signal sound_sent_s             : std_logic := '0';
    signal count_travel_time_s      : std_logic;
    signal count_failure_s          : std_logic := '0';
    signal stop_counting_travel_s   : std_logic;
    signal count_period_20ms_s      : std_logic;
    
begin

    Arithmetic_Unit: block

    --Intern signals from arithmetic unit
    signal time_measured_s  : std_logic_vector((sound_speed'length + max_dist_ticks'length) - 1 downto 0) = (others => '0');
    signal result_div_s     : std_logic_vector(time_measured_s'length - 1 downto 0);
    signal start_division_s : std_logic := '0';       

    begin 

        --Counting until 499 with a clock frequency of 50 MHz ensures a 10us waiting time
        Trigger_Cnt : process( clk_i )
        counter_v   :   unsigned(bits_amount(499) - 1 downto 0) := (others => '0');
        begin
            if rising_edge(clk_i) then 

                trigger_done_s <= '0';
                if rst_i = '1' then
                    counter_v := (others => '0');

                elsif count_10us_s = '1' then
                    if counter_v < 499 then
                        counter_v := counter_v + 1;
                    else
                        trigger_done_s <= '1';          
                        counter_v := (others => '0');
                    end if;
                end if;
            end if;
        end process ; -- Trigger_Cnt

        --This process censures period of 20ms (50Hz frequeny), before the next measurement
        process( clk_i )
        counter_v   :   unsigned( bits_amount(999999) - 1 downto 0) := (others => '0');
        begin
            
            if rising_edge(clk_i) then

                if rst_i = '1' then
                    counter_v := (others => '0');

                elsif count_period_20ms_s = '1' then
                    if counter_v < 999999 then
                        counter_v := counter_v + 1;
                    else
                        next_measure_allowed_s <= '1';
                    end if;
                elsif count_period_20ms_s = '0' then
                    counter_v := (others => '0');   
                    next_measure_allowed_s <= '0';
                end if;
            end if;   
        end process; 
        
        --The sensor waits 250us and sends the sound wave for 200us. 
        --For that time we should wait. Count until 22499 at clk
        --frequency of 50 MHz
        Sending_Sound_Cnt : process( clk_i )
        counter_v   :   unsigned(bits_amount(22499) - 1  downto 0) := (others => '0');
        begin
            if rising_edge(clk_i) then

                sound_sent_s <= '0';
                if rst_i = '1' then
                    counter_v := (others => '0');
                
                elsif wait_sound_sending_s = '1' then

                    if counter_v < 22499 then
                        counter_v := counter_v + 1;
                    else
                        counter_v := (others => '0');
                        sound_sent_s <= '1';
                    end if ; 
                end if ;
            end if;
        end process ; -- Sending_Sound_Cnt

        --Count time until arrival of an Echo signal from the sensor
        --According to the data sheet, the sensor output Echo can
        --remain for maximal 200ms High, in case of no signal detected
        Count_Travel_Time : process( clk_i )
        counter_v   :   unsigned( bits_amount(9999999) - 1 downto 0) := (others => '0');
        begin

            if rising_edge(clk_i) then

                count_failure_s <= '0';
                start_division_s <= '0';

                if rst_i = '1' then
                    counter_v := (others => '0');
                
                elsif count_travel_time_s = '1' then

                    counter_v := counter_v + 1;

                    --because the maximal sensor distance is around 3 meters (6 m both ways)
                    if stop_counting_travel_s = '1' and counter_v < max_dist_ticks then
                        time_measured_s <= std_logic_vector(counter_v * sound_speed);
                        start_division_s <= '1'; 
                        counter_v := (others => '0'); 

                    elsif counter_v > 9999999 then
                        count_failure_s <= '1';
                        counter_v := (others => '0');
                    end if;

                else
                    counter_v := (others => '0');
                end if ;
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
        
        --Signal assignment to output
        value_measured_o <= result_div_s(DATA_WIDTH - 1 downto 0);

    end block;

    Steuerwerk: block

        --Typ for state values
        type state_type is (IDLE, TRIGGER, SOUND_SEND, COUNT_TRAVEL, SEND_VALUE, WAIT_PERIOD, S_ERROR);

        --Intern signals from the control unit
        signal State        : state_type := IDLE;
        signal Next_State   : state_type;

        --Initialize intern signals
        signal trigger_out_s    : std_logic := '1'; --Moore Output
        signal value_there_s    : std_logic := '0'; --Moore Output   

    begin
        
        --assign the value of the intern signals to the output port
        process( trigger_out_s ,value_there_s)
        begin
            trigger_sensor_o <= trigger_out_s;
            value_there_o <= value_there_s;
        end process;

        --Process to calculate the next state and the mealy outputs
        Transition : process( State, trigger_done_s, next_measure_allowed_s, 
                            sound_sent_s, count_failure_s, start_sensor_i, 
                            echo_sensor_i, sender_ready_i)
        begin

            --Default-Values for the next state and mealy-output
            count_10us_s            <= '0';
            wait_sound_sending_s    <= '0';
            count_travel_time_s     <= '0';
            stop_counting_travel_s  <= '0';
            count_period_20ms_s     <= '0';
            Next_State              <= S_ERROR;

            case( State ) is
            
                when IDLE =>
                                    if  start_sensor_i = '0' then
                                        Next_State <= IDLE;
                                    elsif start_sensor_i = '1' then
                                        Next_State <= TRIGGER;
                                    end if ;
                when TRIGGER =>
                                    if trigger_done_s = '0' then
                                        count_10us_s <= '1';
                                        Next_State <= TRIGGER;
                                    elsif trigger_done_s = '1' then
                                        Next_State <= SOUND_SEND;    
                                    end if ;
                when SOUND_SEND =>
                                    count_period_20ms_s <= '1';

                                    if sound_sent_s = '0' then
                                        wait_sound_sending_s <= '1'; 
                                        Next_State <= SOUND_SEND;
                                    elsif sound_sent_s = '1' then
                                        Next_State <= COUNT_TRAVEL;                                     
                                    end if ;
                when COUNT_TRAVEL =>
                                    if count_failure_s = '0' then

                                        count_period_20ms_s <= '1';

                                        if echo_sensor_i = '1' then
                                            count_travel_time_s <= '1';
                                            Next_State <= COUNT_TRAVEL;
    
                                        elsif echo_sensor_i = '0' then
                                            stop_counting_travel_s <= '1';
                                            Next_State <= SEND_VALUE;
                                        end if;
                                    
                                    elsif count_failure_s = '1' then

                                        if start_sensor_i = '1' then
                                            Next_State <= TRIGGER;
                                        elsif start_sensor_i = '0' then
                                            Next_State <= IDLE;
                                        end if ;
                                    end if;
                when SEND_VALUE  =>
                                    if sender_ready_i = '1'  then
                                        Next_State <= WAIT_PERIOD;
                                    else
                                        Next_State <= SEND_VALUE;
                                    end if ;
                when WAIT_PERIOD =>
                                    if  next_measure_allowed_s = '0' then
                                        count_period_20ms_s <= '1';
                                        Next_State <= WAIT_PERIOD;
                                    elsif next_measure_allowed_s = '1' then
                                        if start_sensor_i = '1' then
                                            Next_State <= TRIGGER;
                                        elsif start_sensor_i = '0' then
                                            Next_State <= IDLE;
                                        end if ;
                                    end if ;    
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
                    trigger_out_s <= '1';
                    value_there_s <= '0';
                else
                    case( Next_State ) is
                    
                        when IDLE           => trigger_out_s <= '1'; value_there_s <= '0';
                        when TRIGGER        => trigger_out_s <= '0'; value_there_s <= '0';
                        when SOUND_SEND     => trigger_out_s <= '1'; value_there_s <= '0';
                        when COUNT_TRAVEL   => trigger_out_s <= '1'; value_there_s <= '0';
                        when SEND_VALUE     => trigger_out_s <= '1'; value_there_s <= '1';
                        when WAIT_PERIOD    => trigger_out_s <= '1'; value_there_s <= '0';
                        when S_ERROR        => null;        
                    end case ;
                end if ;
            end if ;
        end process ; 
    end block;

end architecture rtl ; 