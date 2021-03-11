library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_adc is
	Generic (slave_addr : std_logic_vector(6 downto 0) := "1110010");
	PORT(
        clk         : in std_logic;
        config      : in std_logic_vector(7 downto 0);
        SDA, SCL    : inout std_logic;
        data_rd     : out std_logic_vector(7 downto 0);
        dataready   : out std_logic
	);
end i2c_adc;

architecture behavioral of i2c_adc is

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

type state_type is (initial,write,read);
signal state : state_type := initial;
signal count : integer := 0;
signal maxcount : integer := 3000;
signal i2c_datawr : std_logic_vector(7 downto 0);
signal reset_n : std_logic;
signal i2c_en : std_logic;
signal i2c_addr : std_logic_vector(6 downto 0);
signal i2c_rw : std_logic;
signal busy, busyprev : std_logic;
signal SDAbuf, SCLbuf : std_logic;
signal data_rdbuf : std_logic_vector(7 downto 0);
signal ackbuf : std_logic;
signal configprev : std_logic_vector(7 downto 0);
signal byteSel : integer := 0;
signal MaxByte : integer := 9;
begin	

i2c_addr <= "1001000";

output: i2c_master
port map(
	clk=>clk,
	reset_n=>reset_n,
	ena=>i2c_en,
	addr=>i2c_addr,
	rw=>i2c_rw,
	data_wr=>i2c_datawr,
	busy=>busy,
	data_rd=>data_rdbuf,
	ack_error=>ackbuf,
	sda=>SDAbuf,
	scl=>SCLbuf
);

ChangeState: process(byteSel,clk)
	begin	
		case byteSel is
			when 0  => i2c_datawr <= X"76";
			when 1  => i2c_datawr <= X"76";
			when 2  => i2c_datawr <= X"76";
			when 3  => i2c_datawr <= X"7A";
			when 4  => i2c_datawr <= X"FF";
			when 5  => i2c_datawr <= X"77";
			when 6  => i2c_datawr <= X"00";
			when 7  => i2c_datawr <= X"79";
			when 8  => i2c_datawr <= X"00";
			when 9  => i2c_datawr <= config;
			when others => i2c_datawr <= X"76";
		end case;

end process;

process(clk, byteSel)
begin
    if rising_edge(clk) then
        configprev <= config;
        busyprev <= busy;
    end if;
	if(clk'EVENT AND clk = '1')then
		CASE state is
		when initial =>
			if count /= maxcount THEN
				count <= count-1;
				reset_n <= '0';
				state <= initial;
				i2c_en <= '0';
			else
			    count <= 0;	
				reset_n <= '1';
				i2c_en <= '1';
				i2c_rw <= '0';
				i2c_datawr <= config;
				state <= write;
			END IF;

		when write =>
            if busy = '0' and busyprev = '1' then
                i2c_rw <= '1';
                if byteSel /= Maxbyte then
                    byteSel <= byteSel + 1;
                else
                    byteSel <= 9;
                end if;
                state <= read;
                
            end if;
            
	
		when read =>
            if configprev = config then
                dataready <= '0';
                if busy = '0' and busyprev = '1' then
                    data_rd <= data_rdbuf;
                    dataready <= '1';
                end if;
            else
                state <= initial;
            end if;

    	end case;
	end if;
	
	SDA <= SDAbuf;
	SCL <= SCLbuf;
	data_rd <= data_rdbuf;
end process;
			
end behavioral;
