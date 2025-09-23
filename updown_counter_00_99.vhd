library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity updown_counter_00_99 is
  port(
    clk    : in  std_logic;             -- CLOCK_50
    clk_en : in  std_logic;             -- pulso do divisor: 1 passo
    resetn : in  std_logic;             -- ativo em 0
    up     : in  std_logic;             -- 1 = sobe, 0 = desce
    d_tens : out unsigned(3 downto 0);  -- dezenas em BCD
    d_ones : out unsigned(3 downto 0)   -- unidades em BCD
  );
end;

architecture rtl of updown_counter_00_99 is
begin
  process(clk, resetn)
    variable ones : integer range -1 to 10 := 0;
    variable tens : integer range -1 to 10 := 0;
  begin
    -- RESET
    if resetn = '0' then
      if up = '1' then
        ones := 0;  tens := 0;
      else
        ones := 9;  tens := 9;
      end if;

    elsif rising_edge(clk) then
      if clk_en = '1' then
        if up = '1' then
          ones := ones + 1;
          if ones = 10 then
            ones := 0;
            tens := tens + 1;
            if tens = 10 then
              tens := 0;
            end if;
          end if;
        else
          ones := ones - 1;
          if ones = -1 then
            ones := 9;
            tens := tens - 1;
            if tens = -1 then
              tens := 9;
            end if;
          end if;
        end if;
      end if;
    end if;

    -- saídas BCD
    d_ones <= to_unsigned(ones, 4);
    d_tens <= to_unsigned(tens, 4);
  end process;
end;
