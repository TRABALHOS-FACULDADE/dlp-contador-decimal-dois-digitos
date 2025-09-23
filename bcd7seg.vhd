library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd7seg is
  port(
    bcd  : in  unsigned(3 downto 0); -- 0..9
    segn : out std_logic_vector(6 downto 0) -- segmentos do SSD (a..g, ativo em 0)
  );
end;

architecture rtl of bcd7seg is
begin
  process(bcd) is
  begin
    case bcd is
      when "0000" => segn <= "1000000"; -- 0
      when "0001" => segn <= "1111001"; -- 1
      when "0010" => segn <= "0100100"; -- 2
      when "0011" => segn <= "0110000"; -- 3
      when "0100" => segn <= "0011001"; -- 4
      when "0101" => segn <= "0010010"; -- 5
      when "0110" => segn <= "0000010"; -- 6
      when "0111" => segn <= "1111000"; -- 7
      when "1000" => segn <= "0000000"; -- 8
      when "1001" => segn <= "0010000"; -- 9
      when others => segn <= "1111111"; -- apagado
    end case;
  end process;
end;
