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
    port (
    clk_i               : in std_logic;
    rst_i               : in std_logic;
    start_sensor_i      : in std_logic;
    echo_sensor_i       : in std_logic;
    trigger_sensor_o    : out std_logic;            --INVERSE LOGIC
    value_measured_o    : out std_logic_vector(31 downto 0);        --ZU LANG
    ----
    --Signals to uart are still missing
    ---
  ) ;
end entity HC_SR04;

-- GUCK FUNKTION CALCULATE AMOUNT OF BITS VON DER VORLESUNG DAMIT DU DIE FEHLER VERRINGERST

architecture rtl of HC_SR04 is

    signal count_10us_s             : std_logic;
    signal trigger_done_s           : std_logic := '0';
    signal next_measure_allowed_s   : std_logic := '0';
    signal wait_sound_sending_s     : std_logic;
    signal sound_sent_s             : std_logic := '0';
    signal count_travel_time_s      : std_logic;
    signal count_failure_s          : std_logic := '0';
    signal stop_counting_travel_s   : std_logic;
    signal start_input_1dl_s        : std_logic := '0';
    signal start_input_2dl_s        : std_logic := '0';
    signal count_period_20ms_s      : std_logic;
    signal clear_20ms_signal_s      : std_logic;

begin

    --To ensure that the signal remains stable, because it comes from outside
    process( clk_i )
    begin
        if rising_edge(clk_i) then
            start_input_1dl_s <= start_sensor_i;                                        
            start_input_2dl_s <= start_input_1dl_s; --Vieleicht ein debouncer implementieren???!!!!!
            echo_input_s      <= echo_sensor_i;
        end if;  
    end process ;  

    Rechenwerk: block

        
        signal time_measured_s       : std_logic_vector(19 downto 0) = (others => '0');

        --Counting until 499 with a clock frequency of 50 MHz ensures a 10us waiting time
        Trigger_Cnt : process( clk_i )
        counter_v   :   unsigned(8 downto 0) := (others => '0');
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

        --This process counts for 20ms to ensure the measurement frequency 50Hz
        process( clk_i )
        counter_v   :   unsigned(19 downto 0) := (others => '0');
        begin
            
            if rising_edge(clk_i) then

                if rst_i = '1' then
                    counter_v := (others => '0');

                elsif count_period_20ms_s = '1' then
                    if counter_v < 999999 then
                        counter_v := counter_v + 1;
                    else
                        next_measure_allowed_s <= '1';  --Im Rechenwerk sobald dieses Signal kommt, muss count_period = 0 sein
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
        counter_v   :   unsigned(14 downto 0) := (others => '0');
        begin
            if rising_edge(clk_i) then

                if rst_i = '1' then
                    counter_v := (others => '0');
                
                elsif wait_sound_sending_s = '1' then

                    if counter_v < 22499 then
                        counter_v := counter_v + 1;
                    else
                        counter_v := (others => '0');
                        sound_sent_s <= '1'
                    end if ; 
                end if ;
            end if;
        end process ; -- Sending_Sound_Cnt

        --Count time until arrival of an Echo signal from the sensor
        --According to the data sheet, the sensor output Echo will
        --remain for maximal 200ms High, in case of no signal detected
        Count_Travel_Time : process( clk_i )
        counter_v   :   unsigned(23 downto 0) := (others => '0');
        begin

            if rising_edge(clk_i) then

                count_failure_s <= '0';

                if rst_i = '1' then
                    counter_v := (others => '0');
                
                elsif count_travel_time_s = '1' then

                    counter_v := counter_v + 1;

                    --because the maximal sensor distance is around 3 meters (6 m both ways)
                    if stop_counting_travel_s = '1' and counter_v < 899999 then
                        time_measured_s <= std_logic_vector(counter_v); --vorsicht, die rechte seite hat 23 bits, die linke 19
                        counter_v := (others => '0'); 

                    elsif counter_v > 9999999 then
                        count_failure_s <= '1';
                        counter_v := (others => '0');
                    end if;
                end if ;
            end if;
            
        end process ; -- Count_Travel_Time

        Calculator : process( clk_i )

        begin
            
        end process ; -- Calculator



    end block;

    Steuerwerk: block
    signal trigger_sensor_s         . std_logic := '1';         --  In Rechenwerk an den output zuweisen!!

    begin

    end block;

end architecture rtl ; 