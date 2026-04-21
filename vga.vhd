library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.screen_pkg.all;

entity vga is
  port (
    CLK_50 : in std_logic;

    current_pixel : in  std_logic;
    h_frame       : out integer range 0 to SCREEN_WIDTH-1  := 0;
    v_frame       : out integer range 0 to SCREEN_HEIGHT-1 := 0;

    RED   : out std_logic_vector(3 downto 0);
    GREEN : out std_logic_vector(3 downto 0);
    BLUE  : out std_logic_vector(3 downto 0);
    SYNC  : out std_logic_vector(1 downto 0)
    );
end vga;
architecture behav of vga is
-- Pixel clock
  signal px_clk          : std_logic;
--Sync Signals
  signal h_sync          : std_logic;
  signal v_sync          : std_logic;
--Video Enables
  signal video_en        : std_logic;
  signal horizontal_en   : std_logic;
  signal vertical_en     : std_logic;
--Color Signals
  signal color           : std_logic_vector(11 downto 0) := (others => '0');
--Sync Counters
  signal h_cnt           : integer                       := 0;
  signal v_cnt           : integer                       := 0;
  constant h_back_porch  : integer                       := 48;   -- 64;
  constant h_active      : integer                       := 640;  -- 800;
  constant h_front_porch : integer                       := 16;   -- 56;
  constant h_sync_length : integer                       := 96;   -- 120;
  constant h_length      : integer                       := 800;  -- 1040;
  constant v_back_porch  : integer                       := 33;   -- 23;
  constant v_active      : integer                       := 480;  -- 600;
  constant v_front_porch : integer                       := 10;   -- 37;
  constant v_sync_length : integer                       := 2;    -- 6;
  constant v_length      : integer                       := 525;  -- 666;
begin
  video_en <= horizontal_en and vertical_en;
  pixel_read : process(px_clk)
  begin
    if rising_edge(px_clk) then
      if (video_en = '1') or (h_cnt = h_back_porch - 1) then
        h_frame <= h_cnt - h_back_porch + 1;
        v_frame <= v_cnt - v_back_porch;
      end if;
    end if;
  end process pixel_read;

  screen_write : process(px_clk)
  begin
    if rising_edge(px_clk) then
      -- Choose pixel color
      if (video_en = '1') then
        case current_pixel is
          when '1' =>
            color <= "000000001111";
          when '0' =>
            color <= "000011110000";
        end case;
      end if;
      --Generate Horizontal Sync
      if (h_cnt <= h_length-1) and (h_cnt >= h_length - h_sync_length) then
        h_sync <= '0';
      else
        h_sync <= '1';
      end if;
      --Generate Vertical Sync
      if (v_cnt <= v_length-1) and (v_cnt >= v_length - v_sync_length) then
        v_sync <= '0';
      else
        v_sync <= '1';
      end if;
      --Reset Horizontal Counter
      if (h_cnt = h_length - 1) then
        h_cnt <= 0;
      else
        h_cnt <= h_cnt + 1;
      end if;
      --Reset Vertical Counter
      if (v_cnt = v_length - 1) and (h_cnt = h_length - 1) then
        v_cnt <= 0;
      elsif (h_cnt = h_length - 1) then
        v_cnt <= v_cnt + 1;
      end if;
      --Generate Horizontal Data
      if (h_cnt >= 63 and h_cnt <= 863) then
        horizontal_en <= '1';
      else
        horizontal_en <= '0';
      end if;
      --Generate Vertical Data
      if (v_cnt >= 24 and v_cnt <= 623) then
        vertical_en <= '1';
      else
        vertical_en <= '0';
      end if;
      --Assign pins to color VGA
      RED(0)   <= color(8) and video_en;   --Red LSB
      RED(1)   <= color(9) and video_en;
      RED(2)   <= color(10) and video_en;
      RED(3)   <= color(11) and video_en;  --Red MSB
      GREEN(0) <= color(4) and video_en;   --Green LSB

      GREEN(1) <= color(5) and video_en;
      GREEN(2) <= color(6) and video_en;
      GREEN(3) <= color(7) and video_en;  --Green MSB
      BLUE(0)  <= color(0) and video_en;  --Blue LSB
      BLUE(1)  <= color(1) and video_en;
      BLUE(2)  <= color(2) and video_en;
      BLUE(3)  <= color(3) and video_en;  --Blue MSB
      --Synchro
      SYNC(1)  <= h_sync;
      SYNC(0)  <= v_sync;
    end if;
  end process screen_write;

  pixel_clock : process(clk_50)
  begin
    if rising_edge(clk_50) then
      px_clk <= not px_clk;
    end if;
  end process;
end behav;
