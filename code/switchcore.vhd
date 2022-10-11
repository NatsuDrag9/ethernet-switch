library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity switchcore is

	port
			(
				clk:			in	std_logic;
				reset:			in	std_logic;
				
				--Activity indicators
				link_sync:		in	std_logic_vector(3 downto 0);	--High indicates a peer connection at the physical layer. 
				
				--Four GMII interfaces
				tx_data:			out	std_logic_vector(31 downto 0);	--(7 downto 0)=TXD0...(31 downto 24=TXD3)
				tx_ctrl:			out	std_logic_vector(3 downto 0);	--(0)=TXC0...(3=TXC3)
				rx_data:			in	std_logic_vector(31 downto 0);	--(7 downto 0)=RXD0...(31 downto 24=RXD3)
				rx_ctrl:			in	std_logic_vector(3 downto 0)	--(0)=RXC0...(3=RXC3)
			);

end switchcore;

architecture arch of switchcore is

	component switchcore_input
		port
			(
				-- Input signals to the input block of switch
				switch_inp_clk:			in	std_logic;
				switch_inp_rst:			in	std_logic;
				switch_inp_rx_data_in:	in	std_logic_vector(31 downto 0);	-- Input data for all ports
				switch_inp_rx_ctrl:	in	std_logic_vector(3 downto 0);	-- rx_ctrl for all ports
				
				-- I/O signals for input block and MAC learning block
				-- Port 1
				mac_ack1: in std_logic; -- Acknowledge signal for port 1 FIFO from MAC block
				inp_block_port_mac_in1: in std_logic_vector(3 downto 0); -- Port 1
				mac_port1: in std_logic_vector(3 downto 0);	-- Destination port for port 1 FIFO to send data to obtained from MAC block
				mac_req1: out std_logic;	-- Request sent to MAC Learning block for all ports
				address1: out std_logic_vector(95 downto 0);	-- Sends src and dest mac address sent from port 1 FIFO to MAC block
				inp_block_port_mac_out1: out std_logic_vector(3 downto 0);	-- Port 1 FIFO to be sent for MAC Learning
				-- Port 2
				mac_ack2: in std_logic; -- Acknowledge signal for port 2 FIFO from MAC block
				mac_port2: in std_logic_vector(3 downto 0);	-- Destination port for port 2 FIFO to send data to obtained from MAC block
				inp_block_port_mac_in2: in std_logic_vector(3 downto 0); -- Port 2
				address2: out std_logic_vector(95 downto 0);	-- Sends src and dest mac address sent from port 2 FIFO to MAC block
				inp_block_port_mac_out2: out std_logic_vector(3 downto 0);	-- Port 2 FIFO to be sent for MAC Learning
				mac_req2: out std_logic;	-- Request sent to MAC Learning block from port 2 FIFO
				-- Port 3
				mac_ack3: in std_logic; -- Acknowledge signal for port 3 FIFO from MAC block
				mac_port3: in std_logic_vector(3 downto 0);	-- Destination port for port 3 FIFO to send data to obtained from MAC block
				inp_block_port_mac_in3: in std_logic_vector(3 downto 0); -- Port 3
				address3: out std_logic_vector(95 downto 0);	-- Sends src and dest mac address sent from port 3 FIFO to MAC block
				inp_block_port_mac_out3: out std_logic_vector(3 downto 0);	-- Port 3 FIFO to be sent for MAC Learning
				mac_req3: out std_logic;	-- Request sent to MAC Learning block from port 3 FIFO
				-- Port 4
				mac_ack4: in std_logic; -- Acknowledge signal for port 4 FIFO from MAC block
				mac_port4: in std_logic_vector(3 downto 0);	-- Destination port for port 4 FIFO to send data to obtained from MAC block
				inp_block_port_mac_in4: in std_logic_vector(3 downto 0); -- Port 4
				address4: out std_logic_vector(95 downto 0);	-- Sends src and dest mac address sent from port 4 FIFO to MAC block
				inp_block_port_mac_out4: out std_logic_vector(3 downto 0);	-- Port 4 FIFO to be sent for MAC Learning
				mac_req4: out std_logic;	-- Request sent to MAC Learning block from port 4 FIFO

				-- Output signals from input block to the output block of switch
				-- Port 1
				data_out1: out std_logic_vector(8 downto 0); -- Port 1 data to be sent to output block along with EOF
				pkt_length_port1: out std_logic_vector(10 downto 0);	-- Port 1 packet length to be sent to output port
				output_port1: out std_logic_vector(3 downto 0);	-- Destination port for port 1 obtained from MAC Learning block
				-- Port 2
				data_out2: out std_logic_vector(8 downto 0); -- Port 2 data to be sent to output block along with EOF
				pkt_length_port2: out std_logic_vector(10 downto 0);	-- Port 2 packet length to be sent to output port
				output_port2: out std_logic_vector(3 downto 0);	-- Destination port for port 2 obtained from MAC Learning block
				-- Port 3
				data_out3: out std_logic_vector(8 downto 0); -- Port 3 data to be sent to output block along with EOF
				pkt_length_port3: out std_logic_vector(10 downto 0);	-- Port 3 packet length to be sent to output port
				output_port3: out std_logic_vector(3 downto 0);	-- Destination port for port 3 obtained from MAC Learning block
				-- Port 4
				data_out4: out std_logic_vector(8 downto 0); -- Port 4 data to be sent to output block along with EOF
				pkt_length_port4: out std_logic_vector(10 downto 0);	-- Port 4 packet length to be sent to output port
				output_port4: out std_logic_vector(3 downto 0)	-- Destination port for port 4 obtained from MAC Learning block
			);
	end component;

	component MAC_arch
		port
			(
				clk:			in	std_logic;
				reset:		in	std_logic;
				
				addresses_1:			in	std_logic_vector(95 downto 0);
				s_port_1:		in std_logic_vector(3 downto 0);
				req_1:			in	std_logic;	
				
				ack_1:			out	std_logic;	
				d_port_1:		out	std_logic_vector(3 downto 0);

				addresses_2:			in	std_logic_vector(95 downto 0);
				s_port_2:		in std_logic_vector(3 downto 0);
				req_2:			in	std_logic;	
				
				ack_2:			out	std_logic;	
				d_port_2:		out	std_logic_vector(3 downto 0);

				addresses_3:			in	std_logic_vector(95 downto 0);
				s_port_3:		in std_logic_vector(3 downto 0);
				req_3:			in	std_logic;	
				
				ack_3:			out	std_logic;	
				d_port_3:		out	std_logic_vector(3 downto 0);

				addresses_4:			in	std_logic_vector(95 downto 0);
				s_port_4:		in std_logic_vector(3 downto 0);
				req_4:			in	std_logic;	
				
				ack_4:			out	std_logic;	
				d_port_4:		out	std_logic_vector(3 downto 0)
			);
	end component;

	component scheduling_buffering
		port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        data_1         : in  std_logic_vector(8 downto 0);
	data_2         : in  std_logic_vector(8 downto 0);
        data_3         : in  std_logic_vector(8 downto 0);
	data_4         : in  std_logic_vector(8 downto 0);
	port_1         : in std_logic_vector (3 downto 0);
	port_2         : in std_logic_vector (3 downto 0);
	port_3         : in std_logic_vector (3 downto 0);
	port_4         : in std_logic_vector (3 downto 0);
	length_1       : in std_logic_vector(10 downto 0);
	length_2       : in std_logic_vector(10 downto 0);
	length_3       : in std_logic_vector(10 downto 0);
	length_4       : in std_logic_vector(10 downto 0);
        tx             : out std_logic_vector(3 downto 0);
	tx_data        : out std_logic_vector(31 downto 0)
		  );
	end component;

	-- Signals
	-- Switch Input
	signal temp_mac_ack1: std_logic;
	signal temp_mac_req1: std_logic;
	signal temp_inp_block_port_mac_in1: std_logic_vector(3 downto 0);
	signal temp_mac_port1: std_logic_vector(3 downto 0);
	signal temp_address1: std_logic_vector(95 downto 0);
	signal temp_inp_block_port_mac_out1: std_logic_vector(3 downto 0);
	signal temp_data_out1: std_logic_vector(8 downto 0);
	signal temp_pkt_length_port1: std_logic_vector(10 downto 0);
	signal temp_output_port1: std_logic_vector(3 downto 0);
	signal temp_mac_ack2: std_logic;
	signal temp_mac_req2: std_logic;
	signal temp_inp_block_port_mac_in2: std_logic_vector(3 downto 0);
	signal temp_mac_port2: std_logic_vector(3 downto 0);
	signal temp_address2: std_logic_vector(95 downto 0);
	signal temp_inp_block_port_mac_out2: std_logic_vector(3 downto 0);
	signal temp_data_out2: std_logic_vector(8 downto 0);
	signal temp_pkt_length_port2: std_logic_vector(10 downto 0);
	signal temp_output_port2: std_logic_vector(3 downto 0);
	signal temp_mac_ack3: std_logic;
	signal temp_mac_req3: std_logic;
	signal temp_inp_block_port_mac_in3: std_logic_vector(3 downto 0);
	signal temp_mac_port3: std_logic_vector(3 downto 0);
	signal temp_address3: std_logic_vector(95 downto 0);
	signal temp_inp_block_port_mac_out3: std_logic_vector(3 downto 0);
	signal temp_data_out3: std_logic_vector(8 downto 0);
	signal temp_pkt_length_port3: std_logic_vector(10 downto 0);
	signal temp_output_port3: std_logic_vector(3 downto 0);
	signal temp_mac_ack4: std_logic;
	signal temp_mac_req4: std_logic;
	signal temp_inp_block_port_mac_in4: std_logic_vector(3 downto 0);
	signal temp_mac_port4: std_logic_vector(3 downto 0);
	signal temp_address4: std_logic_vector(95 downto 0);
	signal temp_inp_block_port_mac_out4: std_logic_vector(3 downto 0);
	signal temp_data_out4: std_logic_vector(8 downto 0);
	signal temp_pkt_length_port4: std_logic_vector(10 downto 0);
	signal temp_output_port4: std_logic_vector(3 downto 0);
	



