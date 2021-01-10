

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_Interface is
    generic(
        BitWidthM1_g    : integer;
        BitsM1_g        : integer; 
        Parity_on_c     : integer;
        Parity_odd_c    : integer; 
        StopBits_c      : integer
    );
    port (
        --Clock ins, SYS_CLK = 50 MHz
        clk_i : in  std_logic;
        rst_i : in std_logic;

        Data_i  : in std_logic_vector(31 downto 0);
        Data_o  : out std_logic_vector(31 downto 0);

        WEn_i       : in std_logic;
        Valid_i     : in std_logic;
        Ack_o       : out std_logic;
        Tx_Ready_o  : out std_logic;
        Rx_Ready_o  : out std_logic;

        TX_o        : out std_logic;  --UART TX
        RX_i        : in std_logic   --UART RX
    );
end entity UART_Interface;

architecture rtl of UART_Interface is

    signal STB_s        : std_logic := '0';
    signal WE_s         : std_logic := '0';
    signal ADR_s        : std_logic_vector(3 downto 0) := (others => '0');
    signal ACK_s        : std_logic;
    signal Data_i_s     : std_logic_vector(31 downto 0) := (others => '0');


    function cr_value return std_logic_vector is
		variable r : std_logic_vector(31 downto 0);				
	begin
		r := (others=>'0');
	    r(15 downto  0) := std_logic_vector(to_unsigned(BitWidthM1_g, 16));
		r(19 downto 16) := std_logic_vector(to_unsigned(BitsM1_g - 1, 4));
		if Parity_on_c = 1 then
			r(20) := '1';			
		end if;
		if Parity_odd_c = 0 then
			r(21) := '1';			
		end if;
		if    StopBits_c = 0 then  --1.0
			r(23 downto 22) := "00";
		elsif StopBits_c = 1 then
			r(23 downto 22) := "01"; --1.5
		elsif StopBits_c = 2 then
			r(23 downto 22) := "10"; --2.0
		elsif StopBits_c = 3 then
			r(23 downto 22) := "11"; --2.5
		else
			r(23 downto 22) := "XX";			
			report "bad value for stoppbits" severity failure;
		end if;
        
        --Interrupts enabled
        r(25 downto 24) := "11";			

		return r;
	end function;


begin

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

    DataTransmision: process( clk_i )
    variable config_done_v      : natural range 0 to 1 := 0;
    constant Ctrl_Reg_Value_c   : std_logic_vector(31 downto 0) := cr_value;       
    constant TDR_Adr_c          : unsigned(3 downto 0) := x"0";
    constant RDR_Adr_c          : unsigned(3 downto 0) := x"4";
    constant CR_Adr_c           : unsigned(3 downto 0) := x"8";

    begin

        if rising_edge(clk_i) then

            if rst_i = '1' then

                config_done_v := 0;
            else

                if config_done_v = 0 then
                    
                    STB_s <= '1';
                    WE_s <= '1';
                    ADR_s <= std_logic_vector(CR_Adr_c);
                    Data_i_s <= Ctrl_Reg_Value_c;
                    Ack_o <= '0';
                    config_done_v := 1;

                else

                    STB_s <= Valid_i;
                    WE_s <= WEn_i;
                    Ack_o <= ACK_s;

                    if Valid_i = '1' and WEn_i = '1' then

                        ADR_s <= std_logic_vector(TDR_Adr_c);
                        Data_i_s <= Data_i;

                    elsif Valid_i = '1' and WEn_i = '0' then

                        ADR_s <= std_logic_vector(RDR_Adr_c);

                    else

                        ADR_s <= ADR_s;
                        Data_i_s <= Data_i_s;
                        STB_s <= '0';

                    end if ;
                end if;
            end if;

        end if ;
        
    end process ; -- Transition
    
end architecture rtl ; -- arch


