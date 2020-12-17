library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divider is
    generic(
        --Equals the 2^DIVISOR_LENGTH number divided by the number in the denominator
        CONST_VAL           : positive;  
        CONST_VAL_LENGTH    : positive;
        --Variable value length
        VAR_VAL_LENTH       : positive
    );
    port (
        clock_i     : std_logic;
        divide_i    : std_logic;
        val_i       : std_logic_vector(VAR_VAL_LENTH - 1 downto 0);
        result_o    : std_logic_vector(VAR_VAL_LENTH - 1 downto 0);
        div_ready_o : std_logic    
    ) ;
end entity Divider ;

architecture rtl of Divider is

    constant const_value_c  : unsigned(CONST_VAL_LENGTH - 1 downto 0) := to_unsigned(CONST_VAL,CONST_VAL_LENGTH);

    signal const_result_s   : unsigned((CONST_VAL_LENGTH + VAR_VAL_LENTH)-1 downto 0) := (others => '0');
    signal result_i_s       : unsigned(VAR_VAL_LENTH - 1 downto 0) := (others => '0');
    signal div_ready_s      : std_logic;

begin

    Dividor: process( clock_i )
    begin
        
        if rising_edge(clock_i) then

            div_ready_s <= '0';

            if divide_i = '1' then

                const_result_s <= unsigned(val_i)  * const_value_c + (2**(CONST_VAL_LENGTH - 1));
                result_i_s <= const_result_s(const_result_s'length - 1 downto const_value_c'length - 1)

                if result_i_s /= '0' then
                    div_ready_s <= '1';
                end if; 
            end if ;
        end if;
    end process ; 

    --Output signals
    process(result_i_s, div_ready_s)
    begin
        result_o <= std_logic_vector(result_i_s);
        div_ready_o <= div_ready_s;
    end process ; -- 

end architecture rtl; -- arch