BEGIN

-- Port maps
	switch_input: switchcore_input
		port map(
			-- Port 1
			switch_inp_clk => clk,
			switch_inp_rst => reset,
			switch_inp_rx_data_in => rx_data,
			switch_inp_rx_ctrl => rx_ctrl,
			mac_ack1 => temp_mac_ack1,
			inp_block_port_mac_in1 => "0001",
			mac_port1 => temp_mac_port1,
			mac_req1 => temp_mac_req1,
			address1 => temp_address1,
			inp_block_port_mac_out1 => temp_inp_block_port_mac_out1,
			data_out1 => temp_data_out1,
			pkt_length_port1 => temp_pkt_length_port1,
			output_port1 => temp_output_port1,
			-- Port 2
			mac_ack2 => temp_mac_ack2,
			inp_block_port_mac_in2 => "0010",
			mac_port2 => temp_mac_port2,
			mac_req2 => temp_mac_req2,
			address2 => temp_address2,
			inp_block_port_mac_out2 => temp_inp_block_port_mac_out2,
			data_out2 => temp_data_out2,
			pkt_length_port2 => temp_pkt_length_port2,
			output_port2 => temp_output_port2,
			-- Port 3
			mac_ack3 => temp_mac_ack3,
			inp_block_port_mac_in3 => "0100",
			mac_port3 => temp_mac_port3,
			mac_req3 => temp_mac_req3,
			address3 => temp_address3,
			inp_block_port_mac_out3 => temp_inp_block_port_mac_out3,
			data_out3 => temp_data_out3,
			pkt_length_port3 => temp_pkt_length_port3,
			output_port3 => temp_output_port3,
			-- Port 4 
			mac_ack4 => temp_mac_ack4,
			inp_block_port_mac_in4 => "1000",
			mac_port4 => temp_mac_port4,
			mac_req4 => temp_mac_req4,
			address4 => temp_address4,
			inp_block_port_mac_out4 => temp_inp_block_port_mac_out4,
			data_out4 => temp_data_out4,
			pkt_length_port4 => temp_pkt_length_port4,
			output_port4 => temp_output_port4
	);


	mac_arc: MAC_arch 
	port map(
		clk => clk,
		reset => reset,
		addresses_1 => temp_address1,
		s_port_1 => temp_inp_block_port_mac_out1,
		req_1 => temp_mac_req1,
		ack_1 => temp_mac_ack1,
		d_port_1 => temp_mac_port1,
		addresses_2 => temp_address2,
		s_port_2 => temp_inp_block_port_mac_out2,
		req_2 => temp_mac_req2,
		ack_2 => temp_mac_ack2,
		d_port_2 => temp_mac_port2,
		addresses_3 => temp_address3,
		s_port_3 => temp_inp_block_port_mac_out3,
		req_3 => temp_mac_req3,
		ack_3 => temp_mac_ack3,
		d_port_3 => temp_mac_port3,
		addresses_4 => temp_address4,
		s_port_4 => temp_inp_block_port_mac_out4,
		req_4 => temp_mac_req4,
		ack_4 => temp_mac_ack4,
		d_port_4 => temp_mac_port4
	);

	switch_output: scheduling_buffering
		port map (
		
		clk        => clk,
        	reset      => reset,
       		data_1     => temp_data_out1,
		data_2     => temp_data_out2,
        	data_3     => temp_data_out3,
		data_4     => temp_data_out4,
		port_1     => temp_output_port1,
		port_2     => temp_output_port2,
		port_3     => temp_output_port3,
		port_4     => temp_output_port4,
		length_1   => temp_pkt_length_port1,
		length_2   => temp_pkt_length_port2,
		length_3   => temp_pkt_length_port3,
		length_4   => temp_pkt_length_port4,
        	tx         => tx_ctrl,
		tx_data    => tx_data
		 
			);

END arch;

