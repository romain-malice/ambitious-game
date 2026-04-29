library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_ARITH.all;
use ieee.std_logic_UNSIGNED.all;

entity vga is
<<<<<<< HEAD
	port (
		CLK_50 : in std_logic;
		RED : out std_logic_vector(3 downto 0);
		GREEN : out std_logic_vector(3 downto 0);
		BLUE : out std_logic_vector(3 downto 0);
		SYNC : out std_logic_vector(1 downto 0)
	);
end vga;

architecture Behavioral of vga is
	--Sync Signals
	signal h_sync : std_logic;
	signal v_sync : std_logic;
	--Video Enables
	signal video_en : std_logic;
	signal horizontal_en : std_logic;
	signal vertical_en : std_logic;
	--Color Signals
	signal color : std_logic_vector(11 downto 0) := (others => '0');
	--Sync Counters
	signal h_cnt : std_logic_vector(10 downto 0) := (others => '0');
	signal v_cnt : std_logic_vector (10 downto 0) := (others => '0');
	constant h_back_porch : integer := 64;
	constant h_active : integer := 800;
	constant h_front_porch : integer := 56;
	constant h_sync_length : integer := 120;
	constant h_length : integer := 1040;

	constant v_back_porch : integer := 23;
	constant v_active : integer := 600;
	constant v_front_porch : integer := 37;
	constant v_sync_length : integer := 6;
	constant v_length : integer := 666;

begin
	video_en <= horizontal_en and vertical_en;

	vga_square : process
	begin
		wait until rising_edge(CLK_50);
		color <= x"8CE"; -- background color
		--Generate square
		if ((v_cnt >= v_back_porch + 200) and (v_cnt <= v_back_porch + 400)
			and (h_cnt >= h_back_porch + 300) and (h_cnt <= h_back_porch + 500)) then
			color <= "111100000000"; -- square color
		end if;
		--Generate Horizontal Sync
		if (h_cnt <= h_length - 1) and (h_cnt >= h_length - h_sync_length) then
			h_sync <= '0';
		else
			h_sync <= '1';
		end if;
		--Generate Vertical Sync
		if (v_cnt <= v_length - 1) and (v_cnt >= v_length - v_sync_length) then
			v_sync <= '0';
		else
			v_sync <= '1';
		end if;
		--Reset Horizontal Counter
		if (h_cnt = h_length - 1) then
			h_cnt <= "00000000000";
		else
			h_cnt <= h_cnt + 1;
		end if;
		--Reset Vertical Counter
		if (v_cnt = v_length - 1) and (h_cnt = h_length - 1) then
			v_cnt <= "00000000000";
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
		RED(0) <= color(8) and video_en;
		--Red LSB
		RED(1) <= color(9) and video_en;
		RED(2) <= color(10) and video_en;
		RED(3) <= color(11) and video_en; --Red MSB
		GREEN(0) <= color(4) and video_en; --Green LSB
		GREEN(1) <= color(5) and video_en;
		GREEN(2) <= color(6) and video_en;
		GREEN(3) <= color(7) and video_en; --Green MSB
		BLUE(0) <= color(0) and video_en; --Blue LSB
		BLUE(1) <= color(1) and video_en;
		BLUE(2) <= color(2) and video_en;
		BLUE(3) <= color(3) and video_en; --Blue MSB
		--Synchro
		SYNC(1) <= h_sync;
		SYNC(0) <= v_sync;
	end process vga_square;
end Behavioral;
