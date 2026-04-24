library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clut is
  generic (
    COLR_W : integer := 12;              -- Output color width
    IDX_W  : integer := 4;               --  Color index width (16 values)
    F_PAL  : string  := "palette.mif");  -- Color palette file

  port (
    clk_read   : in std_logic;
    idx_read   : in std_logic_vector(IDX_W-1 downto 0);  -- Index to read

    colr_read : out std_logic_vector(COLR_W-1 downto 0)  -- Read color
    );
end entity clut;

architecture struct of clut is
begin	
	pal_rom_inst: entity work.pal_rom
		port map (
			address => idx_read,
			clock => clk_read,
			q => idx_read);
end architecture struct;
