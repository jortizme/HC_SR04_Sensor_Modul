------------------------------------------------------------------------------
-- Serieller Sender
-------------------------------------------------------------------------------
-- Modul Digitale Komponenten
-- Hochschule Osnabrueck
-- Bernhard Lang, Rainer Hoeckmann
-------------------------------------------------------------------------------
-- BitBreiteM1 = (Taktfrequenz / Baudrate) - 1
--
-- Bits = AnzahlBits - 1
--
-- Kodierung Stoppbits:
--   00 - 1   Stoppbits
--   01 - 1,5 Stobbits
--   10 - 2   Stoppbits
--   11 - 2,5 Stoppbits
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Serieller_Sender is
	generic(
		DATA_WIDTH  	  	: positive;
		BITBREITE_WIDTH 	: positive;
		BITS_WIDTH		  	: positive
	);	
	port(	
		Takt			  	: in  std_ulogic;
		Reset               : in  std_logic;

		BitBreiteM1 		: in  std_ulogic_vector(BITBREITE_WIDTH - 1 downto 0);
		Bits  		  	    : in  std_ulogic_vector(BITS_WIDTH - 1 downto 0);
		Paritaet_ein	  	: in  std_ulogic;
		Paritaet_gerade	  	: in  std_ulogic;
		Stoppbits		  	: in  std_ulogic_vector(1 downto 0);

		S_Valid			    : in  std_ulogic;
		S_Ready			    : out std_ulogic;
		S_Data			  	: in  std_ulogic_vector(DATA_WIDTH - 1 downto 0);

		TxD				  	: out std_ulogic
	);
end entity;

architecture rtl of Serieller_Sender is	
	
	-- Typ fuer die Ansteuerung des Multiplexers
	type TxDSel_type is (D, P, H, L);

	-- Signale zwischen Steuerwerk und Rechenwerk
	signal TxDSel    : TxDSel_type := H;
	signal ShiftEn   : std_ulogic;
	signal ShiftLd   : std_ulogic;
	signal CntSel    : std_ulogic := '-';
	signal CntEn     : std_ulogic;
	signal CntLd     : std_ulogic;
	signal CntTc     : std_ulogic := '1';	--Warum ist das auf High? Es sollte '0' sein
	signal BBSel     : std_ulogic := '0';
	signal BBLd      : std_ulogic;
	signal BBTC      : std_ulogic := '0';
	
