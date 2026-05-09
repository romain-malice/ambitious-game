library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;

entity colourmap is
	generic (
		MAP_WIDTH : integer := 200 * 4;
		MAP_HEIGHT : integer := 150 * 4;
		MAP_DIM : integer := 800);

	port (
		x : in integer range 0 to MAP_WIDTH - 1;
		y : in integer range 0 to MAP_HEIGHT - 1;
		flag_x : in unsigned(clog2(MAP_DIM) downto 0);
		flag_y : in unsigned(clog2(MAP_DIM) downto 0);
		flag_flag : in std_logic;
		color : out std_logic_vector(3 downto 0);
		altitude : out integer range 0 to 255
	);
end entity;

architecture struct of colourmap is

begin
	process (x, y)
	begin

		-- Draw map objects

		if x >= 4 * 50 and x <= 4 * 60 and y >= 4 * 60 and y <= 4 * 63 then -- ship
			color <= x"3";
			altitude <= 30;

		elsif (y >= 4 * 10) and (x >= 4 * 120 + (y - 4 * 10)) and (x <= 4 * 140 - (y - 4 * 10)) then -- iceberg
			color <= x"C";
			altitude <= 0;

		elsif x >= 4 * 65 and x <= 4 * 67 and y >= 4 * 50 and y < 4 * 100 then -- pier
			color <= x"0";

		elsif y > 4 * 99 then -- beach
			color <= x"4";
			altitude <= 0;
		elsif flag_flag = '1' and x = flag_x and y = flag_y then -- flag
			color <= x"3";
			altitude <= 10;
		else
			color <= x"8";
			altitude <= 0;

		end if;
	end process;

end architecture;