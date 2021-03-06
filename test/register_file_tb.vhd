library ieee;
library vunit_lib;
library osvvm;

use ieee.std_logic_1164.all;
use osvvm.TbUtilPkg.all;
context vunit_lib.vunit_context;
use work.common_pkg.all;


entity register_file_tb is
  generic(runner_cfg : string := runner_cfg_default);
end entity;


architecture tb of register_file_tb is
    constant period : time := 2 ps;
    signal clk : std_logic := '0';
    signal addressing_mode : std_logic_vector(5 downto 0);
    signal branch_condition : std_logic_vector(3 downto 0);
    signal first_reg : std_logic_vector(4 downto 0);
    signal new_value : std_logic_vector(15 downto 0);
    signal alu_result : std_logic_vector(7 downto 0);
    signal immediate : std_logic_vector(15 downto 0);
    signal second_reg : std_logic_vector(4 downto 1);
    signal write_register01 : std_logic;
    signal write_new_value : std_logic_vector(1 downto 0);
    signal write_alu_result : std_logic;
    signal write_memory : std_logic;
    signal write_xyzs : std_logic;
    signal address : std_logic_vector(15 downto 0);
    signal branch_valid : std_logic;
    signal first_reg_value : std_logic_vector(15 downto 0);
    signal status_flags : std_logic_vector(7 downto 0);
    signal second_reg_value : std_logic_vector(15 downto 0);
    signal register_value: std_logic_vector(7 downto 0);
    signal z_reg_value : std_logic_vector(15 downto 0);
begin
    dut: entity work.register_file
    port map(
        clk => clk,
        addressing_mode => addressing_mode,
        branch_condition => branch_condition,
        first_reg => first_reg,
        new_value => new_value,
        alu_result => alu_result,
        immediate => immediate,
        second_reg => second_reg,
        write_register01 => write_register01,
        write_new_value => write_new_value,
        write_alu_result => write_alu_result,
        write_memory => write_memory,
        write_xyzs => write_xyzs,
        address => address,
        branch_valid => branch_valid,
        first_reg_value => first_reg_value,
        status_flags => status_flags,
        second_reg_value => second_reg_value,
        register_value => register_value,
        z_reg_value => z_reg_value
    );

    CreateClock(clk, period);

    test_runner : process
        variable expected_byte : std_logic_vector(7 downto 0) := (others => '0');
        variable expected_short : std_logic_vector(15 downto 0) := (others => '0');
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("init_state") then
                wait for 1 ps;
                check_equal(address, expected_short);
                check_equal(branch_valid, 'U');
                check_equal(first_reg_value, std_logic_vector'(x"7777"));
                check_equal(second_reg_value, std_logic_vector'(x"7777"));
                expected_byte := (others => 'U');
                check_equal(status_flags, expected_byte);
                check_equal(register_value, std_logic_vector'(x"77"));
                check_equal(z_reg_value, std_logic_vector'(x"7777"));
            elsif run("write_and_read_register") then
                new_value <= x"1111";
                first_reg <= "00001";
                write_new_value(0) <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);

                check_equal(first_reg_value, std_logic_vector'(x"1177"));
            elsif run("write_and_read_register_pair") then
                new_value <= x"1111";
                first_reg <= "00010";
                write_new_value(1) <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);

                check_equal(first_reg_value, std_logic_vector'(x"1111"));
            elsif run("read_z_register_output") then
                new_value <= x"1234";
                first_reg <= "11110";
                write_new_value(1) <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);

                check_equal(z_reg_value, std_logic_vector'(x"1234"));
            elsif run("read_two_register_pairs_simultaneously") then
                /* Write two registers pairs and read them back */
                new_value <= x"1111";
                first_reg <= "00010";
                write_new_value(1) <= '1';
                wait until rising_edge(clk);
                new_value <= x"2222";
                first_reg <= "00100";
                wait until rising_edge(clk);
                first_reg <= "00010";
                second_reg <= "0010";
                wait until falling_edge(clk);

                check_equal(first_reg_value, std_logic_vector'(x"1111"));
                check_equal(second_reg_value, std_logic_vector'(x"2222"));
            elsif run("write_and_read_register_as_io_memory") then
                new_value <= x"1111";
                write_memory <= '1';
                immediate <= x"0001";
                addressing_mode <= MODE_ABSOLUTE;
                wait until rising_edge(clk);
                wait until falling_edge(clk);

                check_equal(register_value, std_logic_vector'(x"11"));
            elsif run("read_memory_with_stack_pointer_addressing") then
                report "TODO";
                new_value <= x"0001";
                write_memory <= '1';
                immediate <= x"005D"; -- stack pointer low byte address
                addressing_mode <= MODE_ABSOLUTE;
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                write_memory <= '0';
                addressing_mode <= MODE_SP_ADD_1;
                wait until rising_edge(clk);
                wait until falling_edge(clk);

                check_equal(register_value, std_logic_vector'(x"01"));
            elsif run("address_source_x_post_increment") then
                new_value <= x"1100";
                first_reg <= "11010"; -- X register address.
                write_new_value(1) <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                write_new_value(1) <= '0';
                write_xyzs <= '1'; -- X incremented as a side effect.
                addressing_mode <= MODE_X_POST_INC;
                wait until rising_edge(clk);
                wait until falling_edge(clk);

                check_equal(first_reg_value, std_logic_vector'(x"1101"));
            elsif run("address_source_y_pre_decrement") then
                new_value <= x"1100";
                first_reg <= "11100"; -- Y register address.
                write_new_value(1) <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                write_new_value(1) <= '0';
                write_xyzs <= '1'; -- Y decrement as a side effect.
                addressing_mode <= MODE_Y_PRE_DEC;
                wait until rising_edge(clk);
                wait until falling_edge(clk);

                check_equal(first_reg_value, std_logic_vector'(x"10FF"));
            elsif run("address_source_z_add_immediate_value") then
                report "TODO";
                new_value <= x"1100";
                first_reg <= "11110"; -- Z register address.
                write_new_value(1) <= '1';
                wait until rising_edge(clk);
                wait until falling_edge(clk);
                write_new_value(1) <= '0';
                write_xyzs <= '1'; -- Value added to Z as a side effect.
                immediate <= x"0003"; -- Immediate value to be added to Z.
                addressing_mode <= MODE_Z_ADD_VAL;
                wait until rising_edge(clk);
                wait until falling_edge(clk);

                check_equal(first_reg_value, std_logic_vector'(x"1103"));
            end if;
        end loop;
        test_runner_cleanup(runner);
    end process;

end architecture;
