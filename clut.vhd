library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clut is
  generic (
    COLR_W : integer := 12;              -- Output color width
    IDX_W  : integer := 4;               --  Color index width (16 values)
    F_PAL  : string  := "palette.mem");  -- Color palette file

  port (
    clk_write  : in std_logic;
    clk_read   : in std_logic;
    we         : in std_logic;                         -- Write enable
    idx_write  : in std_logic_vector(IDX_W downto 0);  -- Index to write to
    idx_read   : in std_logic_vector(IDX_W downto 0);  -- Index to read
    colr_write : in std_logic_vector(COL_W downto 0);  -- Written color

    colr_read : out std_logic_vector(COL_W downto 0)  -- Read color
    );
end entity clut;

architecture struct of clut is
begin
  bram_inst: entity work.bram_sdp(behav)
    generic map (
      WIDTH  => COLR_W,
      DEPTH  => 2**IDX_W,
      INIT_F => F_PAL)
    port map (
      clk_wr  => clk_write,
      clk_rd  => clk_read,
      we      => we,
      addr_wr => idx_write,
      addr_rd => idx_read,
      data_wr => colr_write,
      data_rd => colr_read);
end architecture struct;
