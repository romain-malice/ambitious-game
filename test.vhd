library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.screen_pkg.all;

entity test is
  port (
    clk_50 : in std_logic;
    x      : in integer range 0 to SCREEN_WIDTH-1;
    y      : in integer range 0 to SCREEN_HEIGHT-1;

    px : out std_logic := '1'
    );
end test;

architecture behav of test is
  signal color_cnt : integer range 0 to 49 := 0;
  signal px_reg : std_logic := '1';
begin
	px <= px_reg;

  process(clk_50) is
  begin
    if rising_edge(clk_50) then
      if color_cnt = 49 then
        color_cnt <= 0;
        px_reg <= not px_reg;
      else
        color_cnt <= color_cnt + 1;
      end if;
    end if;
  end process;
end architecture behav;
