--------------------------------------------------------------------------------
-- Filename     : pwmgeneration.vhd
-- Author       : Joseph Drahos
-- Date Created : 2021-9-2
-- Project      : EE316 Project 3
-- Description  : PWM Generation Code
--------------------------------------------------------------------------------

-----------------
--  Libraries  --
-----------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity pwmgenerator is
  port(
    clk : in std_logic;
    reset : in std_logic;
    en    : in std_logic;
    data_in : in std_logic_vector(7 downto 0);

    pwm_out : out std_logic
  );
end pwmgenerator;


architecture archpwmgenerator  of  pwmgenerator is
  signal eightbitcounter: unsigned(7 downto 0) := (others => '0');
begin
  pwm : process (clk, reset)
    begin
      if(reset = '1')then
        counter <= (others => '0');
        eightbitcounter <= (others => '0');
      elsif(rising_edge(clk))then
         if(en = '1')then
             --pwm proportional to input data
             if(std_logic_vector(eightbitcounter) <= data_in)then
               pwm_out <= '1';
             else
               pwm_out <= '0';
             end if;

             eightbitcounter <= eightbitcounter + 1;
             counter <= counter + 1;
           end if;

         end if;
       end if;
  end process pwm;

end architecture;
