library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity pkt_length_counter is
	port(
		counter_clk: in std_logic;
		counter_rst: in std_logic;
		counter_rx_ctrl: in std_logic;	-- receives control signal to count
		counter_data_in: in std_logic_vector(7 downto 0);	-- input data received as bytes
		pkt_length: out integer range 0 to 1550;	-- length of packet in integer
		pkt_length_vector: out std_logic_vector(10 downto 0) -- length of packet in std_logic_vector
	);

end pkt_length_counter;


architecture behavioural of pkt_length_counter is

	signal counter: integer range 0 to 1550;	-- to counts the packet length

begin

	-- Process to implement counter
	process (counter_clk, counter_rst, counter_data_in, counter_rx_ctrl)
		begin
			if(counter_rst = '1') then
				counter <= 0;
			elsif (rising_edge(counter_clk)) then
				if (counter_rx_ctrl = '1') then
					counter <= counter + 1;
				else
					counter <= 0;
				end if;
			end if;
	end process;
	
	-- Delaying by a clock cycle to fetch the final count (length)
	-- and store in pkt_length_fifo
	process(counter_clk)
		begin
			if(rising_edge(counter_clk)) then
				pkt_length <= counter;
				pkt_length_vector <= std_logic_vector(to_unsigned(counter, pkt_length_vector'length));
			end if;
	end process;
	

end behavioural;