library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_utils_pkg.all;

entity voxel_engine is
    generic (
        PLANE_ALTITUDE : integer := 50;
        HEIGHT_LIMIT : integer := 500;
        --HEADING : integer := 0;
        FB_WIDTH : integer := 200;
        FB_HEIGHT : integer := 150;
        TAN_20 : integer := 373; -- Should be divided by 1024
        TAN_15 : integer := 274; -- Should be divided by 1024
        --Z_MAX       : integer := 250;
        --Z_MIN			: integer := 25;
        MAP_DIM : integer := 200 * 4;
        TRIG_IDX_W_adress : integer := 10; -- Size of the trig indexes (adress input)

        --X0          : integer := 4*66;
        --Y0          : integer := 4*110-100;
        COORD_WIDTH : integer := 10;
        LAT_LUT : integer := 3
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        x0 : in unsigned(clog2(MAP_DIM) downto 0);
        y0 : in unsigned(clog2(MAP_DIM) downto 0);
        heading : in unsigned(TRIG_IDX_W_adress - 1 downto 0);
        height : in unsigned(clog2(HEIGHT_LIMIT) downto 0);

        addr : out std_logic_vector(14 downto 0);
        data : out std_logic_vector(3 downto 0);
        we : out std_logic
    );
end entity;

architecture behav of voxel_engine is

    -- Map parameters
    --constant MAP_WIDTH : integer;
    --constant MAP_HEIGHT;

    -- Horizon (parameterizable)
    constant HORIZON_ROW : integer := 49;
    constant SKY_COLOR : std_logic_vector(3 downto 0) := x"A";

    -- Angle stepping
    constant ANGLE_START : integer := 896; -- -45° in 10-bit LUT encoding
    constant ANGLE_EXTRA : integer := 56; -- extra steps to distribute (256-200)

    -- State machine
    type state_t is (LATCH_DATA, TRIG_WAIT, SKY_FILL, RAY_MARCH, NEXT_COL);
    signal state : state_t := TRIG_WAIT;

    -- Distance computation
    --signal Z_MIN : integer range 0 to 65000 := to_integer(shift_right(to_unsigned(PLANE_ALTITUDE*TAN_20, 32), 10));
    --signal Z_MAX : integer range 0 to 65000 := to_integer(shift_right(to_unsigned(PLANE_ALTITUDE/TAN_15, 32), 10));

    -- Pixel height computation
    --signal SCALING : integer := (FB_HEIGHT - 1 - HORIZON_ROW) * Z_MIN * Z_MAX / (Z_MAX - Z_MIN);	 

    -- Latched plane state values
    signal plane_x0 : integer range 0 to 1023;
    signal plane_y0 : integer range 0 to 1023;
    signal plane_heading : integer range 0 to 1023;
    signal plane_height : integer range 0 to 255;

    -- FOV parameters
    signal Z_MIN : integer range 0 to 200000;
    signal Z_MAX : integer range 0 to 200000;
    signal SCALING : integer range 0 to 10000;

    --signal SCALING : integer := (FB_HEIGHT - 1 - HORIZON_ROW) * Z_MIN * Z_MAX / (Z_MAX - Z_MIN);	 

    -- Column and depth tracking
    signal screen_col : integer range 0 to FB_WIDTH - 1 := 0;
    signal z : integer range 0 to 1023 := 0;
    signal color_buffer : std_logic_vector(3 downto 0);

    -- Angle accumulator (Bresenham-style)
    signal angle : unsigned(9 downto 0) := to_unsigned(ANGLE_START - LAT_LUT, 10);
    signal angle_err : integer range 0 to 511 := 0;

    -- Trig LUT outputs (fixed-point, scaled by 1024)
    signal sin_val : signed(10 downto 0);
    signal cos_val : signed(10 downto 0);

    -- Latched sin/cos for current column (stable during ray march)
    signal sin_col : signed(10 downto 0);
    signal cos_col : signed(10 downto 0);
    signal trig_lat : integer range 0 to LAT_LUT := LAT_LUT;

    -- Sky fill counter
    signal sky_row : integer range 0 to FB_HEIGHT - 1 := 0;

    -- Colormap
    signal map_x : integer range 0 to 4 * FB_WIDTH - 1;
    signal map_y : integer range 0 to 4 * FB_HEIGHT - 1;
    signal color : std_logic_vector(3 downto 0);
    signal altitude : integer range 0 to 255;

