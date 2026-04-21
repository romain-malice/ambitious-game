library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.calc_pkg.all;

entity framebuffer is
  port (
    clk_50 : in std_logic;
    rst    : in std_logic;

    vga_hsync : out std_logic;
    vga_vsync : out std_logic;
    vga_r     : out std_logic_vector(3 downto 0);
    vga_g     : out std_logic_vector(3 downto 0);
    vga_b     : out std_logic_vector(3 downto 0);
    );
end entity;

architecture behav of framebuffer is
  -- Color params
  constant COLR_CH_W : integer                           := 4;  -- Color channel width
  constant COLR_W    : integer                           := 3 * COLR_CH_W;  -- Total color width
  constant BKG_COLR  : std_logic_vector(COLR_W downto 0) := x"8CE";  -- Background color

  -- Framebuffer params
  constant FB_WIDTH  : integer := 160;  -- 200;
  constant FB_HEIGHT : integer := 120;  -- 150;
  constant FB_PIXELS : integer := FB_WIDTH * FB_HEIGHT;  -- Number of pixels in framebuffer
  constant FB_ADDR_W : integer := clog2(FB_PIXELS);
  constant FB_DATA_W : integer := 1; -- Logic color idx
  constant FB_IMG : string := "";

  -- Display signals
  signal clk_pix, rst_pix : std_logic;
  constant COORD_W        : integer := 16;
  signal sx, sy           : std_logic_vector(COORD_W downto 0);
  signal h_sync, v_sync   : std_logic;
  signal de, frame        : std_logic;

  -- Pixel and color read addresses
  signal fb_pix_read : std_logic_vector(FB_ADDR_W - 1 downto 0);
  signal fb_colr_read : std_logic_vector(FB_ADDR_W - 1 downto 0);

begin
  display_inst : entity work.display_480(behav)
    generic map (
      COORD_WIDTH => COORD_W)
    port map (
      clk_pix => clk_pix,
      rst_pix => rst_pix,
      hsync   => h_sync,
      vsync   => v_sync,
      de      => de,
      frame   => frame,
      line    => open,
      sx      => sx,
      sy      => sy);

  bram_inst: entity work.bram_sdp(behav)
    generic map (
      WIDTH  => FB_DATA_W,
      DEPTH  => FB_PIXELS,
      INIT_F => FB_IMG,
      ADDR_W => FB_ADDR_W)
    port map (
      clk_wr  => clk_pix,
      clk_rd  => clk_pix,
      we      => open,
      addr_wr => open,
      addr_rd => fb_pix_read,
      data_wr => open,
      data_rd => fb_colr_read);

  -- Pixel clock generation @ 25MHz
  process(clk_50)
  begin
    if rissing_edge(clk_50) then
      clk_pix <= not clk_pix;
    end if;
  end process;
end architecture;
