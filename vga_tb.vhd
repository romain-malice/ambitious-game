library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_ARITH.all;
use ieee.std_logic_UNSIGNED.all;

entity vga_tb is
end entity;

use work.rendering_pkg.all;

architecture test_bench of vga_tb is

  -- Pattern options: swap body of make_frame to change content
  function make_frame return frame_t is
    variable f   : frame_t;
    variable idx : unsigned(19 downto 0);  -- 20 bits fits 480000
    variable r, g, b : unsigned(3 downto 0);
  begin
    for i in 0 to FRAME_SIZE-1 loop
      idx := to_unsigned(i, 20);
      -- Example: horizontal grey ramp cycling every 16 pixels
      r := idx(3 downto 0);
      g := idx(7 downto 4);
      b := idx(11 downto 8);
      f(i) := std_logic_vector(r & g & b);
    end loop;
    return f;
  end function;

  constant FRAME : frame_t := make_frame;

  signal clk_50 : std_logic;
  signal frame : frame_t := make_frame;

  signal r, g, b : std_logic_vector(3 downto 0);
  signal sync : std_logic_vector(1 downto 0);

begin  -- architecture test_bench

  dut : entity work.vga(Behavioral)
    port map(clk_50, frame, r, g, b, sync);

  clk_process : process
  begin
    clk_50 <= '0';
    wait for 10 ns;
    clk_50 <= '1';
    wait for 10 ns;
  end process clk_process;

end architecture test_bench;