begin

    -- Trig LUT
    trig_inst : entity work.trig_lut
        port map(
            clk => clk,
            angle => angle,
            sin_val => sin_val,
            cos_val => cos_val);

    -- Colormap (combinational)
    cmap_inst : entity work.colourmap
        port map(
            x => map_x,
            y => map_y,
            color => color,
            altitude => altitude);

    -- Parametric ray: map (x,y) from current z and latched sin/cos
    -- Fixed-point: sin/cos are scaled by 1024, so we shift right by 10
    map_x <= plane_x0 + to_integer(shift_right(to_signed(z, 11) * sin_col, 10));
    map_y <= plane_y0 - to_integer(shift_right(to_signed(z, 11) * cos_col, 10));

    process (clk)
        variable screen_y : integer range 0 to FB_HEIGHT - 1;
        variable screen_y_next : integer range 0 to FB_HEIGHT - 1;
        variable y_buffer : integer range 0 to FB_HEIGHT := FB_HEIGHT;
        variable copy_pixel : std_logic := '0';

        variable z_min_pxl : integer range 0 to 200000;
        variable z_max_pxl : integer range 0 to 200000;
        variable scaling_pxl : integer range 0 to 10000;

    begin
        if rising_edge(clk) then
            we <= '0';

            if rst = '0' then
                state <= TRIG_WAIT;
                screen_col <= 0;
                trig_lat <= LAT_LUT;
                angle <= to_unsigned(ANGLE_START - LAT_LUT + plane_HEADING, 10);
                angle_err <= 0;
                sky_row <= 0;
                z <= Z_MAX;

            else
                case state is

                        -- Latch the variable describing the state of the plane
                    when LATCH_DATA =>
                        -- Sate variables of the plane
                        plane_x0 <= to_integer(x0);
                        plane_Y0 <= to_integer(y0);
                        plane_height <= to_integer(height);
                        plane_heading <= to_integer(heading);

                        -- FOV parameters update
                        Z_MIN <= to_integer(shift_right(to_unsigned(plane_height * TAN_20, 32), 10));
                        Z_MAX <= (plane_height * 1024)/TAN_15;

                        state <= TRIG_WAIT;

                        -- Wait for LUT to settle for this column's 

                    when TRIG_WAIT =>
                        if trig_lat > 0 then
                            trig_lat <= trig_lat - 1;
                            if screen_col = 0 then
                                SCALING <= (FB_HEIGHT - 1 - HORIZON_ROW) * Z_MIN * Z_MAX / (Z_MAX - Z_MIN);
                            end if;

                        else
                            -- Latch sin/cos for this column, begin sky fill
                            sin_col <= sin_val;
                            cos_col <= cos_val;
                            sky_row <= 0;
                            z <= Z_MIN;
                            y_buffer := FB_HEIGHT;
                            state <= SKY_FILL;
                        end if;

                        -- Fill sky rows for this column top-down
                    when SKY_FILL =>
                        we <= '1';
                        addr <= std_logic_vector(to_unsigned(sky_row * FB_WIDTH + screen_col, 15));
                        data <= SKY_COLOR;
                        if sky_row = HORIZON_ROW - 1 then
                            state <= RAY_MARCH;
                        else
                            sky_row <= sky_row + 1;
                        end if;

                        -- March ray from z=Z_MAX (far=top) down to z=0 (near=bottom)
                    when RAY_MARCH =>
                        --screen_y := (1200/z) + 29;
                        --screen_y := SCALING*((1/z) - (1/Z_MAX)) + HORIZON_ROW;
                        z_min_pxl := to_integer(shift_right(to_unsigned(plane_height * TAN_20, 32), 10));
                        z_max_pxl := (plane_height * 1024)/TAN_15;

                        scaling_pxl := (FB_HEIGHT - 1 - HORIZON_ROW) * z_min_pxl * z_max_pxl / (z_max_pxl - z_min_pxl);

                        --screen_y := SCALING/z - SCALING/Z_MAX + HORIZON_ROW;
                        screen_y := SCALING/z - SCALING/Z_MAX + HORIZON_ROW;

                        if y_buffer > screen_y then
                            -- Fill one row per clock downward toward screen_y
                            we <= '1';
                            addr <= std_logic_vector(to_unsigned((y_buffer - 1) * FB_WIDTH + screen_col, 15));
                            data <= color;
                            y_buffer := y_buffer - 1;
                            -- z stays the same until gap is fully filled
                        else
                            -- Current z fully painted, advance to next z
                            if z = Z_MAX then
                                state <= NEXT_COL;
                            else
                                z <= z + 1;
                            end if;
                        end if;

                        -- Advance to next column, step angle with Bresenham accumulator
                    when NEXT_COL =>
                        if screen_col = FB_WIDTH - 1 then
                            -- Frame complete, restart
                            screen_col <= 0;
                            angle <= to_unsigned(ANGLE_START - LAT_LUT + plane_HEADING, 10);
                            angle_err <= 0;
                            state <= LATCH_DATA;

                        else
                            screen_col <= screen_col + 1;
                            state <= TRIG_WAIT;
                            -- Bresenham-style angle stepping
                            if angle_err + ANGLE_EXTRA >= FB_WIDTH then
                                angle <= angle + 2;
                                angle_err <= angle_err + ANGLE_EXTRA - FB_WIDTH;
                            else
                                angle <= angle + 1;
                                angle_err <= angle_err + ANGLE_EXTRA;
                            end if;
                        end if;
                        trig_lat <= LAT_LUT;
                        y_buffer := FB_HEIGHT;
                        copy_pixel := '0';

                end case;
            end if;
        end if;
    end process;

end architecture;