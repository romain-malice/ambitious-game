library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package game_package is 

    type game_state_t is (START, SEARCH, WIN, LOOSE);
    type start_state_t is (WRITING, IDLE);

end package game_package;

