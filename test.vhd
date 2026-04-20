library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test is
  port (
    clk_50 : in std_logic;
    x      : in integer range 0 to 799;
    y      : in integer range 0 to 599;

    px : out std_logic
    );
end test;

architecture behav of test is
begin
  process(clk_50) is
  begin
    if rising_edge(clk_50) then
      if (x + y < 300) then
        px <= '1';
      else
        px <= '0';
      end if;
    end if;
  end process;
end architecture behav;
