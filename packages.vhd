ieee library;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package rendering_pkg is
  constant RENDER_DIST : natural := 500;
end package rendering_pkg;

package pixel_pkg is record
  type pixel_t is record
    r : std_logic_vector(3 downto 0);
    g : std_logic_vector(3 downto 0);
    b : std_logic_vector(3 downto 0);
  end record;
  type frame_t is array (0 to 480_000) of pixel_t;
end package;
