library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity game is
	port (
		clk_50 : in std_logic;
		controller_data : in std_logic;
		
		red, green, blue : out std_logic_vector(3 downto 0);
		sync : out std_logic_vector(1 downto 0);
		controller_clk, controller_latch : out std_logic
	);
end entity game;
	
architecture struct of game is
	signal buttons_s : std_logic_vector(0 to 11) := (others => '0');
	signal enable_s : std_logic := '0';
	signal limit_s : integer := 833_333; -- 60Hz
begin
	controller : entity work.controller(behav)
		port map (
			clk_50 => clk_50, enable => enable_s, data => controller_data,
			buttons => buttons_s, latch => controller_latch, controller_clk => controller_clk
		);
	
	timer : entity work.timer(behav) -- Get data at 60Hz
		port map (
			clk_50 => clk_50, reset => '0', enable => '1', limit => limit_s,
			interrupt => enable_s
		);
		
	vga : entity work.vga(Behavioral)
		port map (
			clk_50 => clk_50,
			RED => red, GREEN => green, BLUE => blue, SYNC => sync
		);
end architecture struct;