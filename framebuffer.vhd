library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_ARITH.all;
use ieee.std_logic_UNSIGNED.all;

entity framebuffer is
  port (
    clk_50 : in std_logic;
    rst : in std_logic;

    vga_hsync : out std_logic;
    vga_vsync : out std_logic;
    vga_r : out std_logic_vector(3 downto 0);
    vga_g : out std_logic_vector(3 downto 0);
    vga_b : out std_logic_vector(3 downto 0)
  );
end entity;

architecture behav of framebuffer is
  -- Color params
  constant COLR_CH_W : integer := 4; -- Color channel width (send to vga)
  constant COLR_W : integer := 3 * COLR_CH_W; -- Total color width
  constant COLR_IDX_W : integer := 4; -- Width of color index (16 colors)
  constant BG_COLR : std_logic_vector(COLR_W - 1 downto 0) := x"8CE"; -- Background color (sky blue)

  -- Framebuffer params
  constant FB_WIDTH : integer := 200;
  constant FB_HEIGHT : integer := 150;
  constant FB_PIXELS : integer := FB_WIDTH * FB_HEIGHT; -- Number of pixels in framebuffer
  constant FB_ADDR_W : integer := 15;
  constant FB_DATA_W : integer := COLR_IDX_W; -- Logic color idx

  -- Display signals
  constant COORD_W : integer := 16;
  signal sx, sy : std_logic_vector(10 downto 0);
  signal h_sync, v_sync : std_logic;
  signal de, new_frame : std_logic;

  -- Pixel and color read addresses
  signal fb_addr_read : unsigned(FB_ADDR_W - 1 downto 0) := (others => '0');
  signal fb_colr_read : std_logic_vector(FB_DATA_W - 1 downto 0); -- Color index from ram (index)
  signal fb_pix_colr : std_logic_vector(COLR_W - 1 downto 0); -- Pixel color from clut (12bit color)

  -- Reading framebuffer
  constant LAT : integer := 3; -- Latency (3 readings = fb + bram + clut)
  signal read_fb : std_logic;

  -- Paint screen
  signal paint_r, paint_g, paint_b : std_logic_vector(COLR_CH_W - 1 downto 0);

  -- VGA display signals
  signal display_r : std_logic_vector(COLR_CH_W - 1 downto 0);
  signal display_g : std_logic_vector(COLR_CH_W - 1 downto 0);
  signal display_b : std_logic_vector(COLR_CH_W - 1 downto 0);

begin
  display_inst : entity work.display
    port map(
      clk_pix => clk_50,
      hsync => h_sync,
      vsync => v_sync,
      de => de,
      new_frame => new_frame,
      new_line => open,
      sx => sx,
      sy => sy);

  img_rom_inst : entity work.img_rom
    port map(
      address => std_logic_vector(fb_addr_read),
      clock => clk_50,
      q => fb_colr_read);

  -- purpose: Read the right pixel from the buffer
  -- type   : sequential
  -- inputs : clk_50, rst_pix, sx, sy, frame, fb_addr_read
  -- outputs: fb_addr_read, read_fb
  fb_reading : process (clk_50) is
  begin -- process fb_reading
    if rising_edge(clk_50) then -- rising clock edge
      if (sy >= 24) and (sy < 24 + FB_HEIGHT) and (sx >= 63 - LAT) and (sx < 63 + FB_WIDTH - LAT) then
        read_fb <= '1';
      else
        read_fb <= '0';
      end if;
      if new_frame = '1' then
        fb_addr_read <= (others => '0');
      elsif read_fb = '1' then
        fb_addr_read <= fb_addr_read + 1;
      end if;
    end if;
  end process fb_reading;

  -- Color lookup table
  clut_inst : entity work.pal_rom
    port map(
      clock => clk_50,
      address => std_logic_vector(fb_colr_read),
      q => fb_pix_colr);

  -- purpose: Paint the screen
  -- type   : combinational
  -- inputs : sx, sy
  -- outputs: paint_area
  paint_screen : process (sy, sx, fb_pix_colr) is
    variable paint_area : std_logic;
  begin -- process paint_screen
    if (sy >= 24) and (sy < 24 + FB_HEIGHT) and (sx >= 63) and (sx < 63 + FB_WIDTH) then
      paint_area := '1';
    else
      paint_area := '0';
    end if;

    if paint_area = '1' then
      paint_r <= fb_pix_colr(COLR_W - 1 downto COLR_W - COLR_CH_W);
      paint_g <= fb_pix_colr(COLR_W - COLR_CH_W - 1 downto COLR_CH_W);
      paint_b <= fb_pix_colr(COLR_CH_W - 1 downto 0);
    else
      paint_r <= BG_COLR(COLR_W - 1 downto COLR_W - COLR_CH_W);
      paint_g <= BG_COLR(COLR_W - COLR_CH_W - 1 downto COLR_CH_W);
      paint_b <= BG_COLR(COLR_CH_W - 1 downto 0);
    end if;
  end process paint_screen;

  -- Combinatorial update of the rgb signals sent to the vga
  process (de, paint_r, paint_g, paint_b) is
  begin -- process
    if de = '1' then
      display_r <= paint_r;
      display_g <= paint_g;
      display_b <= paint_b;
    else
      display_r <= (others => '0');
      display_g <= (others => '0');
      display_b <= (others => '0');
    end if;
  end process;

  -- VGA output signals
  process (clk_50) is
  begin -- process
    if clk_50'event and clk_50 = '1' then -- rising clock edge
      vga_hsync <= h_sync;
      vga_vsync <= v_sync;
      vga_r <= display_r;
      vga_g <= display_g;
      vga_b <= display_b;
    end if;
  end process;
end architecture;