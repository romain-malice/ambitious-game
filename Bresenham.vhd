library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Bresenham is
    generic (
        COORD_WIDTH : integer := 10  -- Bit width for coordinates
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;												-- Start signal for a call of Bresenham
        x0      : in  std_logic_vector(COORD_WIDTH-1 downto 0);	-- Position of the plane
        y0      : in  std_logic_vector(COORD_WIDTH-1 downto 0);
        x1      : in  std_logic_vector(COORD_WIDTH-1 downto 0);	-- Point from which we draw the line
        y1      : in  std_logic_vector(COORD_WIDTH-1 downto 0);
        x_out   : out std_logic_vector(COORD_WIDTH-1 downto 0);	-- Output pixel
        y_out   : out std_logic_vector(COORD_WIDTH-1 downto 0);
        valid   : out std_logic;												-- High when one output pixel is valid
        done    : out std_logic												-- High when line is complete
    );
end Bresenham;



------------------------------------------------
--- State machine of the Bresenham algorithm ---
------------------------------------------------
-- IDLE: wait for the start signal
-- INIT: latches coordinates, computes dx, dy, step directions sx/sy 
-- DRAW: outputs one pixel per clock; updates the error term and steps x or y (or both),
-- following the classic Bresenham rule
-- FINISH: asserts done for one cycle, returns to IDLE
-------------------------------------------------


architecture Behavioral of Bresenham is

    type state_type is (IDLE, INIT, DRAW, FINISH);
    signal state : state_type := IDLE;

    signal x     : signed(COORD_WIDTH downto 0);	-- Internal signal for x0
    signal y     : signed(COORD_WIDTH downto 0);	-- Internal signal for y0
    signal dx    : signed(COORD_WIDTH downto 0);	-- |x1-x0|
    signal dy    : signed(COORD_WIDTH downto 0);	-- |y1-y0|	
    signal sx    : signed(1 downto 0);  				-- step direction in the x direction: +1 if we go right
    signal sy    : signed(1 downto 0);  				-- step direction in the y direction: +1 if we go down
    signal err   : signed(COORD_WIDTH+1 downto 0);	-- error accumulator
    signal e2    : signed(COORD_WIDTH+1 downto 0);	-- error variable used within a cycle
    signal x_end : signed(COORD_WIDTH downto 0);	-- Internal signal for x1
    signal y_end : signed(COORD_WIDTH downto 0);	-- Internal signal for y1
	 signal valid_buff : std_logic;
	 signal done_buff : std_logic;

begin

    process(clk, rst)
        variable v_dx : signed(COORD_WIDTH downto 0); -- Signed delta between x0 and x1
        variable v_dy : signed(COORD_WIDTH downto 0); -- Signed delta between y0 and y1
    begin
	 
        if rst = '0' then
            state <= IDLE;
            valid <= '0';
				valid_buff <= '0';
            done  <= '0';
				done_buff <= '0';
            x     <= (others => '0');
            y     <= (others => '0');

        elsif rising_edge(clk) then
            valid <= '0';
				valid_buff <= '0';
            done  <= '0';
				done_buff <= '0';

            case state is

                -- Wait for start pulse
                when IDLE =>
                    if start = '1' then
                        state <= INIT;
                    end if;

                -- Latch inputs and compute initial error term
                when INIT =>
                    x     <= signed(resize(unsigned(x0), COORD_WIDTH+1));
                    y     <= signed(resize(unsigned(y0), COORD_WIDTH+1));
                    x_end <= signed(resize(unsigned(x1), COORD_WIDTH+1));
                    y_end <= signed(resize(unsigned(y1), COORD_WIDTH+1));
						  --x_end <= to_signed(130, COORD_WIDTH+1);
						  --y_end <= to_signed(90, COORD_WIDTH+1);

                    v_dx := (signed(resize(unsigned(x1), COORD_WIDTH+1)) -
                            signed(resize(unsigned(x0), COORD_WIDTH+1)));
                    v_dy := (signed(resize(unsigned(y1), COORD_WIDTH+1)) -
                            signed(resize(unsigned(y0), COORD_WIDTH+1)));
						  --v_dx := -(signed(resize(unsigned(x1), COORD_WIDTH+1)) -
                      --      to_signed(130, COORD_WIDTH+1));
                    --v_dy := -(signed(resize(unsigned(y1), COORD_WIDTH+1)) -
                      --      to_signed(90, COORD_WIDTH+1));


                    -- |dx| and |dy|
                    if v_dx < 0 then
                        dx <= -v_dx;
                        sx <= to_signed(-1, 2);
                    else
                        dx <= v_dx;
                        sx <= to_signed(1, 2);
                    end if;

                    if v_dy < 0 then
                        dy <= -v_dy;
                        sy <= to_signed(-1, 2);
                    else
                        dy <= v_dy;
                        sy <= to_signed(1, 2);
                    end if;
						  
						  err <= resize(abs(v_dx), COORD_WIDTH+2) - resize(abs(v_dy), COORD_WIDTH+2);

                    -- Initial error: dx - dy (using absolute values computed above,
                    -- but we must wait one cycle; we'll reuse dx/dy next cycle)
                    -- Handled in DRAW on first entry via the registered dx/dy
                    state <= DRAW;

                -- Output one pixel per clock, step until done
                when DRAW =>
					 
                    -- On first cycle after INIT, initialise err
                    -- (dx and dy are now stable from INIT)
                    --if state = DRAW and valid_buff = '0' and done_buff = '0' then
                      --  err <= resize(dx, COORD_WIDTH+2) - resize(dy, COORD_WIDTH+2);
                    --end if;

                    -- Output current pixel
                    x_out <= std_logic_vector(x(COORD_WIDTH-1 downto 0));
                    y_out <= std_logic_vector(y(COORD_WIDTH-1 downto 0));
						  --y_out <= std_logic_vector(to_unsigned(130, COORD_WIDTH));
						  --x_out <= std_logic_vector(to_unsigned(100, COORD_WIDTH));
						  
                    valid <= '1';
						  valid_buff <= '1';

                    -- Check termination
                    if x = x_end and y = y_end then
                        state <= FINISH;
                    else
							  -- Compute both conditions using the same e2
							  if shift_left(err, 1) > -resize(dy, COORD_WIDTH+2) and
								  shift_left(err, 1) < resize(dx, COORD_WIDTH+2) then
									-- Both fire: apply both corrections together
									err <= err - resize(dy, COORD_WIDTH+2) + resize(dx, COORD_WIDTH+2);
									x   <= x + sx;
									y   <= y + sy;

							  elsif shift_left(err, 1) > -resize(dy, COORD_WIDTH+2) then
									-- Only x step
									err <= err - resize(dy, COORD_WIDTH+2);
									x   <= x + sx;

							  elsif shift_left(err, 1) < resize(dx, COORD_WIDTH+2) then
									-- Only y step
									err <= err + resize(dx, COORD_WIDTH+2);
									y   <= y + sy;
							  end if;
						 end if;

                when FINISH =>
                    done  <= '1';
						  done_buff <= '1';
                    valid <= '0';
						  valid_buff <= '0';
                    state <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;