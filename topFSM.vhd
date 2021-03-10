library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity topFSM is
	port (
		clock : in std_logic;
		button : in std_logic_vector(1 downto 0);
		mode : out std_logic_vector(1 downto 0);
		sig3 : out std_logic;
		clockGeneration : out std_logic
	);
end topFSM;

architecture behavior of topFSM is
type Sreg_type is (a0, a1, a2, a3, a0_clk, a1_clk, a2_clk, a3_clk);
signal Sreg: Sreg_type:=a0;

begin

process(clock)
	begin
		if(rising_edge(clock)) then
			case Sreg is
				when a0 => 
						mode <= "00";     -- LDR
						clockGeneration <= '0';
						--sig3 <= '0';
						if(button(1) = '1') then
							Sreg <= a1;
						else
							Sreg <= a0;
						end if;
						   
				when a1 => 
						mode <= "01";     -- TEMP
						clockGeneration <= '0';
						--sig3 <= '0';
						if(button(1) = '1') then
							Sreg <= a2;
						else
							Sreg <= a1;
						end if;
				when a2 => 
						mode <= "10";     -- OPAMP
						clockGeneration <= '0';
						--sig3 <= '0';
						if(button(1) = '1') then
							Sreg <= a3;
						else
							Sreg <= a2;
						end if;
				when a3 => 
						mode <= "11";     -- POT
						clockGeneration <= '0';
						--sig3 <= '0';
						if(button(1) = '1') then
							Sreg <= a0_clk;
						else
							Sreg <= a3;
						end if;	
				when a0_clk => 
						mode <= "00";     -- LDR w/clk
						clockGeneration <= '1';
						--sig3 <= '1';
						if(button(1) = '1') then
							Sreg <= a1_clk;
						else
							Sreg <= a0_clk;
						end if;
						   
				when a1_clk => 
						mode <= "01";     --TEMP w/clk
						clockGeneration <= '1';
						--sig3 <= '1';
						if(button(1) = '1') then
							Sreg <= a2_clk;
						else
							Sreg <= a1_clk;
						end if;
				when a2_clk => 
						mode <= "10";     -- OPAMP w/clk
						clockGeneration <= '1';
						--sig3 <= '1';
						if(button(1) = '1') then
							Sreg <= a3_clk;
						else
							Sreg <= a2_clk;
						end if;
				when a3_clk => 
						mode <= "11";     -- POT w/clk
						clockGeneration <= '1';
						--sig3 <= '1';
						if(button(1) = '1') then
							Sreg <= a0;
						else
							Sreg <= a3_clk;
						end if;						
			end case;
		end if;	
	end process;
end behavior;
