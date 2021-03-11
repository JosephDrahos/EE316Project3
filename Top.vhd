library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity Top is
	port (
		clock : in std_logic;
		button : in std_logic_vector(1 downto 0);
		
		--sig3 : out std_logic;
		
		--i2c
		SCL : inout std_logic;
        SDA : inout std_logic;
		i2c_adc_SDA : inout std_logic;
		i2c_adc_SCL : inout std_logic;
		
		--pwm 
		pwm_out : out std_logic;
		
		--clock gen
		clock_out : out std_logic;
		leds : out std_logic_vector(2 downto 0);
		clocktest : out std_logic;
		
		--lcd
		lcdSCL : inout std_logic;
		lcdSDA : inout std_logic
	);
end Top;

architecture behavior of Top is
    component pwmgenerator is
    port(
        clk : in std_logic;
        reset : in std_logic;
        data_in : in std_logic_vector(7 downto 0);
        
        pwm_out : out std_logic

    );
    end component pwmgenerator;

    component clockGen is
    port(
        clock : in std_logic;                       -- 125 MHz clock   
        adcSDA : in signed(7 downto 0);             -- this is input from SDA of ADC converter
        aInput : in std_logic_vector(1 downto 0);   -- this is input from top fsm for clock gen mode
        clockGeneration : in std_logic;             -- this is input to determine if clock generation is being used
        pulse : out std_logic;                      -- pulse for frequency
        leds : out std_logic_vector(2 downto 0)     -- controls led1
        );
        
    end component clockGen;

    component i2c_adc_logic is
	PORT(
	    clock         : in std_logic;
	    dataIn      : in std_logic_vector(7 downto 0);
        outSCL      : inout std_logic;
        outSDA    : inout std_logic;
        busy 			: out std_logic
	);
    end component i2c_adc_logic;

    component debounce is
	 port(
		I_CLK 			  : in std_logic;
		I_RESET_N        : in std_logic;  -- System reset (active low)
		I_BUTTON         : in std_logic;  -- Button data to be debounced
		O_BUTTON         : out std_logic  -- Debounced button data
	 );
    end component debounce;
  
    component lcd_ctrl is
	port(
		mode : in std_logic_vector(1 downto 0);  
		clockGen : in std_logic;  
		clock			: in std_logic;
		outSCL			: inout std_logic;
		outSDA			: inout std_logic

	    );
    end component lcd_ctrl;

    component i2c_adc is
	PORT(
        clk         : in std_logic;
        config      : in std_logic_vector(7 downto 0);
        in_address  : in std_logic_vector(6 downto 0);
        SDA, SCL    : inout std_logic;
        data_rd     : out std_logic_vector(7 downto 0);
        dataready   : out std_logic
	);
    end component i2c_adc;

    component ila_0 is
    port(
        clk : in std_logic;
        probe0 : in std_logic_vector(7 downto 0);
        probe1 : in std_logic
    );
    end component ila_0;
    
type Sreg_type is (a0, a1, a2, a3, a0_clk, a1_clk, a2_clk, a3_clk);
signal Sreg: Sreg_type :=a0;
signal mode : std_logic_vector(1 downto 0) := "00";

signal reset : std_logic;
signal clock_data : std_logic_vector(7 downto 0) := "11111111";
signal clockGeneration : std_logic;
signal tempclock : std_logic;
signal clockdata2 :integer := 250000;
signal clockcount : integer := 0;
signal clocktestsignal : std_logic := '1';
--pwm

--i2c
signal i2c_data : std_logic_vector(7 downto 0);
signal i2c_ready : std_logic;
signal i2c_config :std_logic_vector(7 downto 0);
signal i2c_address : std_logic_vector(6 downto 0);
signal i2c_rw      : std_logic;
signal i2c_busy     :std_logic;
signal prevbusy : std_logic;
signal sinecount : unsigned(7 downto 0) := (others => '0');
signal i2c_adc_data : std_logic_vector(7 downto 0);

--ila
signal mode_ila : std_logic_vector(7 downto 0);
signal button_deb : std_logic;

signal buttons_debounce : std_logic_vector(1 downto 0);

