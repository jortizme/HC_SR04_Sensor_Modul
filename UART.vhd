---------------------------------------------------------------------------------------------------
-- UART fuer Beispielrechner
-- Bernhard Lang, Rainer Hoeckmann
-- (c) Hochschule Osnabrueck
---------------------------------------------------------------------------------------------------
-- Offsets:
-- 0x00 Transmit Data Register (TDR)
-- 0x04 Receive Data Register (RDR)
-- 0x08 Control Register (CR)
-- 0x0C Status Register (SR)
---------------------------------------------------------------------------------------------------
-- Control Register (CR):
--  15..0  : Bitbreite - 1
--  19..16 : Anzahl Datenbits - 1
--  20     : Paritaet ein
--  21     : Paritaet gerade
--  23..22 : Stopbits 
--           0: 1.0 Stoppbits
--           1: 1.5 Stoppbits
--           2: 2.0 Stoppbits
--           3: 2.5 Stoppbits
--  24     : Freigabe Rx Interrupt
--  25     : Freigabe Tx Interrupt
---------------------------------------------------------------------------------------------------
-- Status Register (SR):
--  0      : Puffer_Valid
--  1      : Sender_Ready
--  2      : Ueberlauf (wird beim Lesen geloescht)
--  24     : Rx_IRQ
--  25     : Tx_IRQ
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity UART is
	port (
		-- Wishbone Bus
		CLK_I              : in  std_logic;
		RST_I              : in  std_logic;
		STB_I              : in  std_logic;
		WE_I               : in  std_logic;
		ADR_I              : in  std_logic_vector(3 downto 0);
		DAT_I              : in  std_logic_vector(31 downto 0);
		DAT_O              : out std_logic_vector(31 downto 0);
		ACK_O              : out std_logic;
		-- Interupt
		TX_Interrupt       : out std_logic;
		RX_Interrupt       : out std_logic;		
		-- Port Pins
		RxD                : in  std_logic;
		TxD                : out std_logic
	);
end UART;

library IEEE;
use IEEE.numeric_std.all;

architecture behavioral of UART is
	constant DATA_WIDTH  	   : positive := 16;
	constant BITBREITE_WIDTH   : positive := 16;
	constant BITS_WIDTH		   : positive := 4;

	signal Kontroll            : std_logic_vector(31 downto 0) := (others=>'0');
	signal Status              : std_logic_vector(31 downto 0) := (others=>'0');
	signal Ueberlauf           : std_logic                     := '0';

	signal Schreibe_Daten      : std_logic;
	signal Schreibe_Kontroll   : std_logic;
	signal Lese_Status         : std_logic;

	signal BitBreiteM1         : std_logic_vector(BITBREITE_WIDTH - 1 downto 0);
	signal BitsM1  		       : std_logic_vector(BITS_WIDTH - 1 downto 0);
	signal Paritaet_ein        : std_logic;
	signal Paritaet_gerade     : std_logic;
	signal Stoppbits  		   : std_logic_vector(1 downto 0);	
	signal Rx_IrEn             : std_logic;
	signal Tx_IrEn             : std_logic;
	signal Rx_Interrupt_i      : std_logic := '0';
	signal Tx_Interrupt_i      : std_logic := '0';

	signal Sender_Ready	       : std_logic;

	signal Empfaenger_Valid	   : std_logic;
	signal Empfaenger_Ready	   : std_logic;
	signal Empfaenger_Data     : std_logic_vector(15 downto 0);

	signal Puffer_Valid	       : std_logic := '0';
	signal Puffer_Ready        : std_logic;
	signal Puffer_Data         : std_logic_vector(15 downto 0);

