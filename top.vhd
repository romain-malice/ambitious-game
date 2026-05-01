library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_UNSIGNED.all;
use ieee.std_logic_ARITH.all;



entity top is
    port (
        clk_50    : in  std_logic;
        rst       : in  std_logic;
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic_vector(3 downto 0);
        vga_g     : out std_logic_vector(3 downto 0);
        vga_b     : out std_logic_vector(3 downto 0)
    );
end entity;

architecture behav of top is
    signal addr : std_logic_vector(14 downto 0);
    signal data : std_logic_vector(3 downto 0);
    signal we   : std_logic;
begin
    gen_inst : entity work.frame_generator
        port map(
            clk  => clk_50,
            rst  => rst,
            addr => addr,
            data => data,
            we   => we
        );

    fb_inst : entity work.framebuffer
        port map(
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
end architecture;