type mem_t is array (0 to 255) of std_logic_vector(15 downto 0);
signal sine_wave : mem_t := (x"80", x"83", x"86", x"89", x"8C", x"90", x"93", x"96",
 x"99", x"9C", x"9F", x"A2", x"A5", x"A8", x"AB", x"AE",
 x"B1", x"B3", x"B6", x"B9", x"BC", x"BF", x"C1", x"C4",
 x"C7", x"C9", x"CC", x"CE", x"D1", x"D3", x"D5", x"D8",
 x"DA", x"DC", x"DE", x"E0", x"E2", x"E4", x"E6", x"E8",
 x"EA", x"EB", x"ED", x"EF", x"F0", x"F1", x"F3", x"F4",
 x"F5", x"F6", x"F8", x"F9", x"FA", x"FA", x"FB", x"FC", 
 x"FD", x"FD", x"FE", x"FE", x"FE", x"FF", x"FF", x"FF",
 x"FF", x"FF", x"FF", x"FF", x"FE", x"FE", x"FE", x"FD",
 x"FD", x"FC", x"FB", x"FA", x"FA", x"F9", x"F8", x"F6",
 x"F5", x"F4", x"F3", x"F1", x"F0", x"EF", x"ED", x"EB",
 x"EA", x"E8", x"E6", x"E4", x"E2", x"E0", x"DE", x"DC",
 x"DA", x"D8", x"D5", x"D3", x"D1", x"CE", x"CC", x"C9",
 x"C7", x"C4", x"C1", x"BF", x"BC", x"B9", x"B6", x"B3",
 x"B1", x"AE", x"AB", x"A8", x"A5", x"A2", x"9F", x"9C",
 x"99", x"96", x"93", x"90", x"8C", x"89", x"86", x"83",
 x"80", x"7D", x"7A", x"77", x"74", x"70", x"6D", x"6A",
 x"67", x"64", x"61", x"5E", x"5B", x"58", x"55", x"52",
 x"4F", x"4D", x"4A", x"47", x"44", x"41", x"3F", x"3C",
 x"39", x"37", x"34", x"32", x"2F", x"2D", x"2B", x"28",
 x"26", x"24", x"22", x"20", x"1E", x"1C", x"1A", x"18",
 x"16", x"15", x"13", x"11", x"10", x"0F", x"0D", x"0C",
 x"0B", x"0A", x"08", x"07", x"06", x"06", x"05", x"04",
 x"03", x"03", x"02", x"02", x"02", x"01", x"01", x"01",
 x"01", x"01", x"01", x"01", x"02", x"02", x"02", x"03",
 x"03", x"04", x"05", x"06", x"06", x"07", x"08", x"0A",
 x"0B", x"0C", x"0D", x"0F", x"10", x"11", x"13", x"15",
 x"16", x"18", x"1A", x"1C", x"1E", x"20", x"22", x"24",
 x"26", x"28", x"2B", x"2D", x"2F", x"32", x"34", x"37",
 x"39", x"3C", x"3F", x"41", x"44", x"47", x"4A", x"4D",
 x"4F", x"52", x"55", x"58", x"5B", x"5E", x"61", x"64",
 x"67", x"6A", x"6D", x"70", x"74", x"77", x"7A", x"7D");

begin

button_debounce: for i in 0 to 1 generate
	debounce_button: debounce
		port map
		(
			I_CLK 	=> clock,
			I_RESET_N => reset,
			I_BUTTON  => button(i),
			O_BUTTON  => buttons_debounce(i)
		);
	end generate button_debounce;
	
    
    pwm : pwmgenerator
    port map(
        clk => clock,
        reset => reset,
        data_in => std_logic_vector(sinecount),
        pwm_out => pwm_out
    );
    
    clockGenerator : clockGen
    port map(
        clock => clock,
        adcSDA => signed(clock_data),   
        aInput => mode,
        clockGeneration => clockGeneration,
        pulse => clocktest,
        leds => leds
    );

    --dac
    i2c : i2c_adc_logic
    port map(
        clock => clock,
        dataIn => i2c_data,
        outSDA => SDA, 
        outSCL => SCL,
        busy => i2c_busy
    );
    
    lcd : lcd_ctrl
    port map(
        mode => mode,  
		clockGen => clockGeneration,
		clock	=> clock,
		outSCL	=> lcdSCL,
		outSDA	=> lcdSDA
    );
    
    --adc
    adc : i2c_adc
    PORT map(
        clk  => clock,
        config    => i2c_config,
        in_address  => i2c_address,
        SDA       => i2c_adc_SDA,
        SCL       => i2c_adc_SCL,
        data_rd   => i2c_adc_data,
        dataready   => i2c_ready
	);
    
    ila_1 : ila_0
    port map(
        clk => clock,
        probe0 => i2c_data,
        probe1 => buttons_debounce(0)
    );


