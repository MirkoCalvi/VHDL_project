LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY limit_reset IS
END limit_reset;

ARCHITECTURE limit_reset_arch OF limit_reset IS

    CONSTANT CLOCK_PERIOD : TIME := 100 ns;
    SIGNAL tb_done : STD_LOGIC;
    SIGNAL mem_address : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_rst : STD_LOGIC := '0';
    SIGNAL tb_start : STD_LOGIC := '0';
    SIGNAL tb_clk : STD_LOGIC := '0';
    SIGNAL mem_o_data, mem_i_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL enable_wire : STD_LOGIC;
    SIGNAL mem_we : STD_LOGIC;
    SIGNAL tb_z0, tb_z1, tb_z2, tb_z3 : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL tb_w : STD_LOGIC;
	
	--limit case with reset:
		--1) reset immediately after the first reset
		--2) reset during the reading of the first bit of the channel
		--3) reset during the reading of the second bit of the channel
		--4) reset while reading the address
		--5) reset after reading the address
		--6) reset while reading from the memory
		--7) reset after the data input from the memory
		--8) reset after o_done'event and o_done='0'
	
    CONSTANT SCENARIOLENGTH : INTEGER := 122;
	                                                             -- reset0 + reset1 + reset2 + MEM[1]onZ3 +      20 cycles         + reset3 +  MEM[3]onZ2 +      20 cycles         + reset4  +5 cycles + reset5 + MEM[10]onZ1 + reset6 + MEM[10]onZ1 + reset7  + MEM[10]onZ1 +         20 cycles      + reset8
    SIGNAL scenario_rst : unsigned(0 TO SCENARIOLENGTH - 1)     := "00110" & "00110" & "1"   &    "000"   & "00000000000000000000" & "0100" &    "0000"   & "00000000000000000000" & "00001" & "00000" &   "1"  &   "000000"  &  "01"  &   "000000"  &  "001"  &   "000000"  & "00000000000000000000" & "111000" ;                               
    SIGNAL scenario_start : unsigned(0 TO SCENARIOLENGTH - 1)   := "00000" & "00000" & "1"   &    "111"   & "00000000000000000000" & "1100" &    "1111"   & "00000000000000000000" & "11111" & "11111" &   "0"  &   "111110"  &  "00"  &   "111110"  &  "000"  &   "111110"  & "00000000000000000000" & "000000" ;
    SIGNAL scenario_w : unsigned(0 TO SCENARIOLENGTH - 1)       := "00000" & "00000" & "1"   &    "111"   & "00000000000000000000" & "0000" &    "1011"   & "00000000000000000000" & "10101" & "01101" &   "0"  &   "011010"  &  "00"  &   "011010"  &  "000"  &   "011010"  & "00000000000000000000" & "000000" ;
  

    TYPE ram_type IS ARRAY (65535 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL RAM : ram_type := (  0 => STD_LOGIC_VECTOR(to_unsigned(2, 8)),   --MEM[0]
                                1 => STD_LOGIC_VECTOR(to_unsigned(162, 8)), --MEM[1]
                                2 => STD_LOGIC_VECTOR(to_unsigned(75, 8)),  --MEM[2]
                                3 => STD_LOGIC_VECTOR(to_unsigned(175, 8)), --MEM[3]
								4 => STD_LOGIC_VECTOR(to_unsigned(110, 8)), --MEM[4]
								5 => STD_LOGIC_VECTOR(to_unsigned(21, 8)),  --MEM[5]
                                6 => STD_LOGIC_VECTOR(to_unsigned(88, 8)),  --MEM[6]
								10 => STD_LOGIC_VECTOR(to_unsigned(10, 8)),  --MEM[10]
                                OTHERS => "00000000"-- (OTHERS => '0')
                            );
                    
    COMPONENT project_reti_logiche IS
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst : IN STD_LOGIC;
            i_start : IN STD_LOGIC;
            i_w : IN STD_LOGIC;

            o_z0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_z3 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_done : OUT STD_LOGIC;

            o_mem_addr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_mem_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_mem_we : OUT STD_LOGIC;
            o_mem_en : OUT STD_LOGIC
        );
    END COMPONENT project_reti_logiche;

