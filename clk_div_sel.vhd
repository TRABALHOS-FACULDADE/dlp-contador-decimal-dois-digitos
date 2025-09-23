library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_div_sel is
  generic(
    BASE_DIV : natural := 22;   -- base de divisão
    CNTW     : natural := 40    -- largura do contador (aceita sel 0..15)
  );
  port(
    clk    : in  std_logic;
    resetn : in  std_logic;           -- ativo em 0
    sel    : in  unsigned(3 downto 0);-- 0..15
    tick   : out std_logic            -- pulso de 1 ciclo
  );
end;

architecture rtl of clk_div_sel is
  function imin(a, b : integer) return integer is
  begin
    if a < b then return a; else return b; end if;
  end function;

  signal cnt      : unsigned(CNTW-1 downto 0) := (others => '0');
  signal idx      : integer range 1 to CNTW-1 := BASE_DIV;
  signal bit_now  : std_logic := '0';
  signal bit_prev : std_logic := '0';
begin
  idx <= imin(BASE_DIV + to_integer(sel), CNTW-1);

  process(clk, resetn)
  begin
    if resetn = '0' then
      cnt      <= (others => '0');
      bit_now  <= '0';
      bit_prev <= '0';
      tick     <= '0';
    elsif rising_edge(clk) then
      cnt      <= cnt + 1;
      bit_prev <= bit_now;
      bit_now  <= cnt(idx);
      tick     <= bit_now and not bit_prev; -- subida de borda => 1 ciclo
    end if;
  end process;
end;
