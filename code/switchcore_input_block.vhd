library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity switchcore_input_block is
	port(
		inp_block_rx_ctrl:	in std_logic;
		inp_block_data_in:	in std_logic_vector(7 downto 0);
		inp_block_clk: in std_logic;
		inp_block_rst: in std_logic;
		mac_ack: in std_logic; -- Acknowledge signal from MAC block
		mac_port: in std_logic_vector(3 downto 0);	-- Destination port to send data to obtained from MAC block
		address: out std_logic_vector(95 downto 0);	-- Sends src and dest mac address to MAC block
		inp_block_port_mac_in: in std_logic_vector(3 downto 0); -- Port corresponding to this FIFO 
		inp_block_port_mac_out: out std_logic_vector(3 downto 0);	-- FIFO port to be sent for MAC Learning
		mac_req: out std_logic;	-- Request sent to MAC Learning block from FIFO1
		-- fcs_error_check: out std_logic;
		-- start_of_frame: out std_logic;
		-- end_of_frame: out std_logic;
		inp_block_data_out:	out std_logic_vector(8 downto 0);	-- Data to be sent to output port
		inp_block_port_out:	out std_logic_vector(3 downto 0);	-- Destination port to send data to
		inp_block_pkt_length: out std_logic_vector(10 downto 0) -- Sends packet length to output block
		-- inp_block_pkt_length:	out integer range 0 to 1550 -- sends packet length to output block
	);
end switchcore_input_block;

architecture behavioural of switchcore_input_block is

	-- Performs FCS of every byte
	component fcs_check_parallel
		port(
			clk: in std_logic;
			reset: in std_logic;
			start_of_frame: in std_logic;	-- Arrival of first byte
			fcs_rx_ctrl: in std_logic;	-- Remains high as long as FCS receives packet
			data_in: in std_logic_vector(7 downto 0);
			fcs_error: out std_logic	-- Indicates an error in received data
		);
	end component;
	
	-- Input FIFO to store packet
	component sync_fifo
		port (
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			rdreq		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			empty		: OUT STD_LOGIC ;
			full		: OUT STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
		);
	end component;
	
	-- FIFO to store each packets length
	component pkt_length_fifo
		port(
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			rdreq		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			empty		: OUT STD_LOGIC ;
			full		: OUT STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
		);
	end component;
	
	-- Computes SOF and EOF for FCS
	component rxctrl_delay
		port(
			rx_ctrl_clk: in std_logic;
			rx_ctrl : in std_logic;
			start_of_frame: out std_logic;
			end_of_frame: out std_logic
		);
	end component;
	
	-- Counter to count the length of a packet
	component pkt_length_counter
		port(
			counter_clk: in std_logic;
			counter_rst: in std_logic;
			counter_rx_ctrl: in std_logic;
			counter_data_in: in std_logic_vector(7 downto 0);
			pkt_length: out integer range 0 to 1550;
			pkt_length_vector: out std_logic_vector(10 downto 0)
		);
	end component;
	
	-- Address FIFO
	component address_fifo_wrapper
		port (
			add_rx_ctrl: in std_logic;	-- high when switch receives packet
			add_clock: in std_logic;	-- clock for this block
			add_reset: in std_logic;	-- reset for this block
			add_req: in std_logic;		-- request signal to retreive SRC and DEST address
			add_data_in: in std_logic_vector(7 downto 0);	-- input data to store in address_fifo
			add_ack: out std_logic;		-- acknowledge signal when reading is complete
			-- add_data_out: out std_logic_vector(7 downto 0);
			src_address: out std_logic_vector(47 downto 0);	-- sends SRC address to MAC Learning block
			dest_address: out std_logic_vector(47 downto 0) -- sends DEST address to MAC Learning block
		);
	end component;
		
	-- Signals
	signal temp_mac_req: std_logic := '0';
	signal SOF: std_logic; 	-- SOF for data corresponding to each port
	signal EOF: std_logic;	-- EOF for data corresponding to each port
	signal temp_fcs_error_check: std_logic;	-- Decides whether to discard currently received packet or not
	signal r_en: std_logic;	-- Input packet FIFO read enable set in the state machine
	signal w_en: std_logic;	-- Input packet FIFO write enable set in the state machine
	signal fifo_full: std_logic;	-- FIFO full flag
	signal fifo_empty: std_logic; -- FIFO empty flag
	signal temp_dest_address: std_logic_vector(47 downto 0) := (others => '0');
	signal temp_src_address: std_logic_vector(47 downto 0) := (others => '0');
	signal address_counter: unsigned(4 downto 0); -- keeps r_en high until read_ptr in the fifo gets to src/dest add
	-- signal address_idx_counter: integer range 0 to 100;
	signal pkt_counter: std_logic_vector(10 downto 0);
	signal fifo_data: std_logic_vector(8 downto 0);	-- stores data from FIFO
	signal temp_packet_length1: integer range 0 to 1550;
	-- signal temp_packet_length2: integer range 0 to 1550;
	signal temp_packet_length_vector1: std_logic_vector(10 downto 0);
	signal temp_packet_length_vector2: std_logic_vector(11 downto 0) := (others => '0');
	signal temp_inp_block_data_in: std_logic_vector(7 downto 0);
	-- signal temp_inp_block_port_mac: std_logic_vector(3 downto 0) := "0000";	-- 4 bit rx_ctrl for FIFO 1 to be sent for MAC Learning
	signal r_en_pkt: std_logic; -- Packet length FIFO read enable
	signal w_en_pkt: std_logic;	-- Packet length FIFO write enable
	signal fifo_full_pkt: std_logic;	-- Packet length FIFO full flag
	signal fifo_empty_pkt: std_logic; -- Packet length FIFO empty flag
	signal temp_add_req: std_logic;	-- Request signal to fetch src and dest address from address FIFO
	signal temp_add_ack: std_logic;	-- Acknowledge signal from address FIFO
	
	-- State machine states
	TYPE state_type is (ERROR_CHECK, DECIDE_NEXT_STATE, GET_ADDR, SEND_MAC_REQ, WAIT_FOR_MAC, SEND_DATA_TO_OUTPUT, DELETE_PKT);
   signal state   : state_type;

