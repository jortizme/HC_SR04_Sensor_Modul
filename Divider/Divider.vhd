library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divider is
    generic(
        --Equals the 2^CONST_VAL_LENGTH number divided by the number in the denominator
        CONST_VAL           : integer;  
        CONST_VAL_LENGTH    : integer;
        --Variable value length
        VAR_VAL_LENTH       : integer
    );
    port (
        clock_i     : in std_logic;
        divide_i    : in std_logic;
        val_i       : in std_logic_vector(VAR_VAL_LENTH - 1 downto 0);
        result_o    : out std_logic_vector(VAR_VAL_LENTH - 1 downto 0)   
    );
end entity Divider ;

architecture rtl of Divider is

begin

    Dividor: process( clock_i )
    variable const_result_s   : unsigned((CONST_VAL_LENGTH + VAR_VAL_LENTH)-1 downto 0) := (others => '0');
    constant const_value_c    : unsigned(CONST_VAL_LENGTH - 1 downto 0) := to_unsigned(CONST_VAL, CONST_VAL_LENGTH);
    constant const_summand_c   : unsigned(const_result_s'length -1 downto 0) :=   to_unsigned(2**(CONST_VAL_LENGTH - 1), const_result_s'length);
    begin
        
        if rising_edge(clock_i) then

            if divide_i = '1' then
                
                const_result_s := (unsigned(val_i)  * const_value_c) + const_summand_c;
                result_o <= std_logic_vector(const_result_s(const_result_s'length - 1 downto const_value_c'length)); 
            end if ;
        end if;
    end process ; 

end architecture rtl; -- arch