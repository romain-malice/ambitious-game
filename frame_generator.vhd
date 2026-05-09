library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_UNSIGNED.all;
--use ieee.std_logic_ARITH.all;
use ieee.numeric_std.all;




entity frame_generator is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        addr  : out std_logic_vector(14 downto 0);
        data  : out std_logic_vector(3 downto 0);
        we    : out std_logic
    );
end entity;

architecture behav of frame_generator is
  

    constant FB_WIDTH  : integer := 200;
    constant FB_HEIGHT : integer := 150;
	 
	 constant X0 : integer := 66;
	 constant Y0 : integer := 120;
	 constant Z_MAX : integer := 70;
	 
	 constant LAT_LUT : integer := 3;
	 constant ANGLE_MINUS_45 : integer := 896;
	 
	 constant COORD_WIDTH : integer := 10;
	 
	 
	 
	 
	 signal latency : integer range 0 to 16 := LAT_LUT;
	 

    signal x : integer range 0 to FB_WIDTH - 1 := 0;
    signal y : integer range 0 to FB_HEIGHT - 1 := 0;
	 signal starter : std_logic := '1';
	 	 
	 signal x_sine : signed(15 downto 0);
	 signal sine_result : signed(15 downto 0);
	 
	 signal buff_data : std_logic_vector(3 downto 0);
	 
	 signal y_cos : signed(15 downto 0);
	 signal cos_result : signed(15 downto 0);
	 
	 signal angle : unsigned(9 downto 0) := to_unsigned(ANGLE_MINUS_45 - LAT_LUT, 10);
	 
	 signal sin_val : signed(10 downto 0);
	 signal cos_val : signed(10 downto 0);
	 
	-- Table that stores the x and y values corresponding to a circle
	type array_256_t is array (0 to 255) of integer range 0 to 255;
	signal x_array : array_256_t;
	signal y_array : array_256_t;
	signal counter : integer range 0 to 255 := 0;
	
	signal circle_ok : std_logic := '0';
	
	-- Bresenham variables
	signal x0_br : std_logic_vector(COORD_WIDTH-1 downto 0);
	signal y0_br : std_logic_vector(COORD_WIDTH-1 downto 0);
	signal x1_br : std_logic_vector(COORD_WIDTH-1 downto 0);
	signal y1_br : std_logic_vector(COORD_WIDTH-1 downto 0);
	signal x_out_br : std_logic_vector(COORD_WIDTH-1 downto 0);
	signal y_out_br : std_logic_vector(COORD_WIDTH-1 downto 0);
	signal start_br : std_logic := '0';
	signal valid_br : std_logic;
	signal done_br : std_logic;
	signal br_active : std_logic := '0';
	
	type array_2Z_t is array (0 to 2*Z_MAX) of integer range 0 to 512;
	signal x_array_br : array_2Z_t := (others => 0);
	signal y_array_br : array_2Z_t := (others => 0);
	signal counter_br : integer range 0 to 2*Z_MAX := 0;
	
	signal br_started : std_logic := '0';





begin

