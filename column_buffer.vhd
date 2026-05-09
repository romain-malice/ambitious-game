library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_UNSIGNED.all;
use ieee.std_logic_ARITH.all;

-- Computes a column corresponding to a vertical slice of landscape
entity column_buffer is
	generic (
	-- Column_buffer parameters
	FB_WIDTH := 200;
	--CB_WIDTH_W := 8;
	FB_HEIGHT := 150;
	
	MAX_DIST = 60; -- Maximal distance at which you can see
	MIN_DIST = 10; -- Minimum distance at which you can see
	HORIZON := 50; -- y-coordinate of the horizon line
	
	
	