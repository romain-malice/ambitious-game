library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_ARITH.all;
use ieee.std_logic_UNSIGNED.all;

entity display is
  generic (
    COORD_WIDTH : integer := 16; -- signed coordinate width (bits)
    H_ACTIVE : integer := 800; -- horizontal resolution (pixels)
    V_ACTIVE : integer := 600; -- vertical resolution (new_lines)
    H_FP : integer := 56; -- horizontal front porch
    HS_LEN : integer := 120; -- horizontal sync
    H_BP : integer := 64; -- horizontal back porch
    H_LENGTH : integer := 1040; -- Total length of new_line

    V_FP : integer := 37; -- vertical front porch
    VS_LEN : integer := 6; -- vertical sync
    V_BP : integer := 23; -- vertical back porch
    V_LENGTH : integer := 666 -- Total number of new_lines in a new_frame
  );
  port (
    clk_pix : in std_logic; -- pixel clock

    hsync : out std_logic; -- horizontal sync
    vsync : out std_logic; -- vertical sync
    de : out std_logic; -- data enable (low in blanking interval)
    new_frame : out std_logic; -- high at start of new_frame
    new_line : out std_logic; -- high at start of new_line
    sx : out std_logic_vector(10 downto 0) := (others => '0'); -- horizontal screen position
    sy : out std_logic_vector(10 downto 0) := (others => '0') -- vertical screen position
  );
end entity display;

architecture behav of display is
  signal x, y : std_logic_vector(10 downto 0) := (others => '0');

  constant LATENCY : integer := 2;

begin
  -- Sync activation
  process (clk_pix)
  begin
    if rising_edge(clk_pix) then
      if x >= H_LENGTH - HS_LEN and x <= H_LENGTH - 1 then
        hsync <= '0';
      else
        hsync <= '1';
      end if;
      if y >= V_LENGTH - VS_LEN and y <= V_LENGTH - 1 then
        vsync <= '0';
      else
        vsync <= '1';
      end if;
    end if;
  end process;

  -- Control signals
  process (clk_pix)
  begin
    if rising_edge(clk_pix) then
      if (x >= 63 and x <= 863) and (y >= 24 and y <= 623) then -- Définition de quelle zone n'est pas noire
        de <= '1';
      else
        de <= '0';
      end if;
      if (y = 0) and (x = 0) then
        new_frame <= '1';
      else
        new_frame <= '0';
      end if;
      if (x = 0) then
        new_line <= '1';
      else
        new_line <= '0';
      end if;
    end if;
  end process;

  -- purpose: Update horizontal and vertical positions
  -- type   : sequential
  -- inputs : clk_pix, rst_pix
  -- outputs: x, y
  process (clk_pix) is
  begin -- process
    if rising_edge(clk_pix) then -- rising clock edge
      if x = H_LENGTH - 1 then -- End of line
        x <= b"000_0000_0000";
        if y = V_LENGTH - 1 then
          y <= b"000_0000_0000";
        else
          y <= y + 1;
        end if;
      else
        x <= x + 1;
      end if;
    end if;
  end process;

  -- purpose: Map internal register to output position signals (positions sent at the same time as the control signals)
  -- type   : sequential
  -- inputs : clk_pix, rst_pix, x, y
  -- outputs: sx, sy
  process (clk_pix) is
  begin -- process
    if rising_edge(clk_pix) then -- rising clock edge
      sx <= x;
      sy <= y;
    end if;
  end process;
end architecture;