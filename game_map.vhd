library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity game_map is
  port (
    clk_50 : in std_logic;
    enable : in std_logic;
    x, y   : in integer;

    height  : out std_logic_vector(1 downto 0) := (others => '0');
    terrain : out std_logic_vector(1 downto 0) := (others => '0');
    );
end entity game_map;

architecture behav of game_map is
  constant map_width  : integer := 800;
  constant map_height : integer := 600;
begin
  process(clk_50) is
  begin
    if rising_edge(clk_50) and (enable = '1') then
      height  <= "00";
      terrain <= "01";
    end if;
  end process;
end architecture behav;
