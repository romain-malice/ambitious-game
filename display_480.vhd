library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_480p is
  generic (
    COORD_WIDTH : integer := 16;        -- signed coordinate width (bits)
    H_RES       : integer := 640;       -- horizontal resolution (pixels)
    V_RES       : integer := 480;       -- vertical resolution (lines)
    H_FP        : integer := 16;        -- horizontal front porch
    H_SYNC      : integer := 96;        -- horizontal sync
    H_BP        : integer := 48;        -- horizontal back porch
    V_FP        : integer := 10;        -- vertical front porch
    V_SYNC      : integer := 2;         -- vertical sync
    V_BP        : integer := 33;        -- vertical back porch
    H_POL       : integer := 0;    -- horizontal sync polarity (0:neg, 1:pos)
    V_POL       : integer := 0     -- vertical sync polarity (0:neg, 1:pos)
    );
  port (
    clk_pix : in std_logic;             -- pixel clock
    rst_pix : in std_logic;             -- reset in pixel clock domain

    hsync : out std_logic;              -- horizontal sync
    vsync : out std_logic;              -- vertical sync
    de    : out std_logic;  -- data enable (low in blanking interval)
    frame : out std_logic;              -- high at start of frame
    line  : out std_logic;              -- high at start of line
    sx    : out signed(COORD_WIDTH-1 downto 0);  -- horizontal screen position
    sy    : out signed(COORD_WIDTH-1 downto 0)   -- vertical screen position
    );
end entity display_480p;

architecture behav of display_480 is
  -- Timings
  constant H_START  : integer := 0 - H_FP - H_SYNC - H_BP;
  constant HS_START : integer := H_START + H_FP;
  constant HS_END   : integer := HS_START + H_SYNC;
  constant HA_START : integer := 0;
  constant HA_END   : integer := H_RES - 1;

  constant V_START  : integer := 0 - V_FP - V_SYNC - V_BP;
  constant VS_START : integer := V_START + V_FP;
  constant VS_END   : integer := VS_START + V_SYNC;
  constant VA_START : integer := 0;
  constant VA_END   : integer := V_RES - 1;

  signal x, y : std_logic_vector(COORD_WIDTH downto 0) := (others => '0');
begin
  -- Sync activation
  process(clk_pix)
  begin
    if rising_edge(clk_pix) then
      if rst_pix = '1' then
        hsync <= '0' when H_POL = 1 else '1';
        vsync <= '0' when V_POL = 1 else '1';
      else
        hsync <= '1' when (x >= HS_STA and x < HS_END and H_POL = 1)
                 or (not(x >= HS_STA and x < HS_END) and H_POL = 0)
                 else '0';
        vsync <= '1' when (y >= VS_STA and y < VS_END and V_POL = 1)
                 or (not(y >= VS_STA and y < VS_END) and V_POL = 0)
                 else '0';
      end if;
    end if;
  end process;

  -- Control signals
  process(clk_pix)
  begin
    if rst_pix = '0' then
      de    <= '0';
      frame <= '0';
      line  <= '0';
    elsif rising_edge(clk_pix) then
      de    <= (x >= HA_START) and (y >= VA_START);  -- In active area
      frame <= (y = VA_START) and (x = HA_START);    -- Start of frame
      line  <= (x = HA_START);                       -- Start of line
    end if;
  end process;

  -- purpose: Update horizontal and vertical positions
  -- type   : sequential
  -- inputs : clk_pix, rst_pix
  -- outputs: x, y
  process (clk_pix, rst_pix) is
  begin  -- process
    if rst_pix = '0' then               -- asynchronous reset (active low)
      x <= H_START;
      y <= V_START;
    elsif clk_pix'event and clk_pix = '1' then  -- rising clock edge
      if x = HA_END then                -- End of line
        x <= H_START;
        y <= V_START when (y = VA_END) else y + 1;
      else
        x <= x + 1;
      end if;
    end if;
  end process;

  -- purpose: Map internal register to output position signals (positions sent at the same time as the control signals)
  -- type   : sequential
  -- inputs : clk_pix, rst_pix, x, y
  -- outputs: sx, sy
  process (clk_pix, rst_pix) is
  begin  -- process
    if rst_pix = '0' then               -- asynchronous reset (active low)
      sx <= H_START;
      sy <= V_START;
    elsif clk_pix'event and clk_pix = '1' then  -- rising clock edge
      sx <= x;
      sy <= y;
    end if;
  end process;
end architecture;
