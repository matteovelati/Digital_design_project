----------------------------------------------------------------------------------
-- Engineer: VELATI MATTEO (10489761 - 844365)
--           ZANGRANDO NICCOLO' (10464648 - 848997)
-- Create Date: 24.08.2018 15:32:22
-- Design Name: 
-- Module Name: 10489761 - Behavioral
-- Project Name: 10489761
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR (7 downto 0);
           o_address : out STD_LOGIC_VECTOR (15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR (7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type STATE is (RST, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, FINAL);
    signal status: STATE;
    signal colonna, riga, soglia, tmp_data, cat, rat: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal c_max, c_min, r_max, r_min: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal area_max, area: STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal contatore: STD_LOGIC_VECTOR (15 downto 0) := "0000000000000100";
    signal flag: STD_LOGIC := '0';
    signal tmp_col, tmp_rig: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin


lambda: process (i_clk)                               
begin
    if (i_rst = '1') then
        status <= RST;
    else if (i_clk = '0' and i_clk'event) then
        case status is
            when RST =>                   -- INIZIALIZZO VALORI
                cat <= "00000000";
                rat <= "00000000";
                c_max <= "00000000";
                c_min <= "00000000";
                r_max <= "00000000";
                r_min <= "00000000";
                tmp_col <= "00000000";
                tmp_rig <= "00000000";
                contatore <= "0000000000000100";
                flag <='0';
                if (i_start = '1') then
                    status <= S0;
                else
                    status <= RST;
                end if;
                
            when S0 =>                      --CHIEDO VALORE COLONNA
                o_en <= '1';
                o_we <= '0';
                o_address <= "0000000000000010";
                status <= S1;
    
            when S1 =>                      --CHIEDO VALORE RIGA - LETTURA VALORE COLONNA
                o_address <= "0000000000000011";
                colonna <= i_data;
                status <= S2;
    
            when S2 =>                      --CHIEDO VALORE SOGLIA - LETTURA VALORE RIGA
                o_address <= "0000000000000100";
                riga <= i_data;
                status <= S3;
    
            when S3 =>                      --CALCOLO AREAMAX - LETTURA VALORE SOGLIA
                area_max <= STD_LOGIC_VECTOR(unsigned(riga)*unsigned(colonna));
                soglia <= i_data;
                status <= S4;
    
            when S4 =>                      --INCREMENTO CONTATORE 
                contatore <= STD_LOGIC_VECTOR(unsigned(contatore)+1);
                status <= S5;    
                
            when S5 =>                     --VERIRICA FINE LETTURA
                if (unsigned(contatore)-4 > unsigned(area_max)) then
                    status <= S10;
                else
                    status <= S6;
                end if;
            
            when S6 =>                      --CHIEDO VALORE PIXEL
                o_address <= STD_LOGIC_VECTOR(unsigned(contatore));
                status <= S7;
                
            when S7 =>                      --CONTROLLO FINE RIGA - LETTURA PIXEL
                if (tmp_col = colonna) then                            
                    tmp_col <= "00000000";
                    tmp_rig <= rat;
                end if;           
                tmp_data <= i_data;
                status <= S8;
                
            when S8 =>                     --CONTROLLO INIZIO RIGA
                if (tmp_col = "00000000") then
                    rat <= STD_LOGIC_VECTOR(unsigned(tmp_rig)+1);
                end if;
                cat <= tmp_col;
                status <= S9;
    
            when S9 =>                      --CONTROLLO VALORE PIXEL E AGGIORNO PARAMETRI PER CALCOLO DELL'AREA
                if (tmp_data >= soglia) then     
                    if (flag = '0') then
                        r_min <= rat;
                        r_max <= rat; 
                        c_min <= cat; 
                        c_max <= cat; 
                        flag <= '1';
                    else
                        if (rat > r_max) then
                            r_max <= rat;
                        end if;
                        if (cat < c_min) then
                            c_min <= cat;
                        end if;
                        if (cat > c_max) then
                            c_max <= cat;
                        end if;
                    end if;
                end if;
                tmp_rig <= tmp_col;                    
                tmp_col <= STD_LOGIC_VECTOR(unsigned(tmp_col)+1);
                status <= S4;
    
            when S10 =>                      --CALCOLO AREA
                if (flag = '0') then
                    area <= "0000000000000000";
                else
                    area <= STD_LOGIC_VECTOR((unsigned(c_max)-unsigned(c_min)+1)*(unsigned(r_max)-unsigned(r_min)+1));
                end if;
                status <= S11;
    
            when S11 =>                      --SCRIVO AREA bit meno significativi
                o_we <= '1';
                o_address <= "0000000000000000";
                o_data <= area (7 downto 0);
                status <= S12;
                
            when S12 =>                      --SCRIVO AREA bit più significativi
                o_address <= "0000000000000001";
                o_data <= area (15 downto 8);
                o_done <= '1';
                status <= FINAL;
                
            when FINAL =>                    --RESET O_DONE
                o_we <= '0';
                o_done <= '0';
    
    end case;
    end if;
    end if;
    
end process;


end Behavioral;