begin
	-- inp_block_data_out <= fifo_data;
	temp_inp_block_data_in <= inp_block_data_in;
	mac_req <= temp_mac_req;
	
	-- Port maps
	-- Generating SOF and EOF signals for each port
	delay_rxctrl: rxctrl_delay
		port map(
			rx_ctrl_clk => inp_block_clk,
			rx_ctrl => inp_block_rx_ctrl,
			start_of_frame => SOF,
			end_of_frame => EOF
		);
	
	-- FCS Check
	FCS: fcs_check_parallel
		port map(
			clk => inp_block_clk,
			reset => inp_block_rst,
			start_of_frame => SOF,
			fcs_rx_ctrl => inp_block_rx_ctrl,
			data_in => temp_inp_block_data_in,
			fcs_error => temp_fcs_error_check
		);
	
	-- Storing in sync fifo
	store_data: sync_fifo
		port map(
			clock	=> inp_block_clk,
			data(7 downto 0) => temp_inp_block_data_in,
			data(8) => EOF,
			rdreq	=>	r_en,
			wrreq	=> w_en,
			empty	=> fifo_empty,
			full => fifo_full,
			q => fifo_data
		);

	--	Counting pakcet length
	counter: pkt_length_counter
		port map(
			counter_clk => inp_block_clk,
			counter_rst => inp_block_rst,
			counter_rx_ctrl => inp_block_rx_ctrl,
			counter_data_in => temp_inp_block_data_in,
			pkt_length => temp_packet_length1,
			pkt_length_vector => temp_packet_length_vector1
		);
	
	-- Storing packet length in pkt_length_fifo
	store_pkt_length: pkt_length_fifo
		port map(
			clock => inp_block_clk,
			data(10 downto 0) => temp_packet_length_vector1,
			data(11) => EOF,
			rdreq	=> r_en_pkt,
			wrreq	=> w_en_pkt,
			empty => fifo_empty_pkt,
			full => fifo_full_pkt,
			q => temp_packet_length_vector2
		);
		
	-- stores SRC and DEST address as well as retrieves to send to MAC Learning
	address_fifo: address_fifo_wrapper
		port map(
			add_clock => inp_block_clk,
			add_reset => inp_block_rst,
			add_rx_ctrl => inp_block_rx_ctrl,
			add_req => temp_add_req,
			add_data_in => temp_inp_block_data_in,
			-- add_data_out => add_data_out,
			add_ack => temp_add_ack,
			src_address => temp_src_address,
			dest_address => temp_dest_address
		);
	
	
	-- Writing to the input packet FIFO
	process(inp_block_rx_ctrl, inp_block_clk, inp_block_rst)
		begin
			if (inp_block_rst = '1') then
				w_en <= '0';
			elsif (rising_edge(inp_block_clk)) then
				if inp_block_rx_ctrl = '1' then
					w_en <= '1';
				else
					w_en <= '0';
				end if;
			end if;
	end process;
	
	-- Writing to packet length FIFO
	process(inp_block_clk, inp_block_rst)
		begin
			if (inp_block_rst = '1') then
				w_en_pkt <= '0';
			elsif (rising_edge(inp_block_clk)) then
				if EOF = '1' then
					w_en_pkt <= '1';
				else
					w_en_pkt <= '0';
				end if;
			end if;
	end process;
	
	
	-- Reading from the FIFO
