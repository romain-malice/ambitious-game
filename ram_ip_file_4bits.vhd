-- vhdl file describing the ram

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY ram_ip_file_4bits IS
    PORT (
        clock     : IN  STD_LOGIC;
        data      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        rdaddress : IN  STD_LOGIC_VECTOR(14 DOWNTO 0);
        wraddress : IN  STD_LOGIC_VECTOR(14 DOWNTO 0);
        wren      : IN  STD_LOGIC;
        q         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE SYN OF ram_ip_file_4bits IS
BEGIN
    altsyncram_component : altsyncram
    GENERIC MAP (
        address_aclr_b                      => "NONE",
        address_reg_b                        => "CLOCK0",
        clock_enable_input_a                => "BYPASS",
        clock_enable_input_b                => "BYPASS",
        clock_enable_output_b               => "BYPASS",
        intended_device_family              => "Cyclone IV E",
        lpm_type                            => "altsyncram",
        numwords_a                          => 30000,
        numwords_b                          => 30000,
        operation_mode                      => "DUAL_PORT",
        outdata_aclr_b                      => "NONE",
        outdata_reg_b                       => "UNREGISTERED",
        power_up_uninitialized              => "FALSE",
        read_during_write_mode_mixed_ports  => "DONT_CARE",
        widthad_a                           => 15,
        widthad_b                           => 15,
        width_a                             => 4,
        width_b                             => 4,
        width_byteena_a                     => 1,
        init_file                           => "memory_init_4bits.mif"  -- your .mif file here!
    )
    PORT MAP (
        address_a => wraddress,
        address_b => rdaddress,
        clock0    => clock,
        data_a    => data,
        wren_a    => wren,
        q_b       => q
    );
END SYN;