library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package rendering_pkg is
  constant RENDER_DIST : integer := 500;
end package;

package screen_pkg is
  constant SCREEN_WIDTH  : integer := 800;
  constant SCREEN_HEIGHT : integer := 600;
end package;

package calc_pkg is

  function clog2(n : integer) return integer;

end package calc_pkg;

package body calc_pkg is
  function clog2(n : integer) return integer is
    variable result : integer := 0;
    variable val    : integer := n;
  begin
    while val > 1 loop
      val    := (val + 1) / 2;
      result := result + 1;
    end loop;
    return result;
  end function;
end package body;
