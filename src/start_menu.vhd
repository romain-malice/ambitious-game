library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;

use work.game_package.all;


entity start_menu is
  generic(
    NB_PIXELS : unsigned (14 downto 0) := to_unsigned(30000, 15)
  );
    port (
        clk  : in  std_logic;
        trigger : in std_logic;
		  
        addr : out std_logic_vector(14 downto 0);
        data : out std_logic_vector(3 downto 0);
        we   : out std_logic
    );
end entity;

architecture behav of start_menu is

  signal start_state : start_state_t := IDLE; 

  -- Internal signals 
  signal addr_reg : unsigned (14 downto 0) := (others => '0');

begin 

  process(clk)
    variable a : integer range 0 to 30000;

  begin
    if rising_edge(clk) then
      if start_state = WRITING then
        if addr_reg = NB_PIXELS then 
          we <= '0'; 
          start_state <= IDLE;
        else 
          a := to_integer(unsigned(addr));

          -- Default: light blue background 
          data <= x"B";



           -- ---- ROW 0  (y=71, base=14200) ----
          if    (a >= 14283 and a <= 14285) then data <= x"C";  -- S cols 1-3
          elsif (a >= 14290 and a <= 14294) then data <= x"C";  -- T cols 0-4
          elsif (a  = 14299)                then data <= x"C";  -- A col 2
          elsif (a >= 14304 and a <= 14307) then data <= x"C";  -- R cols 0-3
          elsif (a >= 14311 and a <= 14315) then data <= x"C";  -- T cols 0-4

          -- ---- ROW 1  (y=72, base=14400) ----
          elsif (a  = 14483)                then data <= x"C";  -- S col 0
          elsif (a  = 14492)                then data <= x"C";  -- T col 2
          elsif (a  = 14498 or a = 14500)   then data <= x"C";  -- A cols 1,3
          elsif (a  = 14504 or a = 14508)   then data <= x"C";  -- R cols 0,4
          elsif (a  = 14513)                then data <= x"C";  -- T col 2

          -- ---- ROW 2  (y=73, base=14600) ----
          elsif (a  = 14683)                then data <= x"C";  -- S col 0
          elsif (a  = 14692)                then data <= x"C";  -- T col 2
          elsif (a  = 14697 or a = 14701)   then data <= x"C";  -- A cols 0,4
          elsif (a  = 14704 or a = 14708)   then data <= x"C";  -- R cols 0,4
          elsif (a  = 14713)                then data <= x"C";  -- T col 2

          -- ---- ROW 3  (y=74, base=14800) ----
          elsif (a >= 14884 and a <= 14886) then data <= x"C";  -- S cols 1-3
          elsif (a  = 14892)                then data <= x"C";  -- T col 2
          elsif (a >= 14897 and a <= 14901) then data <= x"C";  -- A cols 0-4
          elsif (a >= 14904 and a <= 14907) then data <= x"C";  -- R cols 0-3
          elsif (a  = 14913)                then data <= x"C";  -- T col 2

          -- ---- ROW 4  (y=75, base=15000) ----
          elsif (a  = 15087)                then data <= x"C";  -- S col 4
          elsif (a  = 15092)                then data <= x"C";  -- T col 2
          elsif (a  = 15097 or a = 15101)   then data <= x"C";  -- A cols 0,4
          elsif (a  = 15104 or a = 15106)   then data <= x"C";  -- R cols 0,2
          elsif (a  = 15113)                then data <= x"C";  -- T col 2

          -- ---- ROW 5  (y=76, base=15200) ----
          elsif (a  = 15287)                then data <= x"C";  -- S col 4
          elsif (a  = 15292)                then data <= x"C";  -- T col 2
          elsif (a  = 15297 or a = 15301)   then data <= x"C";  -- A cols 0,4
          elsif (a  = 15304 or a = 15307)   then data <= x"C";  -- R cols 0,3
          elsif (a  = 15313)                then data <= x"C";  -- T col 2

          -- ---- ROW 6  (y=77, base=15400) ----
          elsif (a >= 15483 and a <= 15486) then data <= x"C";  -- S cols 0-3
          elsif (a  = 15492)                then data <= x"C";  -- T col 2
          elsif (a  = 15497 or a = 15501)   then data <= x"C";  -- A cols 0,4
          elsif (a  = 15504 or a = 15508)   then data <= x"C";  -- R cols 0,4
          elsif (a  = 15513)                then data <= x"C";  -- T col 2

          end if;


        end if; 

      -- IDLE STATE 
      else 
        if trigger = '1' then 
          if start_state = IDLE then 
            start_state <= WRITING;
            addr <= (others => '0'); 
            we <= '1';
          end if; 
        end if;
      end if;
    end if;  
      
  end process;

end architecture;