library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fcs_check_parallel is
	port (
	clk: in std_logic;
	reset: in std_logic;
	fcs_rx_ctrl: in std_logic;	-- Remains high as long as FCS receives packet
	start_of_frame: in std_logic;	-- Arrival of first byte
	data_in: in std_logic_vector(7 downto 0);
	fcs_error: out std_logic	-- Indicates an error in received data
	);
end fcs_check_parallel;

architecture behavioural of fcs_check_parallel is

	signal reg: std_logic_vector(31 downto 0) := (others => '0'); -- initializing registers to "0"
	signal shift_count: unsigned(1 downto 0);	-- takes 8 bits at once so there are only 32/8 = 4 counts
	signal data: std_logic_vector(7 downto 0);
	signal is_fcs_done: std_logic := '0';

begin
	-- Ethernet requirements:
	-- Complementing the first 32 bits of the frame either by
	-- waiting for the frame (start_of_frame is'1') or
	-- by executing appropriate number of register shifts.
	process (shift_count, start_of_frame, data_in)
		begin
			data <= data_in;
			if (shift_count < 3 or start_of_frame = '1') then
				data <= not data_in;
			end if;
	end process;
	
	-- Implementing 8-bit parallel LFSR. The XOR operations are derived
	-- from a matrix generated in matlab
	process (clk, reset)
		begin
			if reset = '1' then
				reg <= (others => '0');
				shift_count <= (others => '0');
				fcs_error <= '1';
				is_fcs_done <= '0';
			elsif rising_edge(clk) then
				if fcs_rx_ctrl = '1' then
					if start_of_frame = '1' then
						-- Resetting shift counter when SOF or EOF is '1' i.e. 
						-- when frame's first or last byte enters
						shift_count <= (others => '0');
						fcs_error <= '1';
					elsif shift_count < 3 then
						shift_count <= shift_count + 1;
					end if;
					
					-- XOR operations
					reg(0) <= reg(24) xor reg(30) xor data(0);
					reg(1) <= reg(24) xor reg(25) xor reg(30) xor reg(31) xor data(1);
					reg(2) <= reg(24) xor reg(25) xor reg(26) xor reg(30) xor reg(31) xor data(2);
					reg(3) <= reg(25) xor reg(26) xor reg(27) xor reg(31) xor data(3);
					reg(4) <= reg(24) xor reg(26) xor reg(27) xor reg(28) xor reg(30) xor data(4);
					reg(5) <= reg(24) xor reg(25) xor reg(27) xor reg(28) xor reg(29) xor reg(30) xor
							  reg(31) xor data(5);
					reg(6) <= reg(25) xor reg(26) xor reg(28) xor reg(29) xor reg(30) xor reg(31) xor
							  data(6);
					reg(7)  <= reg(24) xor reg(26) xor reg(27) xor reg(29) xor reg(31) xor data(7);
					reg(8)  <= reg(0) xor reg(24) xor reg(25) xor reg(27) xor reg(28);
					reg(9)  <= reg(1) xor reg(25) xor reg(26) xor reg(28) xor reg(29);
					reg(10) <= reg(2) xor reg(24) xor reg(26) xor reg(27) xor reg(29);
					reg(11) <= reg(3) xor reg(24) xor reg(25) xor reg(27) xor reg(28);
					reg(12) <= reg(4) xor reg(24) xor reg(25) xor reg(26) xor reg(28) xor reg(29) xor
								reg(30);
					reg(13) <= reg(5) xor reg(25) xor reg(26) xor reg(27) xor reg(29) xor reg(30) xor
								reg(31);
					reg(14) <= reg(6) xor reg(26) xor reg(27) xor reg(28) xor reg(30) xor reg(31);
					reg(15) <= reg(7) xor reg(27) xor reg(28) xor reg(29) xor reg(31);
					reg(16) <= reg(8) xor reg(24) xor reg(28) xor reg(29);
					reg(17) <= reg(9) xor reg(25) xor reg(29) xor reg(30);
					reg(18) <= reg(10) xor reg(26) xor reg(30) xor reg(31);
					reg(19) <= reg(11) xor reg(27) xor reg(31);
					reg(20) <= reg(12) xor reg(28);
					reg(21) <= reg(13) xor reg(29);
					reg(22) <= reg(14) xor reg(24);
					reg(23) <= reg(15) xor reg(24) xor reg(25) xor reg(30);
					reg(24) <= reg(16) xor reg(25) xor reg(26) xor reg(31);
					reg(25) <= reg(17) xor reg(26) xor reg(27);
					reg(26) <= reg(18) xor reg(24) xor reg(27) xor reg(28) xor reg(30);
					reg(27) <= reg(19) xor reg(25) xor reg(28) xor reg(29) xor reg(31);
					reg(28) <= reg(20) xor reg(26) xor reg(29) xor reg(30);
					reg(29) <= reg(21) xor reg(27) xor reg(30) xor reg(31);
					reg(30) <= reg(22) xor reg(28) xor reg(31);
					reg(31) <= reg(23) xor reg(29);
				
				elsif fcs_rx_ctrl = '0' and reg = "11111111111111111111111111111111" then
					-- Resetting registers for next error-free packet
					fcs_error <= '0';
					reg <= (others => '0');
				else
					-- Resetting registers when the current packet has errors
					reg <= (others => '0');
				end if;
			end if;
	end process;

end behavioural;