BEGIN
    UUT : project_reti_logiche
    PORT MAP(
        i_clk => tb_clk,
        i_start => tb_start,
        i_rst => tb_rst,
        i_w => tb_w,

        o_z0 => tb_z0,
        o_z1 => tb_z1,
        o_z2 => tb_z2,
        o_z3 => tb_z3,
        o_done => tb_done,

        o_mem_addr => mem_address,
        o_mem_en => enable_wire,
        o_mem_we => mem_we,
        i_mem_data => mem_o_data
    );


    -- Process for the clock generation
    CLK_GEN : PROCESS IS
    BEGIN
        WAIT FOR CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    END PROCESS CLK_GEN;


    -- Process related to the memory 
    MEM : PROCESS (tb_clk)
    BEGIN
        IF tb_clk'event AND tb_clk = '1' THEN
            IF enable_wire = '1' THEN
                IF mem_we = '1' THEN
                    RAM(conv_integer(mem_address)) <= mem_i_data;
                    mem_o_data <= mem_i_data AFTER 1 ns;
                ELSE
                    mem_o_data <= RAM(conv_integer(mem_address)) AFTER 1 ns; 
                END IF;
                ASSERT (mem_we = '1' OR mem_we = '0') REPORT "o_mem_we in an unexpected state" SEVERITY failure;
            END IF;
            ASSERT (enable_wire = '1' OR enable_wire = '0') REPORT "o_mem_en in an unexpected state" SEVERITY failure;
        END IF;
    END PROCESS;
    
    -- This process provides the correct scenario on the signal controlled by the TB
    createScenario : PROCESS (tb_clk)
    BEGIN
        IF tb_clk'event AND tb_clk = '0' THEN
            tb_rst <= scenario_rst(0);
            tb_w <= scenario_w(0);
            tb_start <= scenario_start(0);
            scenario_rst <= scenario_rst(1 TO SCENARIOLENGTH - 1) & '0'; 
            scenario_w <= scenario_w(1 TO SCENARIOLENGTH - 1) & '0';
            scenario_start <= scenario_start(1 TO SCENARIOLENGTH - 1) & '0';
        END IF;
    END PROCESS;

    -- Process without sensitivity list designed to test the actual component.
    testRoutine : PROCESS IS
    BEGIN
	
        mem_i_data <= "00000000";
        -- wait for 10000 ns;
        WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		
		----------------------------1) reset immediately after the first reset
		WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		
		----------------------------2) reset during the reading of the first bit of the channel
		WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
		ASSERT mem_address = ( others => '0' );
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		
		----------------------------3) reset during the reading of the second bit of the channel
		WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
		ASSERT mem_address = ( others => '0' );
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		
		----------------------------4) reset while reading the address
		WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
		ASSERT mem_address = ( others => '0' ) REPORT "TEST FALLITO (postreset mem_address != 0 )" SEVERITY failure;
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		
		------------------------------5) reset after reading the address
		WAIT UNTIL tb_start='1';
		WAIT UNTIL tb_start='0';
		ASSERT mem_address = "0000000000000101" REPORT "TEST FALLITO (wrong mem_address  )" SEVERITY failure;
		
		WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
		WAIT FOR CLOCK_PERIOD/2;
		ASSERT mem_address = ( others => '0' ) REPORT "TEST FALLITO (postreset mem_address != 0 )" SEVERITY failure;
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		----------------------------6) reset while reading from the memory
		WAIT UNTIL tb_start='1';
		WAIT UNTIL tb_start='0';
		ASSERT mem_address = "0000000000001010" REPORT "TEST FALLITO (wrong mem_address  )" SEVERITY failure;
		
		WAIT UNTIL enable_wire='1';
		WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
		WAIT FOR CLOCK_PERIOD/2;
		ASSERT mem_address = ( others => '0' ) REPORT "TEST FALLITO (postreset mem_address != 0 )" SEVERITY failure;
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		
		----------------------------7) reset after the data input from the memory
		WAIT UNTIL tb_start='1';
		WAIT UNTIL tb_start='0';
		ASSERT mem_address = "0000000000001010" REPORT "TEST FALLITO (wrong mem_address  )" SEVERITY failure;
		
		WAIT UNTIL enable_wire='1';
		WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
		WAIT FOR CLOCK_PERIOD/2;
		ASSERT mem_address = ( others => '0' ) REPORT "TEST FALLITO (postreset mem_address != 0 )" SEVERITY failure;
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		
		----------------------------8) reset after o_done='0'
		WAIT UNTIL tb_start='1';
		WAIT UNTIL tb_start='0';
		ASSERT mem_address = "0000000000001010" REPORT "TEST FALLITO (wrong mem_address  )" SEVERITY failure;
		
		WAIT UNTIL tb_done = '1';
		--M: verifico che Z2
        ASSERT tb_z2 = std_logic_vector(to_unsigned(2, 8))  REPORT "TEST FALLITO (Z2 ---) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; --. Expected  209  found " & integer'image(tb_z0))))  severity failure;
        WAIT UNTIL tb_done = '0';
		
		WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
        WAIT FOR CLOCK_PERIOD/2;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postdone Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postdone Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postdone Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postdone Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        

        ASSERT false REPORT "Simulation Ended! TEST PASSATO " SEVERITY failure;
		
    END PROCESS testRoutine;

END limit_reset_arch;