begin
	Rechenwerk: block
	
	    -- Interne Signale des Rechenwerks
		signal DataBit   : std_ulogic := '0';
		signal ParityBit : std_ulogic := '0';
		signal MultiplexZaehlerOut	:	std_ulogic_vector (BITS_WIDTH - 1 downto 0)	:= (others =>'0');
		
	begin
		-- Schieberegister zur Aufnahme der Sendedaten
		Schieberegister: process(Takt)
			variable Q : std_ulogic_vector(DATA_WIDTH - 1 downto 0) := (others=>'0');
		begin
			if rising_edge(Takt) then	

				if Reset = '1' then
					Q := (others => '0');
				elsif ShiftLd = '1' then
					Q := S_Data;
				elsif ShiftEn = '1' then
					Q(DATA_WIDTH - 2 downto 0) := Q(DATA_WIDTH - 1 downto 1);					
				end if;

				Databit <= Q(0);

			end if;			
		end process;
		
		-- Register fuer das Paritaetsbit
		FF: process(Takt)
			variable p : std_ulogic := '0';
		begin
			if rising_edge(Takt) then
			
				if Reset = '1' then
					p := '0';
				elsif ShiftLd = '1' then
					p := not Paritaet_gerade;
					
					for i in S_Data'range loop
						if i <= unsigned(Bits) then
							p := p xor S_Data(i);
						end if;
					end loop;
					
					ParityBit <= p;
				end if;
				
			end if;
		end process;
		
		-- Zaehler Bits und Stoppbits
		ZaehlerBits: process(Takt)
			variable Q : unsigned(BITS_WIDTH - 1 downto 0) := (others=>'0');
			variable DemultiplexOut : unsigned(BITS_WIDTH - 1 downto 0) := (others=>'0'); 
			
		begin

			case( CntSel ) is
				when '0' =>	
							DemultiplexOut := unsigned(Bits); 
				when '1' =>
							case( Stoppbits ) is
								when "00" => DemultiplexOut := to_unsigned(0, Bits'length);
								when "01" => DemultiplexOut := to_unsigned(1, Bits'length);
								when "10" => DemultiplexOut := to_unsigned(2, Bits'length);
								when "11" => DemultiplexOut := to_unsigned(3, Bits'length);
								when others => null;
							end case;
				when others => null;
			end case;

			if rising_edge(Takt) then

				if Reset = '1' then
					Q := (others=>'0');
				elsif CntLd = '1' then
					Q := DemultiplexOut;	
				elsif CntEn = '1' then
					Q := Q - 1;	
				end if;	

				if Q = 0 then
					CntTC <= '1';
				else
					CntTC <= '0';
				end if;

			end if;
		end process;
		
		-- Zaehler Bitbreite
		ZaehlerBitbreite: process(Takt)
			variable Q : unsigned(BITBREITE_WIDTH - 1 downto 0) := (others=>'0');
			variable OutputMultiplexer : std_ulogic_vector( BITBREITE_WIDTH - 1 downto 0 ) := (others=>'0');

		begin

			case( BBSel ) is
				
				when '0' =>
							OutputMultiplexer := BitBreiteM1;
				when '1' =>
							OutputMultiplexer := std_ulogic_vector(unsigned(BitBreiteM1) / 2);		
				when others => null;
			end case ;

			if rising_edge(Takt) then

				if Reset = '1' then
					Q := (others => '0');
				elsif BBLd = '1' or BBTC = '1' then
					Q:= unsigned(OutputMultiplexer);
					BBTC <= '0';
				else
					Q := Q - 1;
					if Q = 0 then
						BBTC <= '1';		
					end if;
				end if;

			end if;
		end process;
		
		-- Ausgangsmultiplexer
		OutMux: process(TxDSel, DataBit, ParityBit)
		begin

			case( TxDsel ) is
			
				when L =>	TxD <= '0';	
				when H =>	TxD <= '1';
				when P =>	TxD <= ParityBit;
				when D =>	TxD <= DataBit;	
				when others => null;

			end case ;	
		end process;
	end block;
	
	Steuerwerk: block
	
		-- Typ fuer die Zustandswerte
		type Zustand_type is (Z_IDLE, Z_START, Z_BITS, Z_PARI, Z_STP, Z_ERROR);

	    -- Interne Signale des Rechenwerks
		signal Zustand      : Zustand_type := Z_IDLE;
		signal Folgezustand : Zustand_type;		
		
		-- Internes Signal fuer die Initialisierung
		signal S_Ready_i    : std_ulogic := '1';
		
	begin	
		-- Wert des internen Signals an Port zuweisen	
		process(S_Ready_i)
		begin
			S_Ready <= S_Ready_i;
		end process;

		-- Prozess zur Berechnung des Folgezustands und der Mealy-Ausgaenge
		Transition: process(Zustand, S_Valid, BBTC, CntTC, Paritaet_ein)
		begin
			
			-- Default-Werte fuer den Folgezustand und die Mealy-Ausgaenge
			ShiftEn      <= '0'; 
			ShiftLd      <= '0'; 
			CntEn        <= '0'; 
			CntLd        <= '0'; 
			BBLd         <= '0';
			Folgezustand <= Z_ERROR;
			
			case( Zustand ) is
			
				when Z_IDLE  =>	
								if S_Valid = '0' then
									Folgezustand <= Z_IDLE;
								
								elsif S_Valid = '1' then
									ShiftLd <= '1';
									BBLd <= '1';
									Folgezustand <= Z_START;
								end if;
				when Z_START  =>
								if BBTC = '0' then
									Folgezustand <= Z_START;
								
								elsif BBTC = '1' then
									CntLd <= '1';
									Folgezustand <= Z_BITS;
								end if;
				when Z_BITS  =>
								if BBTC = '0'  then
									Folgezustand <= Z_BITS;

								elsif BBTC = '1' and CntTC = '0' then
									CntEn <= '1';
									ShiftEn <= '1';
									Folgezustand <= Z_BITS;

								elsif Paritaet_ein = '1' and BBTC = '1' and CntTC = '1' then
									Folgezustand <= Z_PARI;
								
								elsif Paritaet_ein = '0' and BBTC = '1' and CntTC = '1' then
									CntLd <= '1';
									Folgezustand <= Z_STP;
								end if;															
				when Z_PARI  =>
								if BBTC = '0' then
									Folgezustand <= Z_PARI;
								
								elsif BBTC = '1' then
									CntLd <= '1';
									Folgezustand <= Z_STP;				
								end if ;
				when Z_STP  =>	
								if BBTC = '0' then
									Folgezustand <= Z_STP;
								
								elsif BBTC = '1' and CntTC = '0' then
									CntEn <= '1';
									Folgezustand <= Z_STP;
								
								elsif BBTC = '1' and CntTC = '1' then
									Folgezustand <= Z_IDLE;																		
								end if ;
				when Z_ERROR =>	null;

			end case ;	
		end process;
		
		-- Register fuer Zustand und Moore-Ausgaenge
		Reg: process(Takt)
		begin
			if rising_edge(Takt) then

				if Reset = '1' then
					Zustand <= Z_IDLE;
				else
					Zustand <= Folgezustand;
				end if;

				if Reset = '1' then
					S_Ready_i <= '1'; TxDSel <= H; CntSel <= '-'; BBSel <= '0';
				else
					case( Folgezustand ) is
						when Z_IDLE =>
										S_Ready_i <= '1';
										TxDSel <= H;
										CntSel <= '-';
										BBSel <= '0';
						when Z_START =>
										S_Ready_i <= '0';
										TxDSel <= L;
										CntSel <= '0';
										BBSel <= '0';
						when Z_BITS =>
										S_Ready_i <= '0';
										TxDSel <= D;
										CntSel <= '1';
										BBSel <= '0';
						when Z_PARI =>
										S_Ready_i <= '0';
										TxDSel <= P;
										CntSel <= '1';
										BBSel <= '0';
						when Z_STP =>
										S_Ready_i <= '0';
										TxDSel <= H;
										CntSel <= '-';
										BBSel <= '1';
						when Z_ERROR =>
										S_Ready_i <= 'X';
										TxDSel <= H;
										CntSel <= '-';
										BBSel <= 'X';
						end case;
					end if;
			end if;
		end process;
			
	end block;
end architecture;