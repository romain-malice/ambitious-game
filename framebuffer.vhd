library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_UNSIGNED.all;
use ieee.std_logic_ARITH.all;

entity framebuffer is
  generic (
    -- Framebuffer params
    FB_WIDTH : integer := 200;
    FB_WIDTH_W : integer := 8;
    FB_HEIGHT : integer := 150;
    FB_ADDR_W : integer := 15;
    FB_DATA_W : integer := 4; -- Logic color idx
    FB_SCALE : integer := 4;
    FB_SCALE_W : integer := 3
  );
  port (
		buttons : in std_logic_vector(0 to 11);
    clk_50 : in std_logic;
    rst : in std_logic;
	 
	 data_in : in std_logic_vector(FB_DATA_W - 1 downto 0);
    addr_in : in std_logic_vector(FB_ADDR_W - 1 downto 0);
    we : in std_logic;

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
  constant BG_COLR : std_logic_vector(COLR_W - 1 downto 0) := x"FFF";--x"8CE"; -- Background color (sky blue)


  -- Display signals
  --constant COORD_W : integer := 16;
  signal sx, sy : std_logic_vector(10 downto 0);
  signal h_sync, v_sync : std_logic;
  signal de : std_logic;

  -- Pixel and color read addresses
  signal fb_addr_read : unsigned(FB_ADDR_W - 1 downto 0) := (others => '0');
  signal fb_colr_read : std_logic_vector(FB_DATA_W - 1 downto 0); -- Color index from ram (index)
  signal fb_pix_colr : std_logic_vector(COLR_W - 1 downto 0); -- Pixel color from clut (12bit color)

  -- Reading framebuffer
  --constant LAT : integer := 3; -- Latency (3 readings = fb + bram + clut)
  --signal read_fb : std_logic;

  -- Paint screen
  signal paint_r, paint_g, paint_b : std_logic_vector(COLR_CH_W - 1 downto 0);

  -- VGA display signals
  signal display_r : std_logic_vector(COLR_CH_W - 1 downto 0);
  signal display_g : std_logic_vector(COLR_CH_W - 1 downto 0);
  signal display_b : std_logic_vector(COLR_CH_W - 1 downto 0);

  -- Linebuffer
  signal new_frame, new_line, first_line, last_line : std_logic; -- Flags
  --signal cnt_lb_lines : std_logic_vector(FB_SCALE_W - 1 downto 0);
  signal lb_line_cnt : std_logic_vector(FB_SCALE_W - 1 downto 0);

  signal lb_line : std_logic;
  signal lb_en_in, lb_en_out : std_logic;
  signal lb_px_cnt : std_logic_vector(FB_WIDTH_W - 1 downto 0);

  constant LAT_LB : integer := 3;

  signal lb_colr_out : std_logic_vector(FB_DATA_W - 1 downto 0);
  
  

begin
  display_inst : entity work.display
    port map(
      clk_pix => clk_50,
      hsync => h_sync,
      vsync => v_sync,
      de => de,
      new_frame => new_frame,
      new_line => new_line,
      sx => sx,
      sy => sy);

  -- Sets flags when the vga process reaches the first or the last line
  h_screen_limits : process (new_line, sy)
  begin
    if new_line = '1' and sy = 24 then
      first_line <= '1';
      last_line <= '0';
    elsif new_line = '1' and sy = 24 + (FB_HEIGHT * FB_SCALE) then
      first_line <= '0';
      last_line <= '1';
    else
      first_line <= '0';
      last_line <= '0';
    end if;
  end process h_screen_limits;
  
  ram_inst : entity work.ram_ip_file_4bits
    port map(
        clock     => clk_50,
        rdaddress => std_logic_vector(fb_addr_read),
        wraddress => addr_in,
        data      => data_in,
        wren      => we,
        q         => fb_colr_read);

  

  -- Counter for vertical scaling
  lb_counting : process (clk_50) is
  begin
    if rising_edge(clk_50) then
      if first_line = '1' then
        lb_line_cnt <= (others => '0');
      elsif new_line = '1' then
        if lb_line_cnt = FB_SCALE - 1 then
          lb_line_cnt <= (others => '0');
        else
          lb_line_cnt <= lb_line_cnt + 1;
        end if;
      end if;
    end if;
  end process lb_counting;

  -- Tells if a line needs a linebuffer (all displayed lines)
  process (clk_50)
  begin
    if rising_edge(clk_50) then
      if first_line = '1' then
        lb_line <= '1';
      end if;
      if last_line = '1' then
        lb_line <= '0';
      end if;
    end if;
  end process;

  -- Enable writing in linebuffer every FB_SCALE lines
  lb_enable_input : process (lb_line, lb_line_cnt, lb_px_cnt)
  begin
    if lb_line = '1' and lb_line_cnt = 0 and lb_px_cnt < FB_WIDTH then
      lb_en_in <= '1';
    else
      lb_en_in <= '0';
    end if;
  end process lb_enable_input;

  -- Compute frame and line buffer addresses
  process (clk_50)
  begin
    if rising_edge(clk_50) then
      if new_line = '1' then
        lb_px_cnt <= (others => '0');
      elsif lb_en_in = '1' then
        fb_addr_read <= fb_addr_read + 1;
        lb_px_cnt <= lb_px_cnt + 1;
      end if;
      if new_frame = '1' then
        fb_addr_read <= (others => '0');
      end if;
    end if;
  end process;

  -- Enable line buffer output (for copied lines)
  process (clk_50)
  begin
    if rising_edge(clk_50) then
      -- Enables output whenever we are in the frame
      if sy >= 24 and sy < (24 + (FB_HEIGHT * FB_SCALE)) and
        sx >= (63 - LAT_LB) and sx < (63 + (FB_WIDTH * FB_SCALE) - LAT_LB) then  -- I think the change was here
        lb_en_out <= '1';
      else
        lb_en_out <= '0';
      end if;
    end if;
  end process;

  lb_inst : entity work.linebuffer
    port map (
      clk_50 => clk_50,
      scale => conv_std_logic_vector(FB_SCALE, FB_SCALE_W),
      line_sys => new_line,
      en_in => lb_en_in,
      data_in => fb_colr_read,
      line_pix => new_line,
      en_out => lb_en_out,
      data_out => lb_colr_out
    );

  -- Color lookup table
  clut_inst : entity work.pal_rom
    port map(
      clock => clk_50,
      address => std_logic_vector(lb_colr_out),
      q => fb_pix_colr);

		
		
  -- purpose: Paint the screen
  -- type   : combinational
  -- inputs : sx, sy
  -- outputs: paint_area
  paint_screen : process (sy, sx, fb_pix_colr) is
    variable paint_area : std_logic;
  begin -- process paint_screen
    if (sy >= 24) and (sy < 24 + (FB_SCALE * FB_HEIGHT)) and (sx >= 63) and (sx < 64 + (FB_SCALE * FB_WIDTH)) then
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
    if rising_edge(clk_50) then -- rising clock edge
      vga_hsync <= h_sync;
      vga_vsync <= v_sync;
		--vga_r <= (others => '1');
		--vga_g <= (others => '1');
		--vga_b <= (others => '1');
      vga_r <= display_r;
      vga_g <= display_g;
      vga_b <= display_b;
    end if;
  end process;
  
  
  
end architecture;