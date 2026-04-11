library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

use work.rendering_pkg.all;

-- Player to map
entity ptm is
	port (
		clk_50 : in std_logic;
	
		x : in natural;
		y : in natural;
		player_orientation : in integer;
		height : in natural;
		z : in natural;
		
		x_map : out array(0 to RENDER_DIST) of natural;
		y_map : out array(0 to RENDER_DIST) of natural;
	);
end entity ptm;

architecture behav of ptm is
begin
process(clk_50)
begin
	
end process;
end architecture behav;