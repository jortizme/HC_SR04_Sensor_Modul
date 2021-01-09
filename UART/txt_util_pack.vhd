-- ZPU
--
-- Copyright 2004-2008 oharboe - Øyvind Harboe - oyvind.harboe@zylin.com
-- 
-- The FreeBSD license
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above
--    copyright notice, this list of conditions and the following
--    disclaimer in the documentation and/or other materials
--    provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE ZPU PROJECT ``AS IS'' AND ANY
-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
-- PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
-- ZPU PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
-- INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
-- STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation
-- are those of the authors and should not be interpreted as representing
-- official policies, either expressed or implied, of the ZPU Project.

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

package txt_util_pack is

  -- prints a message to the screen
  procedure print(s: string);

  -- prints the message when active
  -- useful for debug switches
  procedure print(active: boolean; s: string);

  -- converts std_logic into a character
  function chr(sl: std_logic) return character;

  -- converts time into a string
  function str(ti: TIME) return STRING;
  
  -- converts std_logic into a string (1 to 1)
  function str(sl: std_logic) return string;

  -- converts std_logic_vector into a string (binary base)
  -- function str(slv: std_logic_vector) return string;
  
  -- converts std_ulogic_vector into a string (binary base)
  function str(suv: std_ulogic_vector) return string;

  -- converts boolean into a string
  function str(b: boolean) return string;

  -- converts an integer into a single character
  -- (can also be used for hex conversion and other bases)
  function chr(int: integer) return character;

  -- converts integer into string using specified base
  function str(int: integer; base: integer) return string;

  -- converts integer to string, using base 10
  function str(int: integer) return string;

  -- convert integer into a string in hex format
  function hstr(int: integer) return string;

  -- convert std_logic_vector into a string in hex format
  function hstr(slv: std_logic_vector) return string;

  -- convert std_ulogic_vector into a string in hex format
  function hstr(suv: std_ulogic_vector) return string;

  -- functions to manipulate strings
  -----------------------------------

  -- convert a character to upper case
  function to_upper(c: character) return character;

  -- convert a character to lower case
  function to_lower(c: character) return character;

  -- convert a string to upper case
  function to_upper(s: string) return string;

  -- convert a string to lower case
  function to_lower(s: string) return string;

 
  
  -- functions to convert strings into other formats
  --------------------------------------------------
  
  -- converts a character into std_logic
  function to_std_logic(c: character) return std_logic; 
  
  -- converts a character into std_ulogic
  function to_std_ulogic(c: character) return std_ulogic; 
  
  -- converts a string into std_logic_vector
  function to_std_logic_vector(s: string) return std_logic_vector; 

  -- converts a string into std_ulogic_vector
  function to_std_ulogic_vector(s: string) return std_ulogic_vector; 

  -- file I/O
  -----------
     
  -- read variable length string from input file
  procedure str_read(file in_file: TEXT; res_string: out string);
      
  -- print string to a file and start new line
  procedure print(file out_file: TEXT; new_string: in  string);
  
  -- print character to a file and start new line
  procedure print(file out_file: TEXT; char: in  character);
                    
end package;

