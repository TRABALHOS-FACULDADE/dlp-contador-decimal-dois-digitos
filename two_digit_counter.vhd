library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ContadorDecimalProgressivoRegressivo is
  port(
    CLOCK_50 : in  std_logic; -- clock principal da placa (setado para 50MHz)
    KEY      : in  std_logic_vector(3 downto 0); -- KEY0=resetn, KEY1=up
    SW       : in  std_logic_vector(9 downto 0); -- SW[3:0] = velocidade
	 
    HEX0     : out std_logic_vector(6 downto 0); -- segmentos do display das unidades
    HEX1     : out std_logic_vector(6 downto 0); -- segmentos do display das dezenas
	 
	 -- HEXx(6) HEXx(5) HEXx(4) HEXx(3) HEXx(2) HEXx(1) HEXx(0)
    --   g       f       e       d       c       b       a

	 
    LEDR     : out std_logic_vector(9 downto 0)
  );
end;

architecture rtl of ContadorDecimalProgressivoRegressivo is
  signal resetn    : std_logic;
  signal up        : std_logic;
  signal tick      : std_logic;
  signal d1,d0     : unsigned(3 downto 0);
  signal pulse_ro  : std_logic;
  signal seg0_w, seg1_w : std_logic_vector(6 downto 0);
begin
  -- botões do FPGA (ativos em 0)
  resetn <= KEY(0);
  up     <= KEY(1);

  -- divisor de clock
  --u_div : entity work.clk_div_sel
    --generic map(BASE_DIV => 22, CNTW => 40)
    --port map(
      --clk    => CLOCK_50,
      --resetn => resetn,
      --sel    => unsigned(SW(3 downto 0)),
      --tick   => tick
    --);

  -- APENAS PARA TESTES NO WAVEFORM
  u_div: entity work.clk_div_sel
	 generic map ( BASE_DIV => 3 )
	 port map (
	   clk => CLOCK_50,
		resetn => resetn,
		sel => to_unsigned(0, 4),
		tick => tick
	 );


  -- contador 00..99
  u_cnt: entity work.updown_counter_00_99
    port map(
		clk => CLOCK_50,
      clk_en => tick,
      resetn => resetn,
      up     => up,
      d_tens => d1,
      d_ones => d0
    );

  -- Instanciando duas vezes o decodificador do SSD (bcd7seg): uma instância para o digito das unidade
  -- e outra instância para o digito das dezenas
	u_hex0: entity work.bcd7seg port map(bcd => d0, segn => seg0_w);
	u_hex1: entity work.bcd7seg port map(bcd => d1, segn => seg1_w);

	process(CLOCK_50, resetn)
	begin
	  if resetn='0' then
		 HEX0 <= (others => '1');
		 HEX1 <= (others => '1');
	  elsif rising_edge(CLOCK_50) then
		 HEX0 <= seg0_w;
		 HEX1 <= seg1_w;
	  end if;
	end process;

   LEDR(3 downto 0) <= std_logic_vector(d0); -- unidades
   LEDR(7 downto 4) <= std_logic_vector(d1); -- dezenas

end;
