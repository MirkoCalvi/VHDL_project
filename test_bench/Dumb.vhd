library ieee;
use ieee.std_logic_1164.all;
use std.env.stop;

entity dumb_tb is
end entity;

architecture dumb_tb_arch of dumb_tb is
    component project_reti_logiche is
        port (
            i_clk : in std_logic;
            i_rst : in std_logic;
            i_start : in std_logic;
            i_w : in std_logic;
            o_z0 : out std_logic_vector(7 downto 0);
            o_z1 : out std_logic_vector(7 downto 0);
            o_z2 : out std_logic_vector(7 downto 0);
            o_z3 : out std_logic_vector(7 downto 0);
            o_done : out std_logic;
            o_mem_addr : out std_logic_vector(15 downto 0);
            i_mem_data : in std_logic_vector(7 downto 0);
            o_mem_we : out std_logic;
            o_mem_en : out std_logic
        );
    end component;

    constant wait_time : time := 2 ns;
    constant t_zero : std_logic_vector(7 downto 0) := "01101101";

    signal i_clk : std_logic := '1';
    signal rst : std_logic;
    signal w, start : std_logic;
    signal z0, z1, z2, z3 : std_logic_vector(7 downto 0);
    signal done : std_logic;
    signal mem_addr : std_logic_vector(15 downto 0);
    signal mem_data : std_logic_vector(7 downto 0);
    signal mem_we, mem_en : std_logic;

    signal s_zero8 : std_logic_vector(7 downto 0) := (others => '0');
    signal s_zero16 : std_logic_vector(15 downto 0) := (others => '0');

begin
    i_clk <= not i_clk after 10 ns;

    UnitUnderTest : project_reti_logiche
        port map(
            i_clk => i_clk,
            i_rst => rst,
            i_start => start,
            i_w => w,
            o_z0 => z0,
            o_z1 => z1,
            o_z2 => z2,
            o_z3 => z3,
            o_done => done,
            o_mem_addr => mem_addr,
            i_mem_data => mem_data,
            o_mem_we => mem_we,
            o_mem_en => mem_en
        );
    
    z_out_done : process (z0, z1, z2, z3)  -- Checking if output is shown with done down
    begin
        if z0/=s_zero8 or z1/=s_zero8 or z2/=s_zero8 or z3/=s_zero8 then
            if done = '0' then
                report "Wrong z output with done down" severity failure; 
            end if;
        end if;
    end process;

   mem_we_out : process (mem_we)  -- we must be down at all times
    begin
        if mem_we = '1' then
            report "Wrong control signal o_mem_we, must be down at all times" severity failure;
        end if;
    end process;

    test : process
    begin
        rst <= '1';
        start <= '0';
        w <= '1';
        mem_data <= (others => '0');
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert mem_en = '0' report "Wrong control signal o_mem_en after reset" severity failure;
        assert mem_we = '0' report "Wrong control signal o_mem_we after reset" severity failure;
        assert done = '0' report "Wrong control signal done after reset" severity failure;
        assert mem_addr = s_zero16 report "Writing on o_mem_addr, better be sure it's intended" severity warning;

        rst <= '0';
        w <= '0';
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert mem_addr = s_zero16 report "Writing on o_mem_addr, better be sure it's intended" severity warning;
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Wrong control signal done with start down" severity failure;
        assert mem_addr = s_zero16 report "Writing on o_mem_addr, better be sure it's intended" severity warning;

        wait until rising_edge(i_clk);
        assert done = '0' report "Wrong control signal done with start down" severity failure;
        wait until rising_edge(i_clk);
        assert done = '0' report "Wrong control signal done with start down" severity failure;
        wait until rising_edge(i_clk);
        assert done = '0' report "Wrong control signal done with start down" severity failure;
        wait for wait_time;

        -- Simulating output selection with N=0 bits following
        start <='1';
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Wrong control signal done with start down" severity failure;

        w <= '1';
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Wrong control signal done with start down" severity failure;
        start <= '0';
        
        wait until rising_edge(mem_en);
        assert mem_addr = s_zero16 report "Wrong output mem address, should be zero" severity failure;
        assert done = '0' report "Done should be down while waiting for memory" severity failure;
        wait until rising_edge(i_clk);  -- Memory will notice en is up on the next clock rise
        wait for 2 ns;  -- Simulating memory delay
        mem_data <= t_zero;

        wait until rising_edge(done);
        assert i_clk = '1' report "Done should transition from down to up at the beginning of the clock cicle" severity failure;
        assert z1 = t_zero report "o_z1 should contain the the data given by the memory" severity failure;
        assert z0=s_zero8 and z2=s_zero8 and z3=s_zero8 report "Wrong z output, others should be zero" severity failure;
        wait until rising_edge(i_clk);  -- Output visibile for at least one clock cicle
        assert done = '1' report "Done should be up for one clock cicle" severity failure;
        assert z1 = t_zero report "o_z1 should contain the the data given by the memory" severity failure;
        assert z0=s_zero8 and z2=s_zero8 and z3=s_zero8 report "Wrong z output, others should be zero" severity failure;

        wait for wait_time;  -- Output visible for no more than one clock cicle
        assert done = '0' report "Done should be down after one clock cicle" severity failure;
        assert z0=s_zero8 and z1=s_zero8 and z2=s_zero8 and z3=s_zero8 report "Wrong z output with done down" severity failure;

        report "Dumb test cases completed";
        stop;
    end process;
end dumb_tb_arch;