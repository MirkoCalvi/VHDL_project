library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.env.stop;

entity cleverRst_tb is
end entity;

architecture cleverRst_tb_arch of cleverRst_tb is
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

    constant t_zero_int : integer := 131;
    constant t_zero : std_logic_vector(8 downto 0) := std_logic_vector(to_unsigned(t_zero_int,9));
    constant t_zero_value : std_logic_vector(7 downto 0) := "10110110";

    constant t_one_int : integer := 1314;
    constant t_one : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(t_one_int,11));
    constant t_one_value : std_logic_vector(7 downto 0) := "10001110";

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

    type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
    signal ram : ram_type := ( t_zero_int => t_zero_value,
                                t_one_int => t_one_value,
                                others => (others => '0')
                            );

begin
    i_clk <= not i_clk after 100 ns;

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
    
    mem : process (i_clk)  -- Process related to the memory
    begin
        if i_clk'event and i_clk = '1' then
            if mem_en = '1' then
                mem_data <= ram(conv_integer(mem_addr)) after 2 ns; 
            end if;
        end if;
    end process;

    z_out_done : process (z0, z1, z2, z3)  -- Checking if output is shown with done down
    begin
        if z0/=s_zero8 or z1/=s_zero8 or z2/=s_zero8 or z3/=s_zero8 then
            if done = '0' then
                report "Wrong z output with done down" severity failure; 
            end if;
        end if;
    end process;

    mem_we_down : process (mem_we)  -- we must be down at all times
    begin
        if mem_we = '1' then
            report "Wrong control signal o_mem_we, must be down at all times" severity failure;
        end if;
    end process;

    test : process
    begin
        rst <= '1';  -- Initial reset
        start <= '0';
        w <= '0';
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert mem_en = '0' report "Wrong control signal o_mem_en after reset" severity failure;
        assert mem_we = '0' report "Wrong control signal o_mem_we after reset" severity failure;
        assert done = '0' report "Wrong control signal done after reset" severity failure;
        assert mem_addr = s_zero16 report "Writing on o_mem_addr, better be sure it's intended" severity warning;

        start <= '1';
        ---  We'll be resetting while reading first two bits
        rst <= '0';
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Done should be down while reading w" severity failure;

        wait for wait_time;
        rst <= '1';  -- Resetting while reading first two bits
        wait for wait_time;
        assert mem_en = '0' report "Wrong control signal o_mem_en after reset" severity failure;
        assert done = '0' report "Wrong control signal done after reset" severity failure;
        assert mem_addr = s_zero16 report "Writing on o_mem_addr, better be sure it's intended" severity warning;


        ---  Testing normal behaviour, we'll be resetting after done will go up
        rst <= '0';
        w <= '1';  -- We'll be selecting z3
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Done should be down while reading w" severity failure;
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Done should be down while reading w" severity failure;
        
        for i in t_zero'range loop
            w <= t_zero(i);
            wait until rising_edge(i_clk);
            wait for wait_time;
            assert done = '0' report "Done should be down while reading w" severity failure;
        end loop;

        start <= '0';
        wait until rising_edge(done);
        assert i_clk = '1' report "Done should transition from down to up at the beginning of the clock cicle" severity failure;
        assert z3 = t_zero_value report "o_z3 should contain the the data given by the memory" severity failure;
        assert z0=s_zero8 and z1=s_zero8 and z2=s_zero8 report "Wrong z output, others should be zero" severity failure;

        wait until falling_edge(i_clk);

        rst <= '1';  -- Resetting immediately after done went up
        start <= '1';
        wait for wait_time;        
        assert mem_en = '0' report "Wrong control signal o_mem_en after reset" severity failure;
        assert done = '0' report "Wrong control signal done after reset" severity failure;
        assert mem_addr = s_zero16 report "Writing on o_mem_addr, better be sure it's intended" severity warning;

        ---  We'll be resetting while reading N bits
        rst <= '0';
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Done should be down while reading w" severity failure;
        w <= '0';
        wait until rising_edge(i_clk);
        assert done = '0' report "Done should be down while reading w" severity failure;
        wait until rising_edge(i_clk);
        assert done = '0' report "Done should be down while reading w" severity failure;
        wait until rising_edge(i_clk);
        assert done = '0' report "Done should be down while reading w" severity failure;

        wait for wait_time;
        rst <= '1';  -- Resetting while reading N bits
        wait for wait_time;
        assert mem_en = '0' report "Wrong control signal o_mem_en after reset" severity failure;
        assert done = '0' report "Wrong control signal done after reset" severity failure;
        assert mem_addr = s_zero16 report "Writing on o_mem_addr, better be sure it's intended" severity warning;

        ---  Testing normal behaviour
        rst <= '0';
        w <= '1';  -- We'll be selecting z2
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Done should be down while reading w" severity failure;
        w <= '0';
        wait until rising_edge(i_clk);
        wait for wait_time;
        assert done = '0' report "Done should be down while reading w" severity failure;
        
        for i in t_one'range loop
            w <= t_one(i);
            wait until rising_edge(i_clk);
            wait for wait_time;
            assert done = '0' report "Done should be down while reading w" severity failure;
        end loop;

        start <= '0';
        wait until rising_edge(done);
        assert i_clk = '1' report "Done should transition from down to up at the beginning of the clock cicle" severity failure;
        assert z2 = t_one_value report "o_z2 should contain the the data given by the memory" severity failure;
        assert z0=s_zero8 and z1=s_zero8 and z3=s_zero8 report "Wrong z output, others should be zero" severity failure;


        report "Test completed";
        stop;
    end process;

end cleverRst_tb_arch;