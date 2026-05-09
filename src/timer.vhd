library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_ARITH.all;
use ieee.std_logic_UNSIGNED.all;

-- Synchronous timer
entity timer is
  port (
    clk_50 : in std_logic;              -- External clock assumed @ 50MHz
    reset  : in std_logic;              -- Sets the timer back to 0
    enable : in std_logic;  -- If 1, the timer starts again indefinitely
    limit  : in integer;                -- Number of clock ticks

    interrupt : out std_logic := '0'    -- Signal sent at the end of the timer
    );
end entity timer;

architecture behav of timer is
  signal counter : integer := 0;
begin
  process(clk_50, reset) is
  begin
    if reset = '0' then                 -- When triggered on reset
      counter   <= 0;
      interrupt <= '0';
    elsif rising_edge(clk_50) then      -- When triggered on clk edge
      if enable = '1' then
        if counter < limit then
          counter   <= counter + 1;
          interrupt <= '0';
        else
          interrupt <= '1';
          counter   <= 0;
        end if;
      end if;
    end if;
  end process;
end architecture behav;
