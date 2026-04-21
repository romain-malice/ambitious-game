library ieee ;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package rendering_pkg is
  constant RENDER_DIST : integer := 500;
end package;

package screen_pkg is
  constant SCREEN_WIDTH : integer := 800;
  constant SCREEN_HEIGHT : integer := 600;
end package;
