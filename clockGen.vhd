library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity clockGen is
port(
    clock : in std_logic;                       -- 125 MHz clock   
    adcSDA : in signed(7 downto 0);             -- this is input from SDA of ADC converter
    aInput : in std_logic_vector(1 downto 0); -- this is input from top fsm for clock gen mode
    clockGeneration : in std_logic;             -- this is input to determine if clock generation is being used
    pulse : out std_logic;                      -- pulse for frequency
    leds : out std_logic_vector(2 downto 0)     -- controls led1
    );
    
end clockGen;

architecture Behavioral of clockGen is
signal clk_en : std_logic := '0';
signal countTo : INTEGER range 0 to 249999;
signal count : integer range 0 to 249999;
--signal aInput : std_logic_vector(1 downto 0);
signal adcSDAsignal : integer range 0 to 255;

begin

    P0: process(clock)
        begin 
            if rising_edge(clock) then
                adcSDAsignal <= to_integer(signed(adcSDA));
                countTo <= (249999 - (654 * adcSDAsignal));
            end if;
        end process;

    P1: process(clock)
    	begin
			if rising_edge(clock) then
			    if(count > (2*countTo))then
			         count <= 0;
				elsif(count < countTo and clockGeneration = '1') then
					pulse <= '1';
				else
					pulse <= '0';
					
				end if; 
				count <= count + 1;
			end if;
	    end process;
	
--	P2: process(clock, clk_en)
--    begin
--        if(rising_edge(clock)) then
--            if(clockGeneration = '1' and clk_en = '1') then -- if clock gen is turned on and counter has reached max value
--                pulse <= '1';
--            else
--                pulse <= '0';
--            end if;
--        end if;	
--    end process;
    
    P3: process(clock)
        begin 
            if rising_edge(clock) then
                if(aInput = "00") then      --input from LDR
                    leds <= "001";          -- led[1] display red
                elsif(aInput = "01") then   -- input from TEMP
                    leds <= "010";          -- led[1] display green
                elsif(aInput = "10") then   -- input from OPAMP
                    leds <= "100";          -- led[1] display blue
                elsif(aInput = "11") then   -- input from POT
                    leds <= "111";            -- led[1] display white
                end if;
            end if;
        end process;
end Behavioral;