--	process(inp_block_clk, inp_block_rst)		
--	begin
--		if (inp_block_rst = '1') then
--			r_en <= '0';
--		elsif (rising_edge(inp_block_clk)) then
--			if (inp_block_rx_ctrl = '0') then
--				r_en <= '1';
--			else
--				r_en <= '0';
--			end if;
--		end if;
--	end process;
	
	-- State machine for this input block
	process(inp_block_clk, inp_block_rst)
		begin
			if (inp_block_rst = '1') then
				inp_block_data_out <= "000000000";
				inp_block_port_out <= "0000";
				address_counter <= (others => '0');
				address <= (others => '0');
				pkt_counter <= (others => '0');
				state <= ERROR_CHECK;
				r_en <= '0';
				r_en_pkt <= '0';
			
			elsif (rising_edge(inp_block_clk)) then
				case state is
					when ERROR_CHECK =>
						-- Initializing read enables to low
						r_en <= '0';
						r_en_pkt <= '0';
						temp_add_req <= '0';
						inp_block_data_out <= "000000000";
						inp_block_port_out <= "0000";
						inp_block_pkt_length <= (others => '0');
						-- FCS error check and write to FIFO parallely
						if (EOF = '1') then
							state <= DECIDE_NEXT_STATE;
						else
							state <= ERROR_CHECK;
						end if;
					when DECIDE_NEXT_STATE =>
						-- Decides between packet deletion or MAC Learning
						if (temp_fcs_error_check = '0') then
							address_counter <= (others => '0');
							temp_add_req <= '0';
							state <= GET_ADDR;
						else
							state <= DELETE_PKT;
						end if;
					when GET_ADDR =>
						-- Gets DEST and SRC ADDR from address FIFO for MAC Learning
						if (temp_add_ack = '1') then
							state <= SEND_MAC_REQ;
						elsif (address_counter <= "01011") then
							address_counter <= address_counter+1;
							temp_add_req <= '1';
							state <= GET_ADDR;
						elsif (address_counter >= "01100" and address_counter <= "01110") then
							address_counter <= address_counter +1;
							temp_add_req <= '0';
							state <= GET_ADDR;
						end if;
					when SEND_MAC_REQ =>
						-- Send a request to MAC block
						temp_mac_req <= '1';
						inp_block_port_mac_out <= inp_block_port_mac_in;
						address(95 downto 48) <= temp_src_address;
						address(47 downto 0) <= temp_dest_address;
						state <= WAIT_FOR_MAC;
					when WAIT_FOR_MAC =>
						-- Waits for acknowledgement from MAC block
						if mac_ack = '1' then
							inp_block_port_out <= mac_port;
							r_en <= '1';
							r_en_pkt <= '1';
							temp_mac_req <= '0';
							state <= SEND_DATA_TO_OUTPUT;
						else
							state <= WAIT_FOR_MAC;
							-- r_en <= '1';
						end if;
					when SEND_DATA_TO_OUTPUT =>
						-- Sends data to output block
						if (pkt_counter = "1000001") then
							pkt_counter <= (others => '0');
							r_en <= '0';
							r_en_pkt <= '0';
							state <= ERROR_CHECK;
							-- temp_packet_length2 <= 0;
						else
							pkt_counter <= pkt_counter+1;
							inp_block_data_out <= fifo_data;
							inp_block_pkt_length <= temp_packet_length_vector2(10 downto 0);
							-- temp_packet_length2 <= to_integer(unsigned(temp_packet_length_vector2(10 downto 0)));
							r_en <= '1';
							r_en_pkt <= '1';
							-- end_of_frame <= fifo_data(8);
							state <= SEND_DATA_TO_OUTPUT;
						end if;
					when DELETE_PKT =>
						-- Deletes error packet in FIFO
						if (pkt_counter = temp_packet_length_vector2(10 downto 0)-'1') then
							pkt_counter <= (others => '0');
							r_en <= '0';
							state <= ERROR_CHECK;
						else
							r_en <= '1';
							pkt_counter <= pkt_counter+1;
							state <= DELETE_PKT;
						end if;
				end case;
			end if;
	end process;

end behavioural;