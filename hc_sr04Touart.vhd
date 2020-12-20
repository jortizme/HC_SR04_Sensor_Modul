

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity hc_sr04Touart is
    generic(
        CONST_VAL           : positive;  --First try would be (2^35 / clk) = 21990 
        CONST_VAL_LENGTH    : positive   -- 35
        DATA_WIDTH          : positive
    );
    port (
    --Clock ins, SYS_CLK = 50 MHz
    clk_i : in  std_logic;
    rst_i : in std_logic;

    --HC_SR04 sensor 
    Start_i     : in std_logic;
    Echo_i      : in std_logic;
    Trigger_o   : out std_logic;

    TX_o        : out std_logic  --UART TX
    );
end entity hc_sr04Touart;

architecture arch of ent is

    constant BitWidthM1_c   : unsigned(15 downto 0) :=  433;      --(SYS_CLK/BAUDRATE - 1) in this case  115200
    constant BitsM1_c       : unsigned(3 downto 0)  :=  7;        --(Amount of bits per frame - 1)
    constant Parity_on_c    : std_logic := '0';                   -- Parity on
    constant Parity_odd_c   : std_logic := '0';
    constant StopBits_c     : unsigned(1 downto 0)  := 0;         --0: 1.0 Stoppbits, 1: 1.5 Stoppbits, 2: 2.0 Stoppbits, 3: 2.5 Stoppbits

    signal UartCtrl_RG_s    : std_logic_vector(31 downto 0) := (others => '0');
    signal UartSTB_s        : std_logic;
    signal UartWE_s         : std_logic;
    signal UartAdr_s        : std_logic_vector(3 downto 0);
    signal UartDAT_I_s      : std_logic_vector(31 downto 0);
    signal UartACK_s        : std_logic;
    signal UartRX_int_s     : std_logic;
    signal UART_RX_s        : std_logic := '1';
    signal Sensor_En_s      : std_logic;
    signal Config_done_s    : std_logic := '0';

begin

    UART: entity work.UART
    port map (
		-- Wishbone Bus
		CLK_I              => clk_i,
		RST_I              => rst_i,
		STB_I              => UartSTB_s,
		WE_I               => UartWE_s ,
		ADR_I              => UartAdr_s,
		DAT_I              => UartDAT_I_s,
        DAT_O              => open,
		ACK_O              => UartACK_s,
		-- Interupt
		TX_Interrupt       => UartRX_int_s,
		RX_Interrupt       => open,		
		-- Port Pins
		RxD                => UART_RX_s,
		TxD                => TX_o
    );

    Sensor_En_s <= Start_i and Config_done_s;

    Sensor: entity work.HC_SR04
    generic map(
        CONST_VAL           => CONST_VAL,   --First try would be (2^35 / clk) = 21990 
        CONST_VAL_LENGTH    => CONST_VAL_LENGTH,      -- 35
        DATA_WIDTH          => DATA_WIDTH   --Lets start with 16
    )
    port map(
        clk_i               => clk_i,
        rst_i               => rst_i,
        start_sensor_i      => Sensor_En_s,
        echo_sensor_i       : in std_logic;
        sender_ready_i      : in std_logic;
        trigger_sensor_o    : out std_logic;            
        value_measured_o    : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        value_there_o       : out std_logic
    );

    Control_Unit:block

    --Typ for state values
    type state_type is (IDLE, CONFIG, DONE, S_ERROR);

    --Intern signals from the control unit
    signal State      : state_type := IDLE;
    signal Next_State : state_type;

    begin

        Transition: process(Start_i, UartACK_s)
        begin

            case( State ) is
            
                when IDLE =>
                        if Start_i = '1' then
                            Next_State <= CONFIG;
                        else
                            Next_State <= IDLE;
                        end if;
                when CONFIG =>
                            

                when DONE => Next_State <= DONE;
                when S_ERROR => null,
            end case ;

        end process;

        Reg: process( clk_i )
        begin
            if rising_edge (clk_i) then
                if rst_i = '1' then
                    State <= IDLE;
                else
                    State <= Next_State;
                end if;

                if  rst_i = '1' then
                    Config_done_s <= '0';
                else
                    case( Next_State ) is
                        when IDLE    => Config_done_s <= '0';
                        when CONFIG  => Config_done_s <= '0';
                        when DONE    => Config_done_s <= '1';
                        when S_ERROR => null;
                    end case ;
                end if ;
            end if ;
        end process; 

    end block;

end arch ; -- arch


