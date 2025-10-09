library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity stepper_28byj_ctrl_bcd is
  generic (
    CLK_HZ      : natural := 50_000_000;
    FREQ_MIN_HZ : natural;
    FREQ_MAX_HZ : natural;
    RAMP_STEP   : natural;
    HOLD_WHEN_STOPPED : boolean := false
  );
  port(
    clk       : in  std_logic;
    resetn    : in  std_logic;
    enable_in : in  std_logic;
    estop     : in  std_logic;
    dir_in    : in  std_logic;

    -- BCD do contador:
    d_tens    : in  unsigned(3 downto 0); -- 0..9
    d_ones    : in  unsigned(3 downto 0); -- 0..9

    -- Saídas para ULN2003
    IN1, IN2, IN3, IN4 : out std_logic
  );
end;

architecture rtl of stepper_28byj_ctrl_bcd is

  type seq_t is array (0 to 7) of std_logic_vector(3 downto 0);
  constant SEQ : seq_t := (
    "1000", "1100", "0100", "0110",
    "0010", "0011", "0001", "1001"
  );

  function clamp(val, lo, hi : integer) return integer is
  begin
    if val < lo then return lo;
    elsif val > hi then return hi;
    else return val;
    end if;
  end;

  -- função para converter BCD para 0..99:
  function bcd_to_u7(tens, ones : unsigned(3 downto 0)) return unsigned is
    variable t8  : unsigned(6 downto 0);
    variable t2  : unsigned(6 downto 0);
    variable sum : unsigned(6 downto 0);
  begin
    t8  := resize(tens, 7) sll 3;
    t2  := resize(tens, 7) sll 1;
    sum := t8 + t2 + resize(ones, 7);
    return sum; -- 0..99 (em 7 bits)
  end;

  signal enabled       : std_logic;
  signal idx           : integer range 0 to 7 := 0;  -- índice da sequência
  signal step_cnt      : integer := 0;
  signal curr_period   : integer := integer(CLK_HZ / FREQ_MIN_HZ);
  signal target_period : integer := integer(CLK_HZ / FREQ_MIN_HZ);
  signal drive         : std_logic_vector(3 downto 0) := (others=>'0');
begin
  enabled <= '0' when (enable_in='0' and estop='1') else '1';

  process(clk, resetn)
    variable v_val   : integer range 0 to 99;
    variable v_f_hz  : integer;
    variable v_ptick : integer;
  begin
    if resetn='0' then
      idx           <= 0;
      step_cnt      <= 0;
      curr_period   <= integer(CLK_HZ / FREQ_MIN_HZ);
      target_period <= integer(CLK_HZ / FREQ_MIN_HZ);
      drive         <= (others=>'0');

    elsif rising_edge(clk) then
      ----------------------------------------------------------------
      -- 1) Lê valor 0..99 a partir de BCD (sem barramento count99)
      ----------------------------------------------------------------
      v_val := to_integer(bcd_to_u7(d_tens, d_ones));  -- 0..99

      ----------------------------------------------------------------
      -- 2) Mapeia 01..99 -> FREQ_MIN..FREQ_MAX; 00 -> parado
      ----------------------------------------------------------------
      if (enabled='1') or (v_val = 0) then
        v_f_hz := 0;
      else
        -- interpolação linear (inteira): 1..99 -> [FREQ_MIN, FREQ_MAX]
        v_f_hz := FREQ_MIN_HZ + (v_val - 1) * (FREQ_MAX_HZ - FREQ_MIN_HZ) / 98;
      end if;

      if v_f_hz <= 0 then
        target_period <= integer'high;     -- parado
      else
        v_ptick := integer(CLK_HZ / v_f_hz);
        target_period <= clamp(v_ptick, 2, integer'high);
      end if;

      ----------------------------------------------------------------
      -- 3) Rampa: aproxima período corrente do alvo (evita trancos)
      ----------------------------------------------------------------
      if curr_period < target_period then
        curr_period <= clamp(curr_period + integer(RAMP_STEP), 2, target_period);
      elsif curr_period > target_period then
        curr_period <= clamp(curr_period - integer(RAMP_STEP), 2, target_period);
      end if;

      ----------------------------------------------------------------
      -- 4) Geração de meio-passo: avança idx quando step_cnt atinge período
      ----------------------------------------------------------------
      if (enabled='0') and (curr_period < integer'high) then
        if step_cnt >= curr_period then
          step_cnt <= 0;
          if dir_in='1' then
            if idx=7 then idx <= 0; else idx <= idx+1; end if;
          else
            if idx=0 then idx <= 7; else idx <= idx-1; end if;
          end if;
        else
          step_cnt <= step_cnt + 1;
        end if;
      else
        step_cnt <= 0;
      end if;

      ----------------------------------------------------------------
      -- 5) Saída para o ULN2003
      ----------------------------------------------------------------
      if enabled='0' then
        drive <= SEQ(idx);
      else
        if HOLD_WHEN_STOPPED then
          drive <= "1100";  -- segura torque (duas fases)
        else
          drive <= "0000";  -- bobinas desligadas (frio/seguro)
        end if;
      end if;
    end if;
  end process;

  IN1 <= drive(3);
  IN2 <= drive(2);
  IN3 <= drive(1);
  IN4 <= drive(0);
end;
