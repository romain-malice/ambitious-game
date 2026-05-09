library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;

use work.game_package.all;


entity start_menu is
  generic(
    NB_PIXELS : unsigned(14 downto 0) := to_unsigned(30_000, 15)
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
  signal addr_reg : unsigned(14 downto 0) := (others => '0'); 

begin  

  process(clk)
  begin
    if rising_edge(clk) then
      if start_state = WRITING then
        if addr_reg = NB_PIXELS then 
          we <= '0'; 
          start_state <= IDLE;
        else 
          if unsigned(addr_reg) <= 125 and unsigned(addr_reg) >= 75 then
            data <= x"A";
          else 
            data <= x"C";
          end if;

          addr_reg <= addr_reg + 1;
        end if; 
      else -- IDLE state
        if trigger = '1' then 
          if start_state = IDLE then 
            start_state <= WRITING;
            addr_reg <= (others => '0'); 
            we <= '1';
          end if; 
        end if;
      end if;

      addr <= std_logic_vector(addr_reg);
    end if;  
      
  end process;

end architecture;