process(clk)
	begin
	if rising_edge(clk) then
		we <= '1';
		start_br <= '0';	
		
		if rst = '0' then
			x    <= 0;
			y    <= 0;
			we   <= '0';
			
		
		elsif starter = '1' then
		
			if latency > 0 then
				latency <= latency - 1;
				counter <= 0;
			else
				counter <= counter + 1;	
			end if;
				
			
			
			if br_active = '0' then
				-- sin and cos computation --
				x_sine <= resize(shift_right(to_signed(Z_MAX, 11) * sin_val, 10), 16);
				sine_result <= to_signed(X0, 16) + x_sine;

				y_cos <= resize(shift_right(to_signed(Z_MAX, 11) * cos_val, 10), 16);
				cos_result <= to_signed(Y0, 16) - y_cos;
				
				
					
				--if angle /= 896 and angle /= 895 and angle /= 897 then
				if latency = 0 then
					x_array(counter) <= to_integer(sine_result);
					y_array(counter) <= to_integer(cos_result);
				end if;
					
				
				
				-- Angle update
				if angle = 127 then
					br_active <= '1';
					start_br <= '1';
					x1_br <= std_logic_vector(to_unsigned(x_array(0), COORD_WIDTH));
					y1_br <= std_logic_vector(to_unsigned(y_array(0), COORD_WIDTH));
					x0_br <= std_logic_vector(to_unsigned(X0, COORD_WIDTH));
					y0_br <= std_logic_vector(to_unsigned(Y0, COORD_WIDTH));
					--starter <= '0';
				else
					angle <= angle + 1;
					
				end if;
				
			
			
			else
				if start_br = '1' then
						start_br <= '0';
				else		
				--elsif br_active = '1' then
					if br_started = '0' then
							start_br <= '1';
							br_started <= '1';
							--x0_br <= std_logic_vector(to_unsigned(X0, COORD_WIDTH));
							--y0_br <= std_logic_vector(to_unsigned(Y0, COORD_WIDTH));
							--x1_br <= std_logic_vector(resize(sine_result, 10));
							--y1_br <= std_logic_vector(resize(cos_result, 10));
							--x1_br <= std_logic_vector(to_unsigned(x_array(200), COORD_WIDTH));
							--y1_br <= std_logic_vector(to_unsigned(y_array(200), COORD_WIDTH));

					
					elsif valid_br = '1' and counter_br < 2*Z_MAX then
						x_array_br(counter_br) <= to_integer(unsigned(x_out_br));
						y_array_br(counter_br) <= to_integer(unsigned(y_out_br));
						counter_br <= counter_br + 1;
					
					
					elsif done_br = '1' or counter_br = 2*Z_MAX-1 then
						starter <= '0';
						
					end if;
				--else
					--counter <= counter + 1;
				end if;
			end if;	
			
			
			
		else
		
		
			-- Compute current address
			we   <= '1';
			addr <= std_logic_vector(to_unsigned(y * FB_WIDTH + x, 15));
	 
			-- Background init
			if starter = '1' then
				data <= x"8";
				
				
			else
					
					
				-----------------------
				-- Trigonometry test --
				-----------------------
				
				
				data <= x"8";
				
				
				
				
					
				-- Draw the circle
					
				counter <= 0;
				circle_ok <= '0';
				
				

				
				
				
				
				-- Draw the origin
				if x=X0 and y=Y0 then
					data <= x"C";
				
						
				
				
					
				-- Draw a point of the circle
				--elsif x= to_integer(sine_result) and y =to_integer(cos_result) then
					--data <= x"4";

				-- Draw map objects
				elsif x >= 50 and x <= 60 and y >= 60 and y <= 63 then -- ship
					data <= x"3";

				elsif (y >= 10) and (x >= 120 + (y - 10)) and (x <= 140 - (y - 10)) then  -- iceberg
					data <= x"C";
				elsif x>=65 and x<=67 and y>=50 and y<100 then -- pier
					data <= x"0";
				elsif y > 99 then	-- beach
					data <= x"4";

				end if;
				
				
				
				for counter in 0 to 255 loop
					if x=x_array(counter) then
						if y=y_array(counter) then -- For a circle
						--if y = Z_MAX then
						data <= x"4";
						end if;
					end if;
				end loop;
				
				
				
				
				-- Draw Bresenham
				for counter in 0 to 2*Z_MAX loop
					if x=x_array_br(counter) then
						if y=y_array_br(counter) then
							if counter < Z_MAX then
								data <= x"5";
							else
								data <= x"2";
							end if;
						end if;
					end if;
				end loop;
				
				
				
				
			end if;
						
					 

			-- Advance to next pixel
			if x = FB_WIDTH - 1 then
				x <= 0;
				if y = FB_HEIGHT - 1 then
					x <= 0;
					y <= 0;
					
				else
					y <= y + 1;
				end if;
			else
				x <= x + 1;
			end if;
		end if;
	end if;
end process;
	 
-- Trigonometry LUT
  trig_inst : entity work.trig_lut
    port map(
      clk => clk,
      angle => angle,
      sin_val => sin_val,
		cos_val => cos_val);
		
		
		
-- Bresenham
	Bresenham_inst : entity work.Bresenham
		port map(
			clk => clk,
			rst => rst,
			start => start_br,
			x0 => x0_br,
			y0 => y0_br,
			x1 => x1_br,
			y1 => y1_br,
			x_out => x_out_br,
			y_out => y_out_br,
			valid => valid_br,
			done => done_br
		);
		
		
end architecture;




