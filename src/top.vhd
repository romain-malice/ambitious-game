library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_UNSIGNED.all;
--use ieee.std_logic_ARITH.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;




entity top is
	generic (
		MAP_DIM : integer := 200*4;
		TRIG_IDX_W_adress : integer := 10; -- Size of the trig indexes (adress input);
		HEIGHT_LIMIT : integer := 500
	);
    port (
        clk_50    : in  std_logic;
        rst       : in  std_logic;
		data_ctrl : in std_logic;
		  
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic_vector(3 downto 0);
        vga_g     : out std_logic_vector(3 downto 0);
        vga_b     : out std_logic_vector(3 downto 0);
		  
		  latch : out std_logic := '0';
		  controller_clk : out std_logic := '0'
    );
end entity;

architecture behav of top is
    signal addr : std_logic_vector(14 downto 0);
    signal data : std_logic_vector(3 downto 0);
    signal we   : std_logic;
	 
	signal x0 : unsigned(clog2(MAP_DIM) downto 0);
	signal y0 : unsigned(clog2(MAP_DIM) downto 0);
	signal heading : unsigned(TRIG_IDX_W_adress - 1 downto 0);
	signal height : unsigned(clog2(HEIGHT_LIMIT) downto 0);
	signal buttons : std_logic_vector(0 to 11);
	
	signal limit : integer := 1000000*5;
	signal timer_interrupt : std_logic;
	
	 -- Enable for the controller entity
	 signal enable : std_logic := '1';
begin
    gen_inst : entity work.voxel_engine
        port map(
            clk  => clk_50,
            rst  => rst,
            addr => addr,
            data => data,
            we   => we,
				x0 => x0,
				y0 => y0,
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
            clk_50    => clk_50,
            rst       => rst,
            addr_in   => addr,
            data_in   => data,
            we        => we,
            vga_hsync => vga_hsync,
            vga_vsync => vga_vsync,
            vga_r     => vga_r,
            vga_g     => vga_g,
            vga_b     => vga_b
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
			
end architecture;