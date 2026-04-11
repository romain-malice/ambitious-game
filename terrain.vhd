library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity game_map is
	port (
		clk_50 : in std_logic;
		
		height : out std_logic_vector(3 downto 0) := (others => 0);
		terrain : out std_logic_vector(2 downto 0) := (others => 0);
		shadow : out std_logic := 0;
	);
end entity game_map;

architecture behav of game_map is
	constant map_width : integer := 800;
	constant map_height : integer := 600;
begin
	process(clk_50)
	begin
	end process 
end architecture behav;