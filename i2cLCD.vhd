library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_arith.ALL;
use ieee.std_logic_unsigned.all;

entity lcd_ctrl is
	port(
		mode : in std_logic_vector(1 downto 0);  
		clockGen : in std_logic;  
		clock			: in std_logic;
		outSCL			: inout std_logic;
		outSDA			: inout std_logic

	    );
end lcd_ctrl;

architecture behavioral of lcd_ctrl is

component i2c_masterLCD is
  GENERIC(
    input_clk : INTEGER := 125_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component i2c_masterLCD;

signal busyReg, busySig, reset, enable, r_w, ackSig : std_logic;
signal regData	: std_logic_vector(15 downto 0);
signal dataOut	: std_logic_vector(7 downto 0);
signal byteSel	: integer := 0;
signal MaxByte : integer; --:= 41;
type state_type is (start, write_data, count, repeat);
signal state : state_type := start;
signal address : std_logic_vector(6 downto 0);
signal Cont 	: integer := 1875000;--5000;
signal modeSignal : std_logic_vector(1 downto 0);
signal modeInitSig : std_logic;
signal enableClock : std_logic:= '0';

signal testCount : integer := 0;
signal lastState : std_logic_vector(2 downto 0);
signal lastClockState : std_logic;
signal checkCondition : std_logic;
begin	

output: i2c_masterLCD
port map(
	clk        =>clock,
	reset_n    =>reset,
	ena        =>enable,
	addr       =>address,
	rw         =>r_w,
	data_wr    =>dataOut,
	busy       =>busySig,
	data_rd    =>OPEN,
	ack_error  =>ackSig,
	sda        =>outSDA,
	scl        =>outSCL
);
process(clock)
begin
	if(clock'EVENT AND clock = '1')then
		busyReg<=busySig;
		modeSignal<=mode;	
	end if;
end process;	

process(clock)
begin
	if(clock'EVENT AND clock = '1')then
		CASE state is
		when start =>
			if cont /= 0 THEN --enableClock = '0' then --
				cont <= cont-1;
				reset <= '0';
				state <= start;
				enable <= '0';
			else	
				reset <= '1';
				enable <= '1';
				byteSel <= 0;
				address <= "0100111";
				r_w <= '0';
				state <= write_data;
				modeInitSig <= '0';
				lastState <= "111";
				lastClockState <= '0';
				checkCondition <= '0';
				MaxByte <= 41;
				
		    end if;
			
		when write_data =>
		if busySig = '0' and busyReg = '1' then
			if (byteSel /= MaxByte) then 
				byteSel<=byteSel+1;
			else 
				--byteSel<= MaxByte;
				if(mode = "00" and lastState /= "000" and clockGen = '0') then
				    lastState <= "000";
				    byteSel <= 42;
				    MaxByte <= 60;
				elsif(mode = "00" and lastState /= "000" and clockGen = '1') then
				    lastState <= "000";
				    byteSel <= 132;
				    MaxByte <= 168;
				elsif(mode = "01" and lastState /= "001" and clockGen = '0') then
				    lastState <= "001";
				    byteSel <= 60;
				    MaxByte <= 84;
				elsif(mode = "01" and lastState /= "001" and clockGen = '1') then
				    lastState <= "001";
				    byteSel <= 168;
				    MaxByte <= 210;
				elsif(mode <= "10" and lastState /= "010" and clockGen = '0') then
				    lastState <= "010";
				    byteSel <= 102;
				    MaxByte <= 132;
				elsif(mode <= "10" and lastState /= "010" and clockGen = '1') then
				    lastState <= "010";
				    byteSel <= 246;
				    MaxByte <= 294;
				elsif(mode <= "11" and lastState /= "011" and clockGen = '0') then
				    lastState <= "011";
				    byteSel <= 84;
				    MaxByte <= 102;
				elsif(mode <= "11" and lastState /= "011" and clockGen = '1') then
				    lastState <= "011";
				    byteSel <= 210;
				    MaxByte <= 246;				    

				end if;
--				state <= count;
--			    enable <= '0';
--			    cont <= 5000;
			end if;
			  state <= count;
			  enable <= '0';
			  cont <= 5000;
		end if;
		
		when count =>
			if cont /= 0 THEN 
				cont <= cont-1;	
			elsif (byteSel /= (MaxByte+1) and lastState = "111") then
				 state<=write_data;
				 enable <= '1';
			elsif(lastState = "000" and byteSel /= MaxByte) then
			    state<=write_data;
			    enable <= '1';
			elsif(lastState = "001" and byteSel /= MaxByte) then
			    state <= write_data;
			    enable <= '1';
			elsif(lastState<= "010" and byteSel /= MaxByte) then
			    state <= write_data;
	            enable <= '1';		        
		    elsif(lastState <= "011" and byteSel /= MaxByte) then
			    state <= write_data;
			    enable <= '1';
			else 
				 state<=repeat;
			end if;			
					  
		when repeat =>
		      enable<='0';
		  if modeSignal/=mode then
  		      state<=start;
		  end if;
		  
			  
	 end case;
	end if;
end process;


ChangeState: process(byteSel)
	begin	
		case byteSel is
		       -- INITIALIZATION --
			when 0  => dataOut <= X"38";
			when 1  => dataOut <= X"3C";
			when 2  => dataOut <= X"38";
			when 3  => dataOut <= X"38";
			when 4  => dataOut <= X"3C";
			when 5  => dataOut <= X"38";
			when 6  => dataOut <= X"38";
			when 7  => dataOut <= X"3C";
			when 8  => dataOut <= X"38";
			when 9  => dataOut <= X"28";
			when 10 => dataOut <= X"2C";
			when 11 => dataOut <= X"28";
			when 12  => dataOut <= X"28";
			when 13 => dataOut <= X"2C";
			when 14 => dataOut <= X"28";
			when 15  => dataOut <= X"C8";
			when 16  => dataOut <= X"CC";
			when 17  => dataOut <= X"C8";
			when 18  => dataOut <= X"08";
			when 19  => dataOut <= X"0C";
			when 20  => dataOut <= X"08";
			when 21  => dataOut <= X"88";
			when 22  => dataOut <= X"8C";
			when 23  => dataOut <= X"88";
			when 24  => dataOut <= X"08";
			when 25  => dataOut <= X"0C";
			when 26  => dataOut <= X"08";
			when 27  => dataOut <= X"18";
			when 28  => dataOut <= X"1C";
			when 29  => dataOut <= X"18";
			when 30  => dataOut <= X"08";
			when 31  => dataOut <= X"0C";
			when 32  => dataOut <= X"08";
			when 33  => dataOut <= X"38";
			when 34  => dataOut <= X"3C";
			when 35  => dataOut <= X"38";
			when 36  => dataOut <= X"08";
			when 37  => dataOut <= X"0C";
			when 38  => dataOut <= X"08";
			when 39  => dataOut <= X"F8";
			when 40  => dataOut <= X"FC";
			when 41  => dataOut <= X"F8";
			
			-- LDR --
			when 42  => dataOut <= X"49"; -- upper nibble L
			when 43  => dataOut <= X"4D";
			when 44  => dataOut <= X"49";
			when 45  => dataOut <= X"C9"; -- lower nibble L
			when 46  => dataOut <= X"CD";
			when 47  => dataOut <= X"C9";
			when 48  => dataOut <= X"49"; -- upper nibble D
			when 49  => dataOut <= X"4D";
			when 50  => dataOut <= X"49";
			when 51  => dataOut <= X"49"; -- lower nibble D
			when 52  => dataOut <= X"4D";
			when 53  => dataOut <= X"49";
			when 54  => dataOut <= X"59"; -- upper nibble R
			when 55  => dataOut <= X"5D";
			when 56  => dataOut <= X"59";
			when 57  => dataOut <= X"29"; -- lower nibble R
			when 58  => dataOut <= X"2D";
			when 59  => dataOut <= X"29";	
			
			-- TEMP --
			when 60  => dataOut <= X"59"; -- upper nibble T
			when 61  => dataOut <= X"5D";
			when 62  => dataOut <= X"59";
			when 63  => dataOut <= X"49"; -- lower nibble T
			when 64  => dataOut <= X"4D";
			when 65  => dataOut <= X"49";	
			when 66  => dataOut <= X"49"; -- upper nibble E
			when 67  => dataOut <= X"4D";
			when 68  => dataOut <= X"49";
			when 69  => dataOut <= X"59"; -- lower nibble E
			when 70  => dataOut <= X"5D";
			when 71  => dataOut <= X"59";	
			when 72  => dataOut <= X"49"; -- upper nibble M
			when 73  => dataOut <= X"4D";
			when 74  => dataOut <= X"49";
			when 75  => dataOut <= X"D9"; -- lower nibble M
			when 76  => dataOut <= X"DD";
			when 77  => dataOut <= X"D9";
			when 78  => dataOut <= X"59"; -- upper nibble P
			when 79  => dataOut <= X"5D";
			when 80  => dataOut <= X"59";
			when 81  => dataOut <= X"09"; -- lower nibble P
			when 82  => dataOut <= X"0D";
			when 83  => dataOut <= X"09";
			
			-- POT -- 
			when 84  => dataOut <= X"59"; -- upper nibble P
			when 85  => dataOut <= X"5D";
			when 86  => dataOut <= X"59";
			when 87  => dataOut <= X"09"; -- lower nibble P
			when 88  => dataOut <= X"0D";
			when 89  => dataOut <= X"09";
			when 90  => dataOut <= X"49"; -- upper nibble O
			when 91  => dataOut <= X"4D";
			when 92  => dataOut <= X"49";
			when 93  => dataOut <= X"F9"; -- lower nibble O
			when 94  => dataOut <= X"FD";
			when 95  => dataOut <= X"F9";
			when 96  => dataOut <= X"59"; -- upper nibble T
			when 97  => dataOut <= X"5D";
			when 98  => dataOut <= X"59";
			when 99  => dataOut <= X"49"; -- lower nibble T
			when 100  => dataOut <= X"4D";
			when 101  => dataOut <= X"49";	
			
			-- OPAMP --
			when 102  => dataOut <= X"49"; -- upper nibble O
			when 103  => dataOut <= X"4D";
			when 104  => dataOut <= X"49";
			when 105  => dataOut <= X"F9"; -- lower nibble O
			when 106  => dataOut <= X"FD";
			when 107  => dataOut <= X"F9";
			when 108  => dataOut <= X"59"; -- upper nibble P
			when 109  => dataOut <= X"5D";
			when 110  => dataOut <= X"59";
			when 111  => dataOut <= X"09"; -- lower nibble P
			when 112  => dataOut <= X"0D";
			when 113  => dataOut <= X"09";	
			when 114  => dataOut <= X"49"; -- upper nibble A
			when 115  => dataOut <= X"4D";
			when 116  => dataOut <= X"49";
			when 117  => dataOut <= X"19"; -- lower nibble A
			when 118  => dataOut <= X"1D";
			when 119  => dataOut <= X"19";
			when 120  => dataOut <= X"49"; -- upper nibble M
			when 121  => dataOut <= X"4D";
			when 122  => dataOut <= X"49";
			when 123  => dataOut <= X"D9"; -- lower nibble M
			when 124  => dataOut <= X"DD";
			when 125  => dataOut <= X"D9";
			when 126  => dataOut <= X"59"; -- upper nibble P
			when 127  => dataOut <= X"5D";
			when 128  => dataOut <= X"59";
			when 129  => dataOut <= X"09"; -- lower nibble P
			when 130  => dataOut <= X"0D";
			when 131  => dataOut <= X"09";
			
					-- LDR w/CG --
			when 132  => dataOut <= X"49"; -- upper nibble L
			when 133  => dataOut <= X"4D";
			when 134  => dataOut <= X"49";
			when 135  => dataOut <= X"C9"; -- lower nibble L
			when 136  => dataOut <= X"CD";
			when 137  => dataOut <= X"C9";
			when 138  => dataOut <= X"49"; -- upper nibble D
			when 139  => dataOut <= X"4D";
			when 140  => dataOut <= X"49";
			when 141  => dataOut <= X"49"; -- lower nibble D
			when 142  => dataOut <= X"4D";
			when 143  => dataOut <= X"49";
			when 144  => dataOut <= X"59"; -- upper nibble R
			when 145  => dataOut <= X"5D";
			when 146  => dataOut <= X"59";
			when 147  => dataOut <= X"29"; -- lower nibble R
			when 148  => dataOut <= X"2D";
			when 149  => dataOut <= X"29";
			when 150  => dataOut <= X"C8"; -- curser 2nd line
			when 151  => dataOut <= X"CC";
			when 152  => dataOut <= X"C8";
			when 153  => dataOut <= X"08"; -- curser 2nd line
			when 154  => dataOut <= X"0C";
			when 155  => dataOut <= X"08";
			when 156  => dataOut <= X"49"; -- upper nibble C
			when 157  => dataOut <= X"4D";
			when 158  => dataOut <= X"49";
			when 159  => dataOut <= X"39"; -- lower nibble C	
			when 160  => dataOut <= X"3D";
			when 161  => dataOut <= X"39";			
			when 162  => dataOut <= X"49"; -- upper nibble G
			when 163  => dataOut <= X"4D";
			when 164  => dataOut <= X"49";
			when 165  => dataOut <= X"79"; -- lower nibble G
			when 166  => dataOut <= X"7D";
			when 167  => dataOut <= X"79";
			
			-- TEMP w/cg--
			when 168  => dataOut <= X"59"; -- upper nibble T
			when 169  => dataOut <= X"5D";
			when 170  => dataOut <= X"59";
			when 171  => dataOut <= X"49"; -- lower nibble T
			when 172  => dataOut <= X"4D";
			when 173  => dataOut <= X"49";	
			when 174  => dataOut <= X"49"; -- upper nibble E
			when 175  => dataOut <= X"4D";
			when 176  => dataOut <= X"49";
			when 177  => dataOut <= X"59"; -- lower nibble E
			when 178  => dataOut <= X"5D";
			when 179  => dataOut <= X"59";	
			when 180  => dataOut <= X"49"; -- upper nibble M
			when 181  => dataOut <= X"4D";
			when 182  => dataOut <= X"49";
			when 183  => dataOut <= X"D9"; -- lower nibble M
			when 184  => dataOut <= X"DD";
			when 185  => dataOut <= X"D9";
			when 186  => dataOut <= X"59"; -- upper nibble P
			when 187  => dataOut <= X"5D";
			when 188  => dataOut <= X"59";
			when 189  => dataOut <= X"09"; -- lower nibble P
			when 190  => dataOut <= X"0D";
			when 191  => dataOut <= X"09";
			when 192  => dataOut <= X"C8"; -- curser 2nd line
			when 193  => dataOut <= X"CC";
			when 194  => dataOut <= X"C8";
			when 195  => dataOut <= X"08"; -- curser 2nd line
			when 196  => dataOut <= X"0C";
			when 197  => dataOut <= X"08";
			when 198  => dataOut <= X"49"; -- upper nibble C
			when 199  => dataOut <= X"4D";
			when 200  => dataOut <= X"49";
			when 201  => dataOut <= X"39"; -- lower nibble C	
			when 202  => dataOut <= X"3D";
			when 203  => dataOut <= X"39";			
			when 204  => dataOut <= X"49"; -- upper nibble G
			when 205  => dataOut <= X"4D";
			when 206  => dataOut <= X"49";
			when 207  => dataOut <= X"79"; -- lower nibble G
			when 208  => dataOut <= X"7D";
			when 209  => dataOut <= X"79";
			
			-- POT w/cg -- 
			when 210  => dataOut <= X"59"; -- upper nibble P
			when 211  => dataOut <= X"5D";
			when 212  => dataOut <= X"59";
			when 213  => dataOut <= X"09"; -- lower nibble P
			when 214  => dataOut <= X"0D";
			when 215  => dataOut <= X"09";
			when 216  => dataOut <= X"49"; -- upper nibble O
			when 217  => dataOut <= X"4D";
			when 218  => dataOut <= X"49";
			when 219  => dataOut <= X"F9"; -- lower nibble O
			when 220  => dataOut <= X"FD";
			when 221  => dataOut <= X"F9";
			when 222  => dataOut <= X"59"; -- upper nibble T
			when 223  => dataOut <= X"5D";
			when 224  => dataOut <= X"59";
			when 225 => dataOut <= X"49"; -- lower nibble T
			when 226  => dataOut <= X"4D";
			when 227  => dataOut <= X"49";
			when 228  => dataOut <= X"C8"; -- curser 2nd line
			when 229  => dataOut <= X"CC";
			when 230  => dataOut <= X"C8";
			when 231  => dataOut <= X"08"; -- curser 2nd line
			when 232  => dataOut <= X"0C";
			when 233  => dataOut <= X"08";
			when 234  => dataOut <= X"49"; -- upper nibble C
			when 235  => dataOut <= X"4D";
			when 236  => dataOut <= X"49";
			when 237  => dataOut <= X"39"; -- lower nibble C	
			when 238  => dataOut <= X"3D";
			when 239  => dataOut <= X"39";			
			when 240  => dataOut <= X"49"; -- upper nibble G
			when 241  => dataOut <= X"4D";
			when 242  => dataOut <= X"49";
			when 243  => dataOut <= X"79"; -- lower nibble G
			when 244  => dataOut <= X"7D";
			when 245  => dataOut <= X"79";
			
			-- OPAMP --
			when 246  => dataOut <= X"49"; -- upper nibble O
			when 247  => dataOut <= X"4D";
			when 248  => dataOut <= X"49";
			when 249  => dataOut <= X"F9"; -- lower nibble O
			when 250  => dataOut <= X"FD";
			when 251  => dataOut <= X"F9";
			when 252  => dataOut <= X"59"; -- upper nibble P
			when 253  => dataOut <= X"5D";
			when 254  => dataOut <= X"59";
			when 255  => dataOut <= X"09"; -- lower nibble P
			when 256  => dataOut <= X"0D";
			when 257  => dataOut <= X"09";	
			when 258  => dataOut <= X"49"; -- upper nibble A
			when 259  => dataOut <= X"4D";
			when 260  => dataOut <= X"49";
			when 261  => dataOut <= X"19"; -- lower nibble A
			when 262  => dataOut <= X"1D";
			when 263  => dataOut <= X"19";
			when 264  => dataOut <= X"49"; -- upper nibble M
			when 265  => dataOut <= X"4D";
			when 266  => dataOut <= X"49";
			when 267  => dataOut <= X"D9"; -- lower nibble M
			when 268  => dataOut <= X"DD";
			when 269  => dataOut <= X"D9";
			when 270  => dataOut <= X"59"; -- upper nibble P
			when 271  => dataOut <= X"5D";
			when 272  => dataOut <= X"59";
			when 273  => dataOut <= X"09"; -- lower nibble P
			when 274  => dataOut <= X"0D";
			when 275  => dataOut <= X"09";
			when 276  => dataOut <= X"C8"; -- curser 2nd line
			when 277  => dataOut <= X"CC";
			when 278  => dataOut <= X"C8";
			when 279  => dataOut <= X"08"; -- curser 2nd line
			when 280  => dataOut <= X"0C";
			when 281  => dataOut <= X"08";
			when 282  => dataOut <= X"49"; -- upper nibble C
			when 283  => dataOut <= X"4D";
			when 284  => dataOut <= X"49";
			when 285  => dataOut <= X"39"; -- lower nibble C	
			when 286  => dataOut <= X"3D";
			when 287  => dataOut <= X"39";			
			when 288  => dataOut <= X"49"; -- upper nibble G
			when 289  => dataOut <= X"4D";
			when 290  => dataOut <= X"49";
			when 291  => dataOut <= X"79"; -- lower nibble G
			when 292  => dataOut <= X"7D";
			when 293  => dataOut <= X"79";
			
			-- CLOCK GENERATION --
--			when 132  => dataOut <= X"C8"; -- curser 2nd line
--			when 133  => dataOut <= X"CC";
--			when 134  => dataOut <= X"C8";
--			when 135  => dataOut <= X"08"; -- curser 2nd line
--			when 136  => dataOut <= X"0C";
--			when 137  => dataOut <= X"08";
--			when 138  => dataOut <= X"49"; -- upper nibble C
--			when 139  => dataOut <= X"4D";
--			when 140  => dataOut <= X"49";
--			when 141  => dataOut <= X"39"; -- lower nibble C
--			when 142  => dataOut <= X"3D";
--			when 143  => dataOut <= X"39";
--			when 144  => dataOut <= X"49"; -- upper nibble L
--			when 145  => dataOut <= X"4D";
--			when 146  => dataOut <= X"49";
--			when 147  => dataOut <= X"C9"; -- lower nibble L
--			when 148  => dataOut <= X"CD";
--			when 149  => dataOut <= X"C9";
--			when 150  => dataOut <= X"49"; -- upper nibble O
--			when 151  => dataOut <= X"4D";
--			when 152  => dataOut <= X"49";
--			when 153  => dataOut <= X"F9"; -- lower nibble O
--			when 154  => dataOut <= X"FD";
--			when 155  => dataOut <= X"F9";
--			when 156  => dataOut <= X"49"; -- upper nibble C
--			when 157  => dataOut <= X"4D";
--			when 158  => dataOut <= X"49";
--			when 159  => dataOut <= X"39"; -- lower nibble C
--			when 160  => dataOut <= X"3D";
--			when 161  => dataOut <= X"39";
--			when 162  => dataOut <= X"49"; -- upper nibble K
--			when 163  => dataOut <= X"4D";
--			when 164  => dataOut <= X"49";
--			when 165  => dataOut <= X"B9"; -- lower nibble K
--			when 166  => dataOut <= X"BD";
--			when 167  => dataOut <= X"B9";
--			when 168  => dataOut <= X"29"; -- upper nibble space
--			when 169  => dataOut <= X"2D";
--			when 170  => dataOut <= X"29";
--			when 171  => dataOut <= X"09"; -- lower nibble space
--			when 172  => dataOut <= X"0D";
--			when 173  => dataOut <= X"09";
--			when 174  => dataOut <= X"49"; -- upper nibble G
--			when 175  => dataOut <= X"4D";
--			when 176  => dataOut <= X"49";
--			when 177  => dataOut <= X"79"; -- lower nibble G
--			when 178  => dataOut <= X"7D";
--			when 179  => dataOut <= X"79";
--			when 180  => dataOut <= X"49"; -- upper nibble E
--			when 181  => dataOut <= X"4D";
--			when 182  => dataOut <= X"49";
--			when 183  => dataOut <= X"59"; -- lower nibble E
--			when 184  => dataOut <= X"5D";
--			when 185  => dataOut <= X"59";
--			when 186  => dataOut <= X"49"; -- upper nibble N
--			when 187  => dataOut <= X"4D";
--			when 188  => dataOut <= X"49";
--			when 189  => dataOut <= X"E9"; -- lower nibble N
--			when 190  => dataOut <= X"ED";
--			when 191  => dataOut <= X"E9";
			when others => dataOut <= X"76";
		end case;

end process;
			
end behavioral;
