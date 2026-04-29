library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
  port (
    clk_50 : in std_logic; -- External clock
    enable : in std_logic;
    data : in std_logic; -- Serial input from controller

    buttons : out std_logic_vector(0 to 11) := (others => '0'); -- Parallel output to modify game variables
    latch : out std_logic := '0';
    controller_clk : out std_logic := '0' -- Output to controller
  );
end entity controller;

architecture behav of controller is
  type state_t is (IDLE, LATCH_SIG, CLK_UP, CLK_DOWN);
  signal state : state_t := IDLE;

  signal timer : integer := 0;
  signal clk_period : integer range 0 to 16 := 0;

  signal buttons_reg : std_logic_vector(0 to 11) := (others => '0');
begin
  process (clk_50)
  begin
    if rising_edge(clk_50) then
      case state is
        when IDLE =>
          if enable = '1' then
            timer <= 0;
            state <= LATCH_SIG;
          end if;
        when LATCH_SIG =>
          if timer = 599 then
            latch <= '0';
            timer <= 0;
            state <= CLK_UP;
          else
            timer <= timer + 1;
            latch <= '1';
          end if;
        when CLK_UP =>
          if timer = 299 then
            if clk_period <= 11 then
              buttons_reg(clk_period) <= data;
            end if;

            timer <= 0;
            state <= CLK_DOWN;
          else
            timer <= timer + 1;
            controller_clk <= '1';
          end if;
        when CLK_DOWN =>
          if timer = 299 then
            timer <= 0;
            clk_period <= clk_period + 1;

            if clk_period = 15 then
              clk_period <= 0;
              buttons <= buttons_reg;
              state <= IDLE;
            else
              state <= CLK_UP;
            end if;
          else
            controller_clk <= '0';
            timer <= timer + 1;
          end if;
      end case;
    end if;
  end process;
end architecture behav;