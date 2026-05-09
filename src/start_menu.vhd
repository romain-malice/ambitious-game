library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;

use work.game_package.all;


entity start_menu is
  generic(
    NB_PIXELS : std_logic_vector := std_logic_vector(to_unsigned(30000, 15))
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

begin

  process(trigger)
  begin
    
  end process; 
    

  process(clk)
  begin
    if rising_edge(clk) then
      if start_state = WRITING then
        if addr = NB_PIXELS then 
          we <= '0'; 
          start_state <= IDLE;
        else 



          if unsigned(addr) <= 125 and unsigned(addr) >= 75 then
            data <= x"A";
          else 
            data <= x"C";
          end if;
        end if;



     
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