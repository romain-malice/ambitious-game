library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trig_lut_sine is
  generic (
    LUT_DEPTH : integer := 1024;					-- Number of values in the LUT
	 LUT_WIDTH : integer := 11;					-- Size of the elements of the LUT
	 FRAC_BITS : integer := 10;
    SIN  : string  := "sin_lut.mif");  		-- Sinus file

  port (
    clk   : in std_logic;
    angle   : in unsigned (9 downto 0);  		-- Input angle (positive integer on 10 bits: 0-->1023)
	 
	 sin_val : out signed(FRAC_BITS downto 0)-- Output sin value (signed integer on 11 bits: -1024-->1023)
    );
end entity trig_lut_sine;

architecture struct of trig_lut_sine is

signal angle_std : std_logic_vector (9 downto 0);
signal sin_raw : std_logic_vector (10 downto 0);

begin	

angle_std <= std_logic_vector(angle);
sin_val <= signed(sin_raw);



sin_lut_inst: entity work.sin_lut
		port map (
			address => angle_std,
			clock => clk,
			q => sin_raw);
end architecture struct;


