library ieee;
use ieee.math_real.all;

package math_utils_pkg is
  function clog2(n : positive) return positive;
end package math_utils_pkg;

package body math_utils_pkg is
  function clog2(n : positive) return positive is
  begin
    if n <= 1 then
      return 1;
    end if;
    return integer(ceil(log2(real(n))));
  end function clog2;
end package body math_utils_pkg;