library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trig_lut is
  generic (
    LUT_DEPTH : integer := 1024; -- Number of values in the LUT
    LUT_WIDTH : integer := 11; -- Size of the elements of the LUT
    FRAC_BITS : integer := 10;
    SIN : string := "sin_lut.mif"); -- Sine file (cos derived by +90deg offset)
  port (
    clk : in std_logic;
    angle : in unsigned(9 downto 0); -- Input angle: 0..1023 maps to 0..360deg

    sin_val : out signed(FRAC_BITS downto 0); -- Q1.10, range -1023..+1023
    cos_val : out signed(FRAC_BITS downto 0) -- Q1.10, range -1023..+1023
  );
end entity trig_lut;

architecture struct of trig_lut is

  -- cos(angle) = sin(angle + 90deg) = sin(angle + LUT_DEPTH/4)
  constant COS_OFFSET : unsigned(9 downto 0) :=
                                               to_unsigned(LUT_DEPTH / 4, 10); -- 256 for a 1024-entry LUT

  signal angle_std : std_logic_vector(9 downto 0);
  signal cos_angle_std : std_logic_vector(9 downto 0);
  signal sin_raw : std_logic_vector(10 downto 0);
  signal cos_raw : std_logic_vector(10 downto 0);

begin

  angle_std <= std_logic_vector(angle);
  cos_angle_std <= std_logic_vector(angle + COS_OFFSET); -- wraps automatically

  sin_val <= signed(sin_raw);
  cos_val <= signed(cos_raw);

  sin_lut_inst : entity work.sin_lut
    port map(
      address => angle_std,
      clock => clk,
      q => sin_raw);

  cos_lut_inst : entity work.sin_lut -- same ROM, offset address
    port map(
      address => cos_angle_std,
      clock => clk,
      q => cos_raw);

end architecture struct;