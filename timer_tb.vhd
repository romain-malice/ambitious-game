library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_ARITH.all;
use ieee.std_logic_UNSIGNED.all;

entity timer_tb is
end entity timer_tb;

architecture test_bench of timer_tb is
  signal clk_50, reset, enable : std_logic;
  signal limit                 : integer;
  signal interrupt             : std_logic;
begin
  dut : entity work.timer(behav)
    port map (clk_50, reset, enable, limit, interrupt);
  stimulus : process
  begin
    -- Initial state
    reset  <= '0';
    enable <= '0';
    limit  <= 5;

    -- Wait for a couple cycles before starting
    wait for 40 ns;

    -- Enable the timer for 100 us
    enable <= '1';
    wait for 1 us;

    -- Disable the timer
    enable <= '0';
    wait for 20 ns;

    -- Reset pulse
    reset <= '1';
    wait for 20 ns;
    reset <= '0';

    wait for 100 ns;
    assert false
      report "End of simulation"
      severity failure;
  end process stimulus;

  clk_process : process
  begin
    clk_50 <= '0';
    wait for 10 ns;
    clk_50 <= '1';
    wait for 10 ns;
  end process clk_process;
end architecture test_bench;