begin
	ACK_O              <= STB_I;
	TX_Interrupt       <= Tx_Interrupt_i;
	RX_Interrupt       <= Rx_Interrupt_i;
	Tx_Interrupt_i     <= Tx_IrEn and Sender_Ready;
	Rx_Interrupt_i     <= Rx_IrEn and Puffer_Valid;

	-- Statusregister mit Statussignalen verbinden
    Status( 0) <= Puffer_Valid;
    Status( 1) <= Sender_Ready;
    Status( 2) <= Ueberlauf;
	Status(24) <= Rx_Interrupt_i;
	Status(25) <= Tx_Interrupt_i;
	
    -- Kontrollregister mit Steuersignalen verbinden
	BitBreiteM1     <= std_logic_vector(Kontroll(15 downto 0));
	BitsM1          <= std_logic_vector(Kontroll(19 downto 16));
	Paritaet_ein    <= Kontroll(20);
	Paritaet_gerade <= Kontroll(21);
	Stoppbits       <= std_logic_vector(Kontroll(23 downto 22));
	Rx_IrEn         <= Kontroll(24);
	Tx_IrEn         <= Kontroll(25);

	Decoder: process(STB_I, ADR_I, WE_I)
	begin
		-- Default-Werte
		Schreibe_Kontroll <= '0';
		Schreibe_Daten    <= '0';
		Puffer_Ready      <= '0';
		Lese_Status       <= '0';

		if STB_I = '1' then
			if WE_I = '1' then
				if    ADR_I = x"0" then Schreibe_Daten    <= '1';
				elsif ADR_I = x"8" then Schreibe_Kontroll <= '1';
				end if;
			elsif WE_I = '0' then
				if    ADR_I = x"4" then Puffer_Ready      <= '1';
				elsif ADR_I = x"C" then Lese_Status       <= '1';
				end if;
			end if;		
		end if;
	end process;

	Lesedaten_MUX: process(ADR_I, Puffer_Data, Kontroll, Status)
	begin
		DAT_O <= (others=>'0');
		
		if    ADR_I = x"4" then DAT_O(Puffer_Data'range) <= Puffer_Data;
		elsif ADR_I = x"8" then DAT_O(Kontroll'range)    <= Kontroll;
		elsif ADR_I = x"C" then DAT_O(Status'range)      <= Status;
		end if;		
	end process;

	-- Kontrollregister
	Regs: process(CLK_I)
	begin
		if rising_edge(CLK_I) then
			if RST_I = '1' then
				Kontroll <= x"00000000";
			elsif Schreibe_Kontroll = '1' then
				Kontroll <= DAT_I;
			end if;
		end if;
	end process;
	
	-- Ueberlauferkennung
	OverflowReg: process(CLK_I)
	begin
		if rising_edge(CLK_I) then	
			if RST_I = '1' then
				Ueberlauf <= '0';
			else
				-- Beim Lesen von Status zuruecksetzen
				if Lese_Status = '1' then
					Ueberlauf <= '0';
				end if;
				
				-- Setzen bei erkanntem Ueberlauf
				if Empfaenger_Valid = '1' and Empfaenger_Ready = '0' then
					Ueberlauf <= '1';
				end if;				
			end if;
		end if;
	end process;
	
	-- Puffer fuer Empfangene Daten
	PufferReg: block
	begin
		process(CLK_I)
		begin
			if rising_edge(CLK_I) then
				if RST_I = '1' then
					Puffer_Valid <= '0';
					Puffer_Data  <= (others=>'0');
				else			
					if Empfaenger_Ready = '1' then
						Puffer_Valid <= Empfaenger_Valid;
						Puffer_Data  <= Empfaenger_Data;
					end if;					
				end if;				
			end if;
		end process;

		Empfaenger_Ready <= (not Puffer_Valid) or Puffer_Ready;
	end block;	

	Empfaenger: entity work.Serieller_Empfaenger
	generic map(
		DATA_WIDTH  	  	=> DATA_WIDTH,
		BITBREITE_WIDTH 	=> BITBREITE_WIDTH,
		BITS_WIDTH		  	=> BITS_WIDTH
	) port map(
		Takt			  	=> CLK_I,
		Reset               => RST_I,
		BitBreiteM1 		=> BitBreiteM1,
		Bits  		  	    => BitsM1,
		Paritaet_ein	  	=> Paritaet_ein,
		Paritaet_gerade	  	=> Paritaet_gerade,
		Stoppbits		  	=> Stoppbits,
		M_Valid			    => Empfaenger_Valid,
		M_Data			  	=> Empfaenger_Data,
		RxD				  	=> Rxd
	);

	Sender: entity work.Serieller_Sender
	generic map(
		DATA_WIDTH  	  	=> DATA_WIDTH,
		BITBREITE_WIDTH 	=> BITBREITE_WIDTH,
		BITS_WIDTH		  	=> BITS_WIDTH
	)	
	port map(	
		Takt			  	=> CLK_I,
		Reset               => RST_I,

		BitBreiteM1 		=> std_ulogic_vector(BitBreiteM1),
		Bits  		  	    => std_ulogic_vector(BitsM1),
		Paritaet_ein	  	=> Paritaet_ein,
		Paritaet_gerade	  	=> Paritaet_gerade,
		Stoppbits		  	=> std_ulogic_vector(Stoppbits),

		S_Valid			  	=> Schreibe_Daten,
		S_Ready			    => Sender_Ready,
		S_Data			  	=> std_ulogic_vector(DAT_I(DATA_WIDTH-1 downto 0)),
		
		TxD					=> TxD
	);
end behavioral;

