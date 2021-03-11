library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity i2c_dac_logic is
	Generic (slave_addr : std_logic_vector(6 downto 0) := "1001000");
	PORT(
			clock			: in std_logic;
			dataIn			: in std_logic_vector(7 downto 0);
--			byteSel		: inout integer := 0;
--			data_wr		: out std_logic_vector(7 downto 0);
			outSCL			: inout std_logic;
			outSDA			: inout std_logic;
--			en				: in std_logic;
			busy 			: out std_logic
	);
end i2c_dac_logic;

architecture behavioral of i2c_dac_logic is

component i2c_master is
  GENERIC(
    input_clk : INTEGER := 100_000_000; --input clock speed from user logic in Hz
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
END component i2c_master;

signal busyReg, busySig, reset, enable, r_w, ackSig : std_logic;
signal regData	: std_logic_vector(7 downto 0);
signal dataOut	: std_logic_vector(7 downto 0);
signal byteSel	: integer := 0;
signal MaxByte : integer := 9;
type state_type is (start,write_data,repeat);
signal state : state_type := start;
signal address : std_logic_vector(6 downto 0);
signal Cont 	: integer := 16383;


begin	

output: i2c_master
port map(
	clk=>clock,
	reset_n=>reset,
	ena=>enable,
	addr=>address,
	rw=>r_w,
	data_wr=>dataOut,
	busy=>busySig,
	data_rd=>OPEN,
	ack_error=>ackSig,
	sda=>outSDA,
	scl=>outSCL
);

ChangeState: process(byteSel,clock)
	begin	
		case byteSel is
			when 0  => dataOut <= X"76";
			when 1  => dataOut <= X"76";
			when 2  => dataOut <= X"76";
			when 3  => dataOut <= X"7A";
			when 4  => dataOut <= X"FF";
			when 5  => dataOut <= X"77";
			when 6  => dataOut <= X"00";
			when 7  => dataOut <= X"79";
			when 8  => dataOut <= X"00";
			when 9  => dataOut <= dataIn;
			when others => dataOut <= X"76";
		end case;

end process;


process(clock)
begin
	if(clock'EVENT AND clock = '1')then
		CASE state is
		when start =>
			if cont /= X"00000"THEN
				cont <= cont-1;
				reset <= '0';
				state <= start;
				enable <= '0';
			ELSE	
				reset <= '1';
				enable <= '1';
				address <= slave_addr;
				r_w <= '0';
				dataOut <= dataOut;
				state <= write_data;
			END IF;
		when write_data =>
		busyReg<=busySig;
		regData<=dataIn;
		if busySig = '0' and busySig/=busyReg then
			if byteSel /= MaxByte then
				byteSel<=byteSel+1;
				state<=write_data;
			else
				byteSel<= 9;
				state<=repeat;
			end if;
		end if;
		
		when repeat=>
		enable<='0';
		if regData/=dataIn then
			state<=start;
		else
			state<=repeat;
		end if;
	end case;
	end if;
end process;
			
end behavioral;
