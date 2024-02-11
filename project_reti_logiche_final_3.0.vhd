library ieee;
use ieee.std_logic_1164.all;

--RICORDA
--1)tutte le variabili che utilizzo in un circuito combinatorio devono comparire nella sensivity list, ex:a<=b+1 , b deve comparire
--2)il valore delle uscite deve essere settato qualunque sia il percorso e l'utilizzo che ne faccio

--MODIFICHE e COMMENTI: da leggere con sotto la versione del codice prima di questa
--ho reinserito READ_N0 e READ_N1 ma con l'approccio no-process
-- print : process
--non sono d'accordo sul tuo commento in delta ASK_MEM, i canali non sono bidirezionali 
--in UPDATE_ZI non c'è il rischio di latch?
--in UPDATE_ZI va utilizzato reg_data_mem non i_mem_addr
--ho tolto reg_n: std_logic_vector(1 downto 0); OSS nel tuo codice credo tu abbia confuso read_n con reg_n
--non c'è reset di o_mem_addr prima dell'inserimento del nuovo indirizzo

--MOLTO IMPORTANTE
--''Contemporaneamente alla scrittura del messaggio sul canale, il segnale DONE passa da 0 passa a 1 ''
--CONTEMPORANEAMENTE!!!!! quindi ho aggregato UPDATE_ZI e PRINT_NEW in un unico stato UPDATE_AND_PRINT


entity project_reti_logiche is                   --************************ = insicurezza/dubbio
	port ( 
	
	    reg_n1: out  std_logic_vector(1 downto 0);
		i_clk : in std_logic; 
		i_rst : in std_logic; 
		i_start : in std_logic; 
		i_w : in std_logic; 
		
		o_z0 : out std_logic_vector(7 downto 0);-- := (OTHERS => '0'); 
		o_z1 : out std_logic_vector(7 downto 0);-- := (OTHERS => '0'); 
		o_z2 : out std_logic_vector(7 downto 0);-- := (OTHERS => '0'); 
		o_z3 : out std_logic_vector(7 downto 0);-- := (OTHERS => '0'); 
		o_done : out std_logic := '0'; 
		
		o_mem_addr : out std_logic_vector(15 downto 0);--:= (OTHERS => '0'); 
		i_mem_data : in std_logic_vector(7 downto 0); 
		o_mem_we : out std_logic := '0'; 
		o_mem_en : out std_logic := '0'
		); 		
end project_reti_logiche;


architecture arch of project_reti_logiche is

    ----------------------NON FSM----------------------
    signal reg_mem_addr : std_logic_vector(15 downto 0):= (OTHERS => '0'); 
	signal reg_data_mem : std_logic_vector(7 downto 0);
	
	
	signal reg_n:  std_logic_vector(1 downto 0):= "00";
	
	signal reg_z0: std_logic_vector(7 downto 0);
    signal reg_z1: std_logic_vector(7 downto 0);
    signal reg_z2: std_logic_vector(7 downto 0);
    signal reg_z3: std_logic_vector(7 downto 0);
	
	
	----------------------FSM----------------------
	
	type STATUS is ( WAIT_START, READ_N1, READ_N0, READ_ADDR, ASK_MEM, UPDATE_AND_PRINT);
	signal PresState : STATUS;
	
	-----input fsm signals
	signal ok_data : std_logic;
	
	-----output fsm signals										  
	signal set_done : std_logic;
	--signal o_mem_we : std_logic; già in entity
	--signal o_mem_en : std_logic; già in entity
	signal calc_addr : std_logic;
	signal reg_mem_en : std_logic;
	

