library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_UNSIGNED.all;
use ieee.std_logic_ARITH.all;

entity linebuffer is
    generic (
        DATA_W : integer := 4; -- Width of data (-> color index)
        LEN : integer := 800;
        ADDR_W : integer := 10;
        SCALE_W : integer := 3
    );
    port (
        clk_50 : in std_logic;
        scale : in std_logic_vector(SCALE_W - 1 downto 0);

        -- Input domain
        line_sys : in std_logic;
        en_in : in std_logic; -- Enable writing
        data_in : in std_logic_vector(DATA_W - 1 downto 0);

        -- Output domain
        line_pix : in std_logic;
        en_out : in std_logic; -- Enable reading
        data_out : out std_logic_vector(DATA_W - 1 downto 0)
    );
end entity linebuffer;

architecture behav of linebuffer is

    -- Read output data
    signal addr_out : std_logic_vector(ADDR_W - 1 downto 0);
    signal h_cnt : std_logic_vector(ADDR_W - 1 downto 0);

    -- Writing parameters
    signal we : std_logic; -- Write enable
    signal addr_in : std_logic_vector(ADDR_W - 1 downto 0);

begin
    ram_inst : entity work.linebuffer_ram
        port map(
            clock => clk_50,
            data => data_in,
            rdaddress => addr_out,
            wraddress => addr_in,
            wren => we,
            q => data_out
        );

    read : process (clk_50) is
    begin
        if rising_edge(clk_50) then
            -- Reset counters at start of new line
            if line_pix = '1' then
                addr_out <= (others => '0');
                h_cnt <= (others => '0');
            end if;

            -- Increment counters
            if en_out = '1' then
                if h_cnt = scale - 1 then
                    h_cnt <= (others => '0');
                    if addr_out /= LEN - 1 then
                        addr_out <= addr_out + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;
            end if;
        end if;
    end process read;

    write : process (clk_50) is
    begin
        if rising_edge(clk_50) then
            -- (De)activate write enable
            if en_in = '1' then
                we <= '1';
            end if;

            if addr_in = LEN - 1 then
                we <= '0';
            end if;

            -- Update control signals
            if we = '1' then
                addr_in <= addr_in + 1;
            end if;

            if line_sys = '1' then
                addr_in <= (others => '0');
                we <= '0';
            end if;
        end if;
    end process write;
end architecture behav;