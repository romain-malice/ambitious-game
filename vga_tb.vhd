library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_tb is
end entity vga_tb;

architecture test_bench of vga_tb is
  signal clk_50 : std_logic := '0';
  signal current_pixel : std_logic := '0';
  signal h_frame :
begin
  dut : entity work.vga(behav)
    port map (clk_50, current_pixel, h_frame, v_frame, r, g, b, s);

  stimulus : process
  begin

  end process stimulus;
end architecture test_bench;
