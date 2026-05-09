library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_UNSIGNED.all;
--use ieee.std_logic_ARITH.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;
use work.game_package.all;

entity top is
	generic (
		MAP_DIM : integer := 200 * 4;
		TRIG_IDX_W_adress : integer := 10; -- Size of the trig indexes (adress input);
		HEIGHT_LIMIT : integer := 500
	);

	port (
		clk_50 : in std_logic;
		rst : in std_logic;
		data_ctrl : in std_logic;

		vga_hsync : out std_logic;
		vga_vsync : out std_logic;
		vga_r : out std_logic_vector(3 downto 0);
		vga_g : out std_logic_vector(3 downto 0);
		vga_b : out std_logic_vector(3 downto 0);

		latch : out std_logic := '0';
		controller_clk : out std_logic := '0'
	);
end entity;

architecture behav of top is
	signal addr_vox : std_logic_vector(14 downto 0);
	signal data_vox : std_logic_vector(3 downto 0);
	signal we_vox : std_logic;

	signal addr_menu : std_logic_vector(14 downto 0);
	signal data_menu : std_logic_vector(3 downto 0);
	signal we_menu : std_logic;

	signal addr_fb : std_logic_vector(14 downto 0);
	signal data_fb : std_logic_vector(3 downto 0);
	signal we_fb : std_logic;

	signal x0 : unsigned(clog2(MAP_DIM) downto 0);
	signal y0 : unsigned(clog2(MAP_DIM) downto 0);
	signal heading : unsigned(TRIG_IDX_W_adress - 1 downto 0);
	signal height : unsigned(clog2(HEIGHT_LIMIT) downto 0);
	signal buttons : std_logic_vector(0 to 11);
	alias btn_start : std_logic is buttons(3);
	alias btn_A : std_logic is buttons(8);

	signal limit : integer := 1000000 * 5;
	signal timer_interrupt : std_logic;

	-- Enable for the controller entity
	signal enable : std_logic := '1';

	-- Game state
	signal game_state : game_state_t := START;
	signal flag_x : unsigned(clog2(MAP_DIM) downto 0) := (others => '0');
	signal flag_y : unsigned(clog2(MAP_DIM) downto 0) := (others => '0');
	signal flag_flag : std_logic := '0';
	signal flag_cnt : integer range 0 to 3;
	signal trigger : std_logic := '0';
	signal trigger_flag : std_logic := '1';

begin
	gen_inst : entity work.voxel_engine
		port map(
			clk => clk_50,
			rst => rst,
			addr => addr_vox,
			data => data_vox,
			we => we_vox,
			x0 => x0,
			y0 => y0,
			flag_x => flag_x,
			flag_y => flag_y,
			flag_flag => flag_flag,
			heading => heading,
			height => height
		);

	player_inst : entity work.player
		port map(
			clk_50 => clk_50,
			buttons => buttons,
			en => enable,
			interrupt => timer_interrupt,

			x => x0,
			y => y0,
			lookAngle => heading,
			height => height
		);

	fb_inst : entity work.framebuffer
		port map(
			buttons => buttons,
			clk_50 => clk_50,
			rst => rst,
			addr_in => addr_fb,
			data_in => data_fb,
			we => we_fb,
			vga_hsync => vga_hsync,
			vga_vsync => vga_vsync,
			vga_r => vga_r,
			vga_g => vga_g,
			vga_b => vga_b
		);

	controller_inst : entity work.controller
		port map(
			enable => enable,
			clk_50 => clk_50,
			data_ctrl => data_ctrl,
			latch => latch,
			controller_clk => controller_clk,
			buttons => buttons
		);

	timer_inst : entity work.timer
		port map(
			clk_50 => clk_50,
			enable => enable,
			reset => rst,
			limit => limit,
			interrupt => timer_interrupt
		);

	menu_inst : entity work.start_menu
		port map(
			clk => clk_50,
			trigger => trigger,
			addr => addr_menu,
			data => data_menu,
			we => we_menu
		);

	state_machine : process (clk_50)
	begin
		if rising_edge(clk_50) then
			case game_state is
				when START =>
					addr_fb <= addr_menu;
					data_fb <= data_menu;
					we_fb <= we_menu;

					if trigger_flag = '1' then
						trigger <= '1';
					else
						trigger <= '0';
					end if;
					trigger_flag <= '0';

					if btn_A = '1' then
						game_state <= PLAY;
						trigger_flag <= '1';
					end if;
				when PLAY =>
					addr_fb <= addr_vox;
					data_fb <= data_vox;
					we_fb <= we_vox;

					if flag_flag = '0' then
						flag_x <= to_unsigned(10 * flag_cnt, flag_x'length);
						flag_y <= to_unsigned(20 * flag_cnt, flag_x'length);
						flag_flag <= '1';
					else
						if to_integer(x0) = flag_x and to_integer(y0) = flag_y then
							flag_flag <= '0';
							if flag_cnt = 3 then
								game_state <= START;
							else
								flag_cnt <= flag_cnt + 1;
							end if;
						end if;
					end if;
			end case;
		end if;
	end process state_machine;
end architecture;