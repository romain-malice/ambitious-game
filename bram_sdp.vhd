-- Simple dual port ram module
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.calc_pkg.all;

entity bram_sdp is

  generic (
    WIDTH : integer := 8;
    DEPTH : integer := 256;
    INIT_F : string := "";
    ADDR_W : integer := clog2(DEPTH));
  port map (
    clk_wr : in std_logic;
    clk_rd : in std_logic;
    we : in std_logic;
    addr_wr : in std_logic_vector(ADDR_W-1  downto 0);
    addr_rd : in std_logic_vector(ADDR_W-1  downto 0);
    data_wr : in std_logic_vector(WIDTH-1 downto 0);
    data_rd : out std_logic_vector(WIDTH-1 downto 0));
end entity bram_sdp;

architecture behav of bram_sdp is

  type mem_t is array(0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
  signal mem : mem_t;

begin  -- architecture behav

  -- purpose: Writing data to the memory
  -- type   : combinational
  -- inputs : clk_wr, data_wr, addr_wr
  -- outputs:
  write: process (clk_wr) is
  begin  -- process write
    if rising_edge(clk_wr) then
      if we = '1' then
        mem(addr_wr) <= data_wr;
      end if;
    end if;
  end process write;

  -- purpose: Reading data from the memory
  -- type   : combinational
  -- inputs : clk_rd, addr_rd
  -- outputs: data_rd
  read: process (clk_rd) is
  begin  -- process read
    data_rd <= mem(addr_rd);
  end process read;

end architecture behav;
