LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE std.textio.ALL;

ENTITY limit_2_18 IS
END limit_2_18;

ARCHITECTURE limit_2_18_arch OF limit_2_18 IS

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

	--M: con gli scenari stabilisci ad ogni cico di clk i valori delle entrate ( vedi process createScenario)*********************************************************
	
    CONSTANT SCENARIOLENGTH : INTEGER := 47; --5+2+20+18+2         (RST) + (MEM[0]on Z2)   + 20 CYCLES     +     (MEM[6]on z4)      + TheEnd
    SIGNAL scenario_rst : unsigned(0 TO SCENARIOLENGTH - 1)     := "00110" & "00" & "00000000000000000000" & "000000000000000000" & "00";
    SIGNAL scenario_start : unsigned(0 TO SCENARIOLENGTH - 1)   := "00000" & "11" & "00000000000000000000" & "111111111111111111" & "00";
    SIGNAL scenario_w : unsigned(0 TO SCENARIOLENGTH - 1)       := "00000" & "10" & "00000000000000000000" & "110000000000000110" & "00";
  

	--M: assegno ad ogni entrata(mem_address) un'uscita (mem_o_data) **************************************************************************************************
    TYPE ram_type IS ARRAY (65535 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL RAM : ram_type := (  0 => STD_LOGIC_VECTOR(to_unsigned(2, 8)),   --MEM[0]
                                1 => STD_LOGIC_VECTOR(to_unsigned(162, 8)), --MEM[1]
                                2 => STD_LOGIC_VECTOR(to_unsigned(75, 8)),  --MEM[2]
                                3 => STD_LOGIC_VECTOR(to_unsigned(175, 8)), --MEM[3]
								4 => STD_LOGIC_VECTOR(to_unsigned(110, 8)), --MEM[4]
								5 => STD_LOGIC_VECTOR(to_unsigned(21, 8)),  --MEM[5]
                                6 => STD_LOGIC_VECTOR(to_unsigned(88, 8)),  --MEM[6]
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
	--M: non importante, scrive su mem_o_data i risultati della ram corrispondenti a mem_address )*********************************************************
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
            scenario_rst <= scenario_rst(1 TO SCENARIOLENGTH - 1) & '0'; --M: shifto a sx gli scenari così da poter sempre prendere scenario(0) al nuovo ciclo di clk *********************************************************
            scenario_w <= scenario_w(1 TO SCENARIOLENGTH - 1) & '0';
            scenario_start <= scenario_start(1 TO SCENARIOLENGTH - 1) & '0';
        END IF;
    END PROCESS;

    -- Process without sensitivity list designed to test the actual component.
    testRoutine : PROCESS IS
    BEGIN
	
		--M: inizializzo e verifico che tutte le uscite siano nulle ******************************************************************************************************************
        mem_i_data <= "00000000";
        -- wait for 10000 ns;
        WAIT UNTIL tb_rst = '1';
        WAIT UNTIL tb_rst = '0';
        ASSERT tb_done = '0' REPORT "TEST FALLITO (postreset DONE != 0 )" SEVERITY failure;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postreset Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		 
		---------------------------- limit case 2 clock periods
		--M: guardando i miei scenari so che ho start=1 per due cicli di clk in cui w=[10] quindi l'uscita sarà su Z2 e poi tutto zero *********************************************************
		--   quindi l'address sarà [00...00] che in ram (vedi SIGNAL RAM) ha valore 2 mappato unsigned su 8 bit ********************************************************************************
		
		WAIT UNTIL tb_start = '1'; --verifico che quando start va a uno sia tutto a 0 (non lo faccio sempre, solo all'inizio)
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (poststart Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (poststart Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (poststart Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (poststart Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
       
  	    WAIT UNTIL tb_done = '1';
        WAIT FOR CLOCK_PERIOD/2;
		--M: verifico che Z2
        ASSERT tb_z2 = std_logic_vector(to_unsigned(2, 8))  REPORT "TEST FALLITO (Z2 ---) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; --. Expected  209  found " & integer'image(tb_z0))))  severity failure;
        WAIT UNTIL tb_done = '0';
        WAIT FOR CLOCK_PERIOD/2;
        ASSERT tb_z0 = "00000000" REPORT "TEST FALLITO (postdone Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z0))) severity failure; 
        ASSERT tb_z1 = "00000000" REPORT "TEST FALLITO (postdone Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z1))) severity failure; 
        ASSERT tb_z2 = "00000000" REPORT "TEST FALLITO (postdone Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; 
        ASSERT tb_z3 = "00000000" REPORT "TEST FALLITO (postdone Z0--Z3 != 0 ) found " & integer'image(to_integer(unsigned(tb_z3))) severity failure; 
        
		
		
		---------------------------- limit case 18 clock periods
		
		WAIT UNTIL tb_start = '1';--M: attendo il nuovo input, quindi start=1 ********************************************************************************************************************
        WAIT UNTIL tb_done = '1';--M: aspetto mi arrivi il valore in uscita sulle Z, per capire quando è arrivato faccio affidamento a tb_done=1**************************************************
		WAIT FOR CLOCK_PERIOD/2;
		
		--M: guardando i miei scenari so che ho start=1 per 20 cicli di clk in cui w1,2=[11] quindi l'uscita sarà su Z4, *********************************************************
		--   l'address sarà [000000000000000110] che in ram (vedi SIGNAL RAM) ha valore 88 mappato unsigned su 8 bit ********************************************************************************
		
        ASSERT tb_z2 = std_logic_vector(to_unsigned(2, 8))  REPORT "TEST FALLITO (Z2 ---) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; --. Expected  209  found " & integer'image(tb_z0))))  severity failure;
        ASSERT tb_z3 = std_logic_vector(to_unsigned(88, 8))  REPORT "TEST FALLITO (Z3 ---) found " & integer'image(to_integer(unsigned(tb_z2))) severity failure; --. Expected  209  found " & integer'image(tb_z0))))  severity failure;
		WAIT UNTIL tb_done = '0';
        WAIT FOR CLOCK_PERIOD/2;
        

        ASSERT false REPORT "Simulation Ended! TEST PASSATO (EXAMPLE)" SEVERITY failure;
		
    END PROCESS testRoutine;

END limit_2_18_arch;
