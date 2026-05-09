library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;

entity player is
    generic (
			-- Map dimensions (should match colour_map)
			MAP_WIDTH : integer := 200*4;
			MAP_HEIGHT : integer := 150*4;
		
        MAP_DIM : integer := 200*4; -- Size of the map
        SPEED : integer := 10; -- Size of the steps the player takes
        TRIG_IDX_W_adress : integer := 10; -- Size of the trig indexes (adress input)
        TRIG_IDX_W_q : integer := 11; -- Size of the LUT output (q output)
        TURNING_ANGLE : integer := 5;
		  CLIMB_RATE : integer := 2;
        HEIGHT_LIMIT : integer := 500;
		  HEIGHT_MIN : integer := 5;
		  HEIGHT_MAX : integer := 200
    );
    port (
        clk_50 : in std_logic;
        buttons : in std_logic_vector(0 to 11);
        en : in std_logic;
		  interrupt : in std_logic;

        x : out unsigned(clog2(MAP_DIM) downto 0);
        y : out unsigned(clog2(MAP_DIM) downto 0);
        lookAngle : out unsigned(TRIG_IDX_W_adress - 1 downto 0);
        height : out unsigned(clog2(HEIGHT_LIMIT) downto 0)
    );
end entity player;


architecture behav of player is
    -- Trig
    signal sinLookAngle : signed(TRIG_IDX_W_q - 1 downto 0) := (others => '0');
    signal cosLookAngle : signed(TRIG_IDX_W_q - 1 downto 0) := (others => '0');

    -- Buttons
    
    alias btn_up : std_logic is buttons(3); -- Correct!
	 alias btn_down : std_logic is buttons(4); -- Correct!
    alias btn_left : std_logic is buttons(5); -- Correct!
    alias btn_right : std_logic is buttons(6); -- Correct!
	 
	 alias btn_climb : std_logic is buttons(10); -- R button
	 alias btn_descend : std_logic is buttons(9); -- L button

    -- Internal signals
    signal x_reg : unsigned(clog2(MAP_DIM) downto 0) := to_unsigned(264, clog2(MAP_DIM)+1);
    signal y_reg : unsigned(clog2(MAP_DIM) downto 0) := to_unsigned(340, clog2(MAP_DIM)+1);
    signal lookAngle_reg : unsigned(TRIG_IDX_W_adress - 1 downto 0) := (others => '0');
	 signal height_reg : unsigned(clog2(HEIGHT_LIMIT) downto 0) := to_unsigned(50, clog2(HEIGHT_LIMIT)+1);

    -- Internal signals for conversion
    signal lookAngle_std_logic : std_logic_vector(TRIG_IDX_W_adress - 1 downto 0);
    --signal sinLookAngle_std_logic : std_logic_vector(TRIG_IDX_W_q - 1 downto 0);
    --signal cosLookAngle_std_logic : std_logic_vector(TRIG_IDX_W_q - 1 downto 0);

    
begin

    -- Update conversion variables
    --sinLookAngle <= signed(sinLookAngle_std_logic);
    --cosLookAngle <= signed(cosLookAngle_std_logic);
    lookAngle_std_logic <= std_logic_vector(lookAngle_reg);

    -- Update output    
    x <= x_reg;
    y <= y_reg;
    lookAngle <= lookAngle_reg;
	 height <= height_reg;

    process (clk_50)
    begin
        if rising_edge(clk_50) then
            if en = '1' and interrupt = '1' then
				--if(true) then
                -- Update player position
					 if btn_up = '0' then
                    x_reg <= x_reg + unsigned(resize(shift_right(to_signed(SPEED, sinLookAngle'length) * sinLookAngle, 10), x_reg'length));
                    y_reg <= y_reg - unsigned(resize(shift_right(to_signed(SPEED, cosLookAngle'length) * cosLookAngle, 10), y_reg'length));
						 
                elsif btn_down = '0' then
					 --elsif (false) then
                    x_reg <= x_reg - unsigned(resize(shift_right(to_signed(SPEED, sinLookAngle'length) * sinLookAngle, 10), x_reg'length));
                    y_reg <= y_reg + unsigned(resize(shift_right(to_signed(SPEED, cosLookAngle'length) * cosLookAngle, 10), y_reg'length));
                end if;

                -- Update player look angle
                if btn_right = '0' then
					 --if (false) then
                    lookAngle_reg <= lookAngle_reg + TURNING_ANGLE;
                elsif btn_left = '0' then
                    lookAngle_reg <= lookAngle_reg - TURNING_ANGLE;
                end if;
					 
					 --if false then
					 if btn_climb = '0' and height_reg < HEIGHT_MAX then
						height_reg <= height_reg + CLIMB_RATE;
						
					elsif btn_descend = '0' and height_reg > HEIGHT_MIN then
						height_reg <= height_reg - CLIMB_RATE;
					end if;
            end if;
			
        end if;
    end process;

	 
	 
	 
		-- Trig LUT
    trig_inst : entity work.trig_lut
        port map(
            clk     => clk_50,
            angle   => unsigned(lookAngle_std_logic),
            sin_val => sinLookAngle,
            cos_val => cosLookAngle);
				
	
				
	

end architecture behav;