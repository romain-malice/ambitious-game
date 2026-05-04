library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;

entity player is
    generic (
        MAP_DIM : integer := 100; -- Size of the map
        SPEED : integer := 10; -- Size of the steps the player takes
        TRIG_IDX_W : integer := 8; -- Size of the trig indexes
        TURNING_ANGLE : integer := 1;
        HEIGHT_LIMIT : integer := 20
    );
    port (
        clk_50 : in std_logic;
        buttons : in std_logic_vector(0 to 11);
        en : in std_logic;

        x : out signed(clog2(MAP_DIM) - 2 downto 0);
        y : out signed(clog2(MAP_DIM) - 2 downto 0);
        lookAngle : out unsigned(TRIG_IDX_W-1 downto 0);
        height : out unsigned(clog2(HEIGHT_LIMIT)-1 downto 0)
    );
end entity player;

architecture Rtlgit of player is
    -- Trig
    signal sinLookAngle : signed(TRIG_IDX_W - 1 downto 0);
    signal cosLookAngle : signed(TRIG_IDX_W - 1 downto 0);

    -- Buttons
    alias btn_up : std_logic is buttons(4);
    alias btn_down : std_logic is buttons(5);
    alias btn_left : std_logic is buttons(6);
    alias btn_right : std_logic is buttons(7);

    -- Internal signals
    signal x_reg : signed(clog2(MAP_DIM) - 2 downto 0) := (others => '0');
    signal y_reg : signed(clog2(MAP_DIM) - 2 downto 0) := (others => '0');
    signal lookAngle_reg : unsigned(TRIG_IDX_W-1 downto 0) := (others => '0');

    -- Internal signals for conversion
    

begin
    -- Update output    
        x <= x_reg ;
        y <= y_reg ;
        lookAngle <= lookAngle_reg ; 
    
    process (clk_50)
    begin
        if rising_edge(clk_50) then
            if en = '1' then 
                -- Update player position
                if btn_up = '1' and btn_down = '0' then
                    x_reg <= x_reg + shift_right(to_signed(SPEED, cosLookAngle'length) * cosLookAngle, 10);
                    y_reg <= y_reg + shift_right(to_signed(SPEED, sinLookAngle'length) * sinLookAngle, 10);
                elsif btn_down = '1' and btn_up = '0' then
                    x_reg <= x_reg - shift_right(to_signed(SPEED, cosLookAngle'length) * cosLookAngle, 10);
                    y_reg <= y_reg - shift_right(to_signed(SPEED, sinLookAngle'length) * sinLookAngle, 10);
                end if;

                -- Update player look angle
                if btn_left = '1' and btn_right = '0' then
                    lookAngle_reg <= lookAngle_reg + 1;
                elsif btn_right = '1' and btn_left = '0' then
                    lookAngle_reg <= lookAngle_reg - 1;
                end if;
            end if;
        end if;
    end process;

    process (clk_50)
    begin
        if rising_edge(clk_50) then
            height <= to_unsigned(5, height'length);
        end if;
    end process;

    sin_lut_inst : entity work.sin_lut
        port map(
            address => lookAngle_reg,
            clock => clk_50,
            q => std_logic_vector(sinLookAngle)
        );

    cos_lut_inst : entity work.cos_lut
        port map(
            address => lookAngle_reg,
            clock => clk_50,
            q => std_logic_vector(cosLookAngle)
        );

end architecture Rtl;