begin
	
	-----------------------ARCHITETTURA CALCOLO INDIRIZZO DI MEMORIA-------------------
	--è uno shifter, fine, tutto lì
	mem_addr_calc : process( i_clk, i_start, reg_mem_addr, calc_addr) --i_w	
    begin
    
    --reg_mem_addr<= reg_n(1) & reg_n(0) & "00000000000000"; --DeBug
    
    if i_clk'event and i_clk = '1' then
        if calc_addr='0' and i_start = '1' then --OSS:  i_start, vorrei che ogni volta che parte una nuova lettura o_mem_addr resettasse
            --o_mem_addr <= "0000000000000000";
            reg_mem_addr <= "0000000000000000";
            --ok_data <= '0';
            --set_done <= '0';
            --calc_addr <= '0';
            --o_mem_we <= '0';
            --o_mem_en <= '0';
    
         elsif calc_addr='1' and i_start = '1' then
            --reg_mem_addr <= "1111000000000001"; DeBug
            reg_mem_addr(0) <= i_w;           
            reg_mem_addr(1) <= reg_mem_addr(0);
            reg_mem_addr(2) <= reg_mem_addr(1);
            reg_mem_addr(3) <= reg_mem_addr(2);
            reg_mem_addr(4) <= reg_mem_addr(3);
            reg_mem_addr(5) <= reg_mem_addr(4);
            reg_mem_addr(6) <= reg_mem_addr(5);
            reg_mem_addr(7) <= reg_mem_addr(6);
            reg_mem_addr(8) <= reg_mem_addr(7);
            reg_mem_addr(9) <= reg_mem_addr(8);
            reg_mem_addr(10) <= reg_mem_addr(9);
            reg_mem_addr(11) <= reg_mem_addr(10);
            reg_mem_addr(12) <= reg_mem_addr(11);
            reg_mem_addr(13) <= reg_mem_addr(12);
            reg_mem_addr(14) <= reg_mem_addr(13);
            reg_mem_addr(15) <= reg_mem_addr(14);
            
         end if;
        ----------------------------------------------------------------------------------------------------------
    end if;   
    end process;


	-----------------------ARCHITETTURA REGISTRO DATI MEMORIA-----------------------
	--i_mem_data'event è il fattore scatenante, però, metti caso che mi cambia durante l'esecuzione di altri stati, non mi piace sta cosa
	--per ovviare al problema quindi osservo o_mem_en così da capire se sono o meno in comunicazione con la memoria (o_mem_en è gestito dalla fsm)
	
	get_data_mem : process(reg_n, i_mem_data, reg_mem_en, reg_mem_addr) --IMP: ho tolto reg_mem_en dalla sens list 
	begin
	    reg_n1<=reg_n;
	    o_mem_addr <= reg_mem_addr ;
	    
	    if i_mem_data'event then
	        --o_mem_addr <= reg_mem_addr;
            --if reg_mem_en'event and reg_mem_en='1' then
                reg_data_mem <= i_mem_data;
                --o_mem_addr <= i_mem_data & "00000000" ;-- DeBug
                ok_data <= '1';--feedback di completamento della lettura da memoria
            --end if;
        end if;
		--------OSS: il caso in cui i_mem_data non cambia potrebbe dare bug
	end process;
	
	
	-----------------------ARCHITETTURA OUTPUT-----------------------
	
	update_and_print_Z: process(i_clk, ok_data, reg_data_mem, reg_z0, reg_z1, reg_z2, reg_z3, i_rst)
	begin
	     --o_mem_addr <= i_mem_data & "00000000";
                   --o_done <= '1'; --DeBug
          if ok_data='1' and i_clk'event and i_clk = '1' and i_rst='0' then
                
                   case reg_n is
   
                       when "00" =>
                           o_z0 <= reg_data_mem;   
                           reg_z0 <= reg_data_mem;
                           
                           o_z1 <= reg_z1;
                           reg_z1 <= reg_z1;
                           
                           o_z2 <= reg_z2;
                           reg_z2 <= reg_z2;
                           
                           o_z3 <= reg_z3;
                           reg_z3 <= reg_z3;
                           
                           o_done <= '1';
   
                       when "01" =>
                           o_z0 <= reg_z0;
                           o_z1 <= reg_data_mem;
                           reg_z1 <= reg_data_mem;
                           o_z2 <= reg_z2;
                           o_z3 <= reg_z3;
                           o_done <= '1';
   
                       when "10" =>
                           
                           o_z0 <=reg_z0;
                           o_z1 <= reg_z1;
                           o_z2 <= reg_data_mem;
                           reg_z2 <= reg_data_mem;
                           o_z3 <= reg_z3;
                           o_done <= '1';
   
                       when "11" => 
                           o_z0 <= reg_z0;
                           o_z1 <= reg_z1;
                           o_z2 <= reg_z2;
                           o_z3 <= reg_data_mem;
                           reg_z3 <= reg_data_mem;
                           o_done <= '1';
   
                       when others =>
                       
                   end case;
                   
               else
               
               o_z0 <= "00000000";
               o_z1 <= "00000000";
               o_z2 <= "00000000";
               o_z3 <= "00000000";
               o_done <= '0';
			
			--end if;	

		end if;
	end process;
	
	
	--------------------------------ARCHITETTURA RESET	--------------------------------
	
	rst_process : process(i_rst, i_clk)
	begin 
	   
	   if i_clk='1' and i_clk'event and i_rst='1' then
	   
	        reg_z0 <= "00000000";
            reg_z1 <= "00000000";
            reg_z2 <= "00000000";
            reg_z3 <= "00000000";
            o_done <= '0';
            
            --reg_n <= "00";
            
            --o_mem_we <= '0';
			--o_mem_en <= '0';
            --o_mem_addr <= "0000000000000000";
            --reg_mem_addr <= "0000000000000000";
			--ok_data <= '0';
            
	  
	   end if;
	
	end process;
	
	
	--------------------------------ARCHITETTURA FSM--------------------------------
	
	--delta_fsm: dallo stato presente, se si verificano le condizioni (in base all'input) genero lo stato successivo (nello stesso ciclo di clock)
	delta_fsm : process (i_clk, i_rst, ok_data )
	begin
        if i_rst = '1' then
            PresState <= WAIT_START;
        elsif i_clk'event and i_clk = '1' then
		
            case PresState is
			
                when WAIT_START => --passo in READ_N1 quando compare il primo i_start=1
                    if i_start='1' then
                        PresState <= READ_N1;
                        reg_n(1) <= i_w;
                    else 
                        PresState <= WAIT_START;
                    end if;
					
                when READ_N1 =>
                    reg_n(0) <= i_w; 
                    PresState <= READ_N0;
					
                when READ_N0 =>
                    PresState <= READ_ADDR;
					
                when READ_ADDR => --passo in ASK_MEM quando i_start passando a 0 mi dice che non mi sta più comunicando l'address
					if i_start = '0' then
                       PresState <= ASK_MEM;
                    else 
                        PresState <= READ_ADDR; 
                    end if;
					
				when ASK_MEM => --una volta che ho terminato di leggere i dati da memoria mi arriva ok_data
					if ok_data = '1' then --OSS: ho riaggiunto ok_data e ho tolto i_start= '0'
					   PresState <= UPDATE_AND_PRINT;
					   
					else 
					    PresState <= ASK_MEM;
					    
					end if;
					
				when UPDATE_AND_PRINT =>
		
					PresState <= WAIT_START; ---?
				
				when others => 
				
            end case;
        end if;
    end process;
	
	
	-- State and output registers
	state_output_fsm: process(PresState)
	
	begin
	
		--valori di default per tutte le uscite ***********************
		--set_done <= '0'; 
		--calc_addr <= '0';
	    --o_mem_we <= '0';
		--o_mem_en <= '0';
		
		case PresState is
		
			when WAIT_START =>
			    set_done <= '0';
				calc_addr <= '0';
				o_mem_we <= '0';
				o_mem_en <= '0';
			
			when READ_N1 =>
				--reg_n(1) <= i_w;
				
				set_done <= '0';
				calc_addr <= '0';
				o_mem_we <= '0';
				o_mem_en <= '0';
			
			when READ_N0 =>
				--reg_n(0) <= i_w;
				
				set_done <= '0';
				calc_addr <= '1';----RISCHIOOOOOOO
				o_mem_we <= '0';
				o_mem_en <= '0';
			
			when READ_ADDR =>
				calc_addr <= '1';
				
				set_done <= '1';
				o_mem_we <= '0';
				o_mem_en <= '0';
			
			when ASK_MEM =>
				o_mem_en <= '1';
				reg_mem_en <= '1'; 
				
				set_done <= '1';
				calc_addr <= '0';
				o_mem_we <= '0';
				
			
			when UPDATE_AND_PRINT =>
				set_done <= '1';

				calc_addr <= '0';
				o_mem_we <= '0';
				o_mem_en <= '0';
			    reg_mem_en <= '0';
			when others => 
				
		end case;
		
	end process;
	
end architecture;