process(clock)
    begin 
        if(rising_edge(clock))then
            --if(i2c_busy = '0' and prevbusy ='1')then
                i2c_data <= std_logic_vector(sinecount);
                sinecount <= "01111111";
            --end if;
            
            prevbusy <= i2c_busy;
            
--            clocktest <= clocktestsignal;
--            if(clockcount = 25000)then
--                clockcount <= 0;
--            else
--                if(clockcount = 12500 and clockGeneration = '1')then
--                    clocktestsignal <= not clocktestsignal;
--                end if;
--            end if;
--            clockcount <= clockcount + 1;
--            clock_out <= clocktestsignal;
        end if;
end process;

process(clock)
	begin
	   
		if(rising_edge(clock)) then
		    if(buttons_debounce(0) = '1') then
                Sreg <= a0;
                mode <= "00";
                reset <= '1';
            else
                reset <= '0';
                case Sreg is
				when a0 => 
						mode <= "00";     -- LDR
						clockGeneration <= '0';
						i2c_rw <= '1';
						i2c_address <= "1001001";
						i2c_config <= "00000000";
						if(buttons_debounce(1) = '1') then
							Sreg <= a1;
						else
							Sreg <= a0;
						end if;
						   
				when a1 => 
						mode <= "01";     -- TEMP
						clockGeneration <= '0';
						i2c_rw <= '1';
						i2c_address <= "1001010";
						i2c_config <= "00000001";
						if(buttons_debounce(1) = '1') then
							Sreg <= a2;
						else
							Sreg <= a1;
						end if;
				when a2 => 
						mode <= "10";     -- OPAMP
						clockGeneration <= '0';
						i2c_rw <= '1';
						i2c_address <= "1001100";
						i2c_config <= "00000010";
						if(buttons_debounce(1) = '1') then
							Sreg <= a3;
						else
							Sreg <= a2;
						end if;
				when a3 => 
						mode <= "11";     -- POT
						clockGeneration <= '0';
						i2c_rw <= '1';
						i2c_address <= "1001000";
						i2c_config <= "00000011";
						if(buttons_debounce(1) = '1') then
							Sreg <= a0_clk;
						else
							Sreg <= a3;
						end if;	
				when a0_clk => 
						mode <= "00";     -- LDR w/clk
						clockGeneration <= '1';
						i2c_rw <= '1';
						i2c_address <= "1001001";
						i2c_config <= "00000000";
						
						if(buttons_debounce(1) = '1') then
							Sreg <= a1_clk;
						else
							Sreg <= a0_clk;
						end if;
						   
				when a1_clk => 
						mode <= "01";     --TEMP w/clk
						clockGeneration <= '1';
						i2c_rw <= '1';
						i2c_address <= "1001010";
						i2c_config <= "00000001";
						
						if(buttons_debounce(1) = '1') then
							Sreg <= a2_clk;
						else
							Sreg <= a1_clk;
						end if;
				when a2_clk => 
						mode <= "10";     -- OPAMP w/clk
						clockGeneration <= '1';
						i2c_rw <= '1';
						i2c_address <= "1001100";
						i2c_config <= "00000010";
						
						if(buttons_debounce(1) = '1') then
							Sreg <= a3_clk;
						else
							Sreg <= a2_clk;
						end if;
				when a3_clk => 
						mode <= "11";     -- POT w/clk
						clockGeneration <= '1';
						i2c_rw <= '1';
						i2c_address <= "1001000";
						i2c_config <= "00000011";
						if(buttons_debounce(1) = '1') then
							Sreg <= a0;
						else
							Sreg <= a3_clk;
						end if;						
			 end case;
            end if;
			
			mode_ila <= "000000"&mode;
		end if;	
	end process;
end behavior;