package body txt_util_pack is
  function str(ti: TIME) return STRING is
    variable result : STRING(14 downto 1) := "              "; -- longest string is "2147483647 min"
    variable tmp    : NATURAL;
    variable pos    : NATURAL := 1;
    variable digit  : NATURAL;
    variable resol  : TIME := TIME'succ(ti) - ti; -- time resolution
    variable scale  : NATURAL := 1;
    variable unit   : TIME;
  begin	
    
    if resol = 100 sec then scale := 100; unit := 1 sec;
    elsif  resol = 10 sec then scale := 10; unit := 1 sec;
    elsif  resol = 1 sec then scale := 1; unit := 1 sec;
    elsif resol = 100 ms then scale := 100; unit := 1 ms;
    elsif  resol = 10 ms then scale := 10; unit := 1 ms;
    elsif  resol = 1 ms then scale := 1; unit := 1 ms;
    elsif resol = 100 us then scale := 100; unit := 1 us;
    elsif  resol = 10 us then scale := 10; unit := 1 us;
    elsif  resol = 1 us then scale := 1; unit := 1 us;	
    elsif resol = 100 ns then scale := 100; unit := 1 ns;
    elsif  resol = 10 ns then scale := 10; unit := 1 ns;
    elsif  resol = 1 ns then scale := 1; unit := 1 ns;		 
    elsif resol = 100 ps then scale := 100; unit := 1 ps;
    elsif  resol = 10 ps then scale := 10; unit := 1 ps;
    elsif  resol = 1 ps then scale := 1; unit := 1 ps;	
    elsif resol = 100 fs then scale := 100; unit := 1 fs;
    elsif  resol = 10 fs then scale := 10; unit := 1 fs;
    elsif  resol = 1 fs then scale := 1; unit := 1 fs;
    else scale := 0; unit := 1 fs;
    end if;
          
    -- Write unit (reversed order)
    if unit = 1 hr then
      result(pos) := 'r';
      pos := pos + 1;
      result(pos) := 'h';
      pos := pos + 1;
      result(pos) := ' ';
      pos := pos + 1;	
    elsif unit = 1 sec then
      result(pos) := 'c';
      pos := pos + 1;
      result(pos) := 'e';
      pos := pos + 1;
      result(pos) := 's';
      pos := pos + 1;
    elsif unit = 1 ms then
      result(pos) := 's';
      pos := pos + 1;
      result(pos) := 'm';
      pos := pos + 1;
      result(pos) := ' ';
      pos := pos + 1;
    elsif unit = 1 us then
      result(pos) := 's';
      pos := pos + 1;
      result(pos) := 'u';
      pos := pos + 1;
      result(pos) := ' ';
      pos := pos + 1;
    elsif unit = 1 ns then
      result(pos) := 's';
      pos := pos + 1;
      result(pos) := 'n';
      pos := pos + 1;
      result(pos) := ' ';
      pos := pos + 1;
    elsif unit = 1 ps then
      result(pos) := 's';
      pos := pos + 1;
      result(pos) := 'p';
      pos := pos + 1;
      result(pos) := ' ';
      pos := pos + 1;
    elsif unit = 1 fs then
      result(pos) := 's';
      pos := pos + 1;
      result(pos) := 'f';
      pos := pos + 1;
      result(pos) := ' ';
      pos := pos + 1;	
    else
      result(pos) := '?';
      pos := pos + 1;
      result(pos) := '?';
      pos := pos + 1;
      result(pos) := ' ';
      pos := pos + 1;	
    end if;

    -- Convert TIME to NATURAL
    tmp := scale * (ti / resol);
    
    loop
        digit := tmp MOD 10; -- extract last digit
          tmp := tmp / 10;
          result(pos) := character'val(character'pos('0') + digit);
          pos := pos + 1;
          exit when tmp = 0;
    end loop;
    
    -- Return result (put back in right order)
    return result((pos-1) downto 1);
  end function;

  -- prints text to the screen
  procedure print(s: string) is
    variable msg_line: line;
  begin
    write(msg_line, s);
    writeline(output, msg_line);
  end procedure;

  -- prints text to the screen when active
  procedure print(active: boolean; s: string)  is
  begin
    if active then
      print(s);
    end if;
  end procedure;

  -- converts std_logic/std_ulogic into a character
  function chr(sl: std_logic) return character is
    variable c: character;
  begin
    case sl is
      when 'U' => c:= 'U';
      when 'X' => c:= 'X';
      when '0' => c:= '0';
      when '1' => c:= '1';
      when 'Z' => c:= 'Z';
      when 'W' => c:= 'W';
      when 'L' => c:= 'L';
      when 'H' => c:= 'H';
      when '-' => c:= '-';
    end case;
    return c;
  end function;

  -- converts std_logic/std_ulogic into a string (1 to 1)
  function str(sl: std_logic) return string is
    variable s: string(1 to 1);
  begin
    s(1) := chr(sl);
    return s;
  end function;
  
  -- converts std_ulogic_vector into a string (binary base)
  -- (this also takes care of the fact that the range of
  --  a string is natural while a std_ulogic_vector may
  --  have an integer range)
  function str(suv: std_ulogic_vector) return string is
    variable result : string (1 to suv'length);
    variable r : integer;
  begin
    r := 1;
    for i in suv'range loop
      result(r) := chr(suv(i));
      r := r + 1;
    end loop;
    return result;
  end function;
  
  function str(b: boolean) return string is
  begin
    if b then
      return "true";
    else
      return "false";
    end if;
  end function;

  -- converts an integer into a character
  -- for 0 to 9 the obvious mapping is used, higher
  -- values are mapped to the characters A-Z
  -- (this is usefull for systems with base > 10)
  -- (adapted from Steve Vogwell's posting in comp.lang.vhdl)
  function chr(int: integer) return character is
    variable c: character;
  begin
    case int is
      when  0 => c := '0';
      when  1 => c := '1';
      when  2 => c := '2';
      when  3 => c := '3';
      when  4 => c := '4';
      when  5 => c := '5';
      when  6 => c := '6';
      when  7 => c := '7';
      when  8 => c := '8';
      when  9 => c := '9';
      when 10 => c := 'A';
      when 11 => c := 'B';
      when 12 => c := 'C';
      when 13 => c := 'D';
      when 14 => c := 'E';
      when 15 => c := 'F';
      when 16 => c := 'G';
      when 17 => c := 'H';
      when 18 => c := 'I';
      when 19 => c := 'J';
      when 20 => c := 'K';
      when 21 => c := 'L';
      when 22 => c := 'M';
      when 23 => c := 'N';
      when 24 => c := 'O';
      when 25 => c := 'P';
      when 26 => c := 'Q';
      when 27 => c := 'R';
      when 28 => c := 'S';
      when 29 => c := 'T';
      when 30 => c := 'U';
      when 31 => c := 'V';
      when 32 => c := 'W';
      when 33 => c := 'X';
      when 34 => c := 'Y';
      when 35 => c := 'Z';
      when others => c := '?';
    end case;
    return c;
  end function;

   -- convert integer to string using specified base
   -- (adapted from Steve Vogwell's posting in comp.lang.vhdl)
  function str(int: integer; base: integer) return string is
    variable temp:      string(1 to 10);
    variable num:       integer;
    variable abs_int:   integer;
    variable len:       integer := 1;
    variable power:     integer := 1;
  begin
    -- bug fix for negative numbers
    abs_int := abs(int);
    num     := abs_int;
    while num >= base loop                     -- Determine how many
      len := len + 1;                          -- characters required
      num := num / base;                       -- to represent the
    end loop ;                                 -- number.
    for i in len downto 1 loop                 -- Convert the number to
      temp(i) := chr(abs_int/power mod base);  -- a string starting
      power := power * base;                   -- with the right hand
    end loop ;                                 -- side.
    -- return result and add sign if required
    if int < 0 then
       return '-'& temp(1 to len);
     else
       return temp(1 to len);
    end if;
  end function;

  function hstr(int: integer) return string is
    variable temp:      string(1 to 10);
    variable num:       integer;
    variable abs_int:   integer;
    variable len:       integer := 1;
    variable power:     integer := 1;
    constant base:      integer := 16;
  begin
    -- bug fix for negative numbers
    abs_int := abs(int);
    num     := abs_int;
    while num >= base loop                     -- Determine how many
      len := len + 1;                          -- characters required
      num := num / base;                       -- to represent the
    end loop ;                                 -- number.
    for i in len downto 1 loop                 -- Convert the number to
      temp(i) := chr(abs_int/power mod base);  -- a string starting
      power := power * base;                   -- with the right hand
    end loop ;                                 -- side.
    -- return result and add sign if required
    if int < 0 then
       return '-'& temp(1 to len);
     else
       return temp(1 to len);
    end if;
  end function;

  -- convert integer to string, using base 10
  function str(int: integer) return string is
  begin
    return str(int, 10) ;
  end function;

  function hstr(slv: std_logic_vector) return string is
  begin
	return hstr(std_ulogic_vector(slv));
  end function;
  
  -- converts a std_ulogic_vector into a hex string.
  function hstr(suv: std_ulogic_vector) return string is
    variable hexlen: integer;
    variable longsuv : std_ulogic_vector(67 downto 0) := (others => '0');
    variable hex : string(1 to 16);
    variable fourbit : std_ulogic_vector(3 downto 0);
  begin
    hexlen := (suv'left+1)/4;
    if (suv'left+1) mod 4 /= 0 then
      hexlen := hexlen + 1;
    end if;
    longsuv(suv'left downto 0) := suv;
    for i in (hexlen -1) downto 0 loop
      fourbit := longsuv(((i*4)+3) downto (i*4));
      case fourbit is
        when "0000" => hex(hexlen -I) := '0';
        when "0001" => hex(hexlen -I) := '1';
        when "0010" => hex(hexlen -I) := '2';
        when "0011" => hex(hexlen -I) := '3';
        when "0100" => hex(hexlen -I) := '4';
        when "0101" => hex(hexlen -I) := '5';
        when "0110" => hex(hexlen -I) := '6';
        when "0111" => hex(hexlen -I) := '7';
        when "1000" => hex(hexlen -I) := '8';
        when "1001" => hex(hexlen -I) := '9';
        when "1010" => hex(hexlen -I) := 'A';
        when "1011" => hex(hexlen -I) := 'B';
        when "1100" => hex(hexlen -I) := 'C';
        when "1101" => hex(hexlen -I) := 'D';
        when "1110" => hex(hexlen -I) := 'E';
        when "1111" => hex(hexlen -I) := 'F';
        when "ZZZZ" => hex(hexlen -I) := 'z';
        when "UUUU" => hex(hexlen -I) := 'u';
        when "XXXX" => hex(hexlen -I) := 'x';
        when others => hex(hexlen -I) := '?';
      end case;
    end loop;
    return hex(1 to hexlen);
  end function;

   -- functions to manipulate strings
   -----------------------------------

  -- convert a character to upper case
  function to_upper(c: character) return character is
    variable u: character;
  begin
    case c is
      when 'a' => u := 'A';
      when 'b' => u := 'B';
      when 'c' => u := 'C';
      when 'd' => u := 'D';
      when 'e' => u := 'E';
      when 'f' => u := 'F';
      when 'g' => u := 'G';
      when 'h' => u := 'H';
      when 'i' => u := 'I';
      when 'j' => u := 'J';
      when 'k' => u := 'K';
      when 'l' => u := 'L';
      when 'm' => u := 'M';
      when 'n' => u := 'N';
      when 'o' => u := 'O';
      when 'p' => u := 'P';
      when 'q' => u := 'Q';
      when 'r' => u := 'R';
      when 's' => u := 'S';
      when 't' => u := 'T';
      when 'u' => u := 'U';
      when 'v' => u := 'V';
      when 'w' => u := 'W';
      when 'x' => u := 'X';
      when 'y' => u := 'Y';
      when 'z' => u := 'Z';
      when others => u := c;
    end case;
    return u;
  end function;

  -- convert a character to lower case
  function to_lower(c: character) return character is
    variable l: character;
  begin
    case c is
      when 'A' => l := 'a';
      when 'B' => l := 'b';
      when 'C' => l := 'c';
      when 'D' => l := 'd';
      when 'E' => l := 'e';
      when 'F' => l := 'f';
      when 'G' => l := 'g';
      when 'H' => l := 'h';
      when 'I' => l := 'i';
      when 'J' => l := 'j';
      when 'K' => l := 'k';
      when 'L' => l := 'l';
      when 'M' => l := 'm';
      when 'N' => l := 'n';
      when 'O' => l := 'o';
      when 'P' => l := 'p';
      when 'Q' => l := 'q';
      when 'R' => l := 'r';
      when 'S' => l := 's';
      when 'T' => l := 't';
      when 'U' => l := 'u';
      when 'V' => l := 'v';
      when 'W' => l := 'w';
      when 'X' => l := 'x';
      when 'Y' => l := 'y';
      when 'Z' => l := 'z';
      when others => l := c;
    end case;
    return l;
  end function;

  -- convert a string to upper case
  function to_upper(s: string) return string is
    variable uppercase: string (s'range);
  begin
    for i in s'range loop
        uppercase(i):= to_upper(s(i));
    end loop;
    return uppercase;
  end function;

  -- convert a string to lower case
  function to_lower(s: string) return string is
   variable lowercase: string (s'range);
  begin
    for i in s'range loop
      lowercase(i):= to_lower(s(i));
    end loop;
    return lowercase;
  end function;

-- functions to convert strings into other types

  -- converts a character into a std_logic
  function to_std_logic(c: character) return std_logic is 
  begin
    return to_std_ulogic(c);
  end function;

  -- converts a character into a std_ulogic
  function to_std_ulogic(c: character) return std_ulogic is 
    variable sl: std_ulogic;
  begin
    case c is
      when 'U' => 
         sl := 'U'; 
      when 'X' =>
         sl := 'X';
      when '0' => 
         sl := '0';
      when '1' => 
         sl := '1';
      when 'Z' => 
         sl := 'Z';
      when 'W' => 
         sl := 'W';
      when 'L' => 
         sl := 'L';
      when 'H' => 
         sl := 'H';
      when '-' => 
         sl := '-';
      when others =>
         sl := 'X'; 
    end case;
    return sl;
  end function;
  
  -- converts a string into std_ulogic_vector
  function to_std_logic_vector(s: string) return std_logic_vector is 
  begin
    return std_logic_vector(to_std_ulogic_vector(s));
  end function;

  -- converts a string into std_ulogic_vector
  function to_std_ulogic_vector(s: string) return std_ulogic_vector is 
    variable slv: std_ulogic_vector(s'high-s'low downto 0);
    variable k: integer;
  begin
     k := s'high-s'low;
    for i in s'range loop
       slv(k) := to_std_ulogic(s(i));
       k      := k - 1;
    end loop;
    return slv;
  end function;                                       
                                         
  ----------------
  --  file I/O  --
  ----------------
  
  -- read variable length string from input file
  procedure str_read(file in_file: TEXT; res_string: out string) is
    variable l:         line;
    variable c:         character;
    variable is_string: boolean;
  begin
    readline(in_file, l);
    -- clear the contents of the result string
    for i in res_string'range loop
      res_string(i) := ' ';
    end loop;   
    -- read all characters of the line, up to the length  
    -- of the results string
    for i in res_string'range loop
      read(l, c, is_string);
      res_string(i) := c;
      if not is_string then -- found end of line
        exit;
      end if;   
    end loop; 
  end procedure;
  
  -- print string to a file
  procedure print(file out_file: TEXT; new_string: in  string) is
    variable l: line;
  begin
    write(l, new_string);
    writeline(out_file, l);
  end procedure;
  
  -- print character to a file and start new line
  procedure print(file out_file: TEXT; char: in  character) is
    variable l: line;
  begin
    write(l, char);
    writeline(out_file, l);
  end procedure;
  
  -- appends contents of a string to a file until line feed occurs
  -- (LF is considered to be the end of the string)
  procedure str_write(file out_file: TEXT; new_string: in  string) is
  begin
    for i in new_string'range loop
      print(out_file, new_string(i));
      if new_string(i) = LF then -- end of string
        exit;
      end if;
    end loop;               
  end procedure;

end package body;




