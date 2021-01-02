

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity hc_sr04Touart is
    generic(
        BitWidthM1_g    : positive;
        BitsM1_g        : positive; 
        Parity_on_c     : positive;
        Parity_odd_c    : positive; 
        StopBits_c      : positive
    );
    port (
        --Clock ins, SYS_CLK = 50 MHz
        clk_i : in  std_logic;
        rst_i : in std_logic;

        Data_i  : in std_logic_vector(31 downto 0);
        Data_o  : out std_logic(31 downto 0);

        WEn_i        : in std_logic;
        Valid_i     : in std_logic;
        Ack_o       : out std_logic;
        Tx_Ready_o  : out std_logic;
        Rx_Ready_o  : out std_logic;

        Cfg_done_o  : out std_logic;

        TX_o        : out std_logic;  --UART TX
        RX_i        : in std_logic   --UART RX
    );
end entity hc_sr04Touart;

architecture arch of ent is

    --constant BitWidthM1_c   : unsigned(15 downto 0) :=  433;      --(SYS_CLK/BAUDRATE - 1) in this case  115200
    --constant BitsM1_c       : unsigned(3 downto 0)  :=  7;        --(Amount of bits per frame - 1)
    --constant Parity_on_c    : std_logic := '0';                   -- Parity on
    --constant Parity_odd_c   : std_logic := '0';
    --constant StopBits_c     : unsigned(1 downto 0)  := 0;         --0: 1.0 Stoppbits, 1: 1.5 Stoppbits, 2: 2.0 Stoppbits, 3: 2.5 Stoppbits

    signal UartCtrl_RG_s    : std_logic_vector(31 downto 0) := (others => '0');
    signal STB_s        : std_logic;
    signal WE_s         : std_logic;
    signal ADR_s        : std_logic_vector(3 downto 0);
    signal ACK_s        : std_logic;
    signal DCfg_i_s     : std_logic_vector(31 downto 0) := (others => '0');
    signal Data_i_s     : std_logic_vector(31 downto 0);
    signal Config_done_s    : std_logic := '0';

begin

    Data_i_s <= Data_i when Config_done_s = '1' else DCfg_i_s;

    UART: entity work.UART
    port map (
		-- Wishbone Bus
		CLK_I              => clk_i,
		RST_I              => rst_i,
		STB_I              => STB_s,
		WE_I               => WE_s ,
		ADR_I              => ADR_s,
		DAT_I              => Data_i_s,
        DAT_O              => Data_o,
		ACK_O              => ACK_s,
		-- Interupt
		TX_Interrupt       => Tx_Ready_o,
		RX_Interrupt       => Rx_Ready_o,		
		-- Port Pins
		RxD                => RX_i,
		TxD                => TX_o
    );

    Config:block

    --Typ for state values
    type state_type is (CONFIG, DONE, WAIT_ACK, S_ERROR);

    --Intern signals from the control unit
    signal State            : state_type := CONFIG;
    signal Next_State       : state_type;

    begin

        --Signal to the output
        Cfg_done_o <= Config_done_s;

        Transition: process(State, ACK_s)
        begin

            case( State ) is

                when CONFIG =>
                            DCfg_i_s(15 downto 0) <= std_logic_vector(to_unsigned(BitWidthM1_g, 16));
                            DCfg_i_s(19 downto 16) <= std_logic_vector(to_unsigned(BitsM1_g, 4));
                            DCfg_i_s(20) <= '1' when Parity_on_c = 1 else '0';
                            DCfg_i_s(21) <= '1' when Parity_odd_c = 1 else '0';
                            DCfg_i_s(23 downto 22) <= std_logic_vector(to_unsigned(StopBits_c, 2));
                            DCfg_i_s(24 downto 25) <= "11";

                            --Set the control bus signals
                            WE_s <= '1';        --Write
                            ADR_s <= x"8";      --To the control register
                            STB_s <= '1';       --strobe signal

                            Next_State <= WAIT_ACK;

                when WAIT_ACK =>
                            if ACK_s <= '1' then
                                STB_s <= '0';       --strobe signal
                                Next_State <= DONE;
                            else
                                Next_State <= WAIT_ACK,
                            end if ;

                when DONE => Next_State <= DONE;
                when S_ERROR => null,
            end case ;

        end process;

        Reg: process( clk_i )
        begin
            if rising_edge (clk_i) then
                if rst_i = '1' then
                    State <= CONFIG;
                else
                    State <= Next_State;
                end if;

                if  rst_i = '1' then
                    Config_done_s <= '0';
                else
                    case( Next_State ) is
                        when CONFIG  => Config_done_s <= '0';
                        when DONE    => Config_done_s <= '1';
                        when S_ERROR => null;
                    end case ;
                end if ;
            end if ;
        end process;

    end block;

    Operation:block
    begin

        DataTransmision: process( clk_i )
        begin

            if rising_edge(clk_i) then

                WE_s <= WEn_i;
                STB_s <= Valid_i;

                if Valid_i = '1' and WEn_i = '1' then
                    --Write data to be trasmited
                    ADR_s <= x"0";
                elsif Valid_i = '1' and WEn_i = '0' then
                    --Read data received from UART
                    ADR_s <= x"4";
                end if ;
            end if ;
            
        end process ; -- Transition
        
        --ACK signal from UART to the output 
        Ack_o <= ACK_s;

    end block;

end arch ; -- arch


