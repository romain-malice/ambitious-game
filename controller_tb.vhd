library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_tb is
end entity controller_tb;

architecture test_bench of controller_tb is
  signal clk_50, enable              : std_logic;
  signal data, latch, controller_clk : std_logic;
  signal buttons                     : std_logic_vector(0 to 11) := (others => '0');
begin
  dut : entity work.controller(behav)
    port map (clk_50, enable, data, buttons, latch, controller_clk);

  stimulus : process
  begin
    -- Initial state
    enable <= '0';

    data <= '0';

    -- Wait before starting
    wait for 40 ns;

    -- Start the protocol
    enable <= '1';

    -- Act as the controller responding to inputs
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press B
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Y
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Sel
    wait until rising_edge(controller_clk);
    data <= '1';                        -- Press Strt
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Up
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Down
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Left
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Right
    wait until rising_edge(controller_clk);
    data <= '1';                        -- Press A
    wait until rising_edge(controller_clk);
    data <= '1';                        -- Press X
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press L
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press R

    -- Disable reading
    enable <= '0';

    wait for 100 ns;

    -- New measure

    enable <= '1';

    -- Act as the controller responding to inputs
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press B
    wait until rising_edge(controller_clk);
    data <= '1';                        -- Press Y
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Sel
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Strt
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Up
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Down
    wait until rising_edge(controller_clk);
    data <= '1';                        -- Press Left
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press Right
    wait until rising_edge(controller_clk);
    data <= '1';                        -- Press A
    wait until rising_edge(controller_clk);
    data <= '1';                        -- Press X
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press L
    wait until rising_edge(controller_clk);
    data <= '0';                        -- Press R

    -- Disable reading
    enable <= '0';

    wait for 500 us;

    assert false report "End of simulation" severity failure;
  end process stimulus;

  clk_process : process
  begin
    clk_50 <= '0';
    wait for 10 ns;
    clk_50 <= '1';
    wait for 10 ns;
  end process clk_process;
end architecture test_bench;
