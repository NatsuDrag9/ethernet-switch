library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity switchcore_input is

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
				pkt_length_port4:out std_logic_vector(10 downto 0);	-- Port 4 packet length to be sent to output port
				output_port4: out std_logic_vector(3 downto 0)	-- Destination port for port 4 obtained from MAC Learning block
			);

end switchcore_input;

architecture behavioural of switchcore_input is

	component switchcore_input_block
		port (
			inp_block_rx_ctrl:	in std_logic;
			inp_block_data_in:	in std_logic_vector(7 downto 0);
			inp_block_clk: in std_logic;
			inp_block_rst: in std_logic;
			mac_ack: in std_logic; -- Acknowledge signal from MAC block
			mac_port: in std_logic_vector(3 downto 0);	-- Destination port to send data to obtained from MAC block
			address: out std_logic_vector(95 downto 0);	-- Sends src and dest mac address to MAC block
			inp_block_port_mac_in: in std_logic_vector(3 downto 0); -- Port corresponding to this FIFO 
			inp_block_port_mac_out: out std_logic_vector(3 downto 0);	-- FIFO 1 port to be sent for MAC Learning
			mac_req: out std_logic;	-- Request sent to MAC Learning block from FIFO1
			-- fcs_error_check: out std_logic;
			-- start_of_frame: out std_logic;
			-- end_of_frame: out std_logic;
			inp_block_data_out:	out std_logic_vector(8 downto 0);	-- data to be sent to output port
			inp_block_port_out:	out std_logic_vector(3 downto 0);	-- Destination port to send data to
			inp_block_pkt_length:	out std_logic_vector(10 downto 0) -- sends packet length to output block
		);
	end component;
	
	-- Signals
--	signal temp_mac_req1: std_logic;	-- MAC request from port 1 fifo
--	signal temp_mac_req2: std_logic;	-- MAC request from port 2 fifo
--	signal temp_mac_req3: std_logic;	-- MAC request from port 3 fifo
--	signal temp_mac_req4: std_logic;	-- MAC request from port 3 fifo
	
begin
--	mac_req(0) <= temp_mac_req1;
--	mac_req(1) <= temp_mac_req2;
--	mac_req(2) <= temp_mac_req3;
--	mac_req(3) <= temp_mac_req4;
	
	unit_port1: switchcore_input_block
		port map (
			inp_block_rx_ctrl => switch_inp_rx_ctrl(0),
			inp_block_data_in => switch_inp_rx_data_in(7 downto 0),
			inp_block_clk => switch_inp_clk,
			inp_block_rst => switch_inp_rst,
			mac_ack => mac_ack1,
			mac_port => mac_port1,
			address => address1,
			inp_block_port_mac_in => inp_block_port_mac_in1,
			inp_block_port_mac_out => inp_block_port_mac_out1,
			mac_req => mac_req1,
			-- fcs_error_check: out std_logic;
			-- start_of_frame: out std_logic;
			-- end_of_frame: out std_logic;
			inp_block_data_out => data_out1,
			inp_block_port_out => output_port1,
			inp_block_pkt_length => pkt_length_port1
		);
	
	unit_port2: switchcore_input_block
		port map (
			inp_block_rx_ctrl => switch_inp_rx_ctrl(1),
			inp_block_data_in => switch_inp_rx_data_in(15 downto 8),
			inp_block_clk => switch_inp_clk,
			inp_block_rst => switch_inp_rst,
			mac_ack => mac_ack2,
			mac_port => mac_port2,
			address => address2,
			inp_block_port_mac_in => inp_block_port_mac_in2,
			inp_block_port_mac_out => inp_block_port_mac_out2,
			mac_req => mac_req2,
			-- fcs_error_check: out std_logic;
			-- start_of_frame: out std_logic;
			-- end_of_frame: out std_logic;
			inp_block_data_out => data_out2,
			inp_block_port_out => output_port2,
			inp_block_pkt_length => pkt_length_port2
		);
	
	unit_port3: switchcore_input_block
		port map (
			inp_block_rx_ctrl => switch_inp_rx_ctrl(2),
			inp_block_data_in => switch_inp_rx_data_in(23 downto 16),
			inp_block_clk => switch_inp_clk,
			inp_block_rst => switch_inp_rst,
			mac_ack => mac_ack3,
			mac_port => mac_port3,
			address => address3,
			inp_block_port_mac_in => inp_block_port_mac_in3,
			inp_block_port_mac_out => inp_block_port_mac_out3,
			mac_req => mac_req3,
			-- fcs_error_check: out std_logic;
			-- start_of_frame: out std_logic;
			-- end_of_frame: out std_logic;
			inp_block_data_out => data_out3,
			inp_block_port_out => output_port3,
			inp_block_pkt_length => pkt_length_port3
		);

	unit_port4: switchcore_input_block
		port map (
			inp_block_rx_ctrl => switch_inp_rx_ctrl(3),
			inp_block_data_in => switch_inp_rx_data_in(31 downto 24),
			inp_block_clk => switch_inp_clk,
			inp_block_rst => switch_inp_rst,
			mac_ack => mac_ack4,
			mac_port => mac_port4,
			address => address4,
			inp_block_port_mac_in => inp_block_port_mac_in4,
			inp_block_port_mac_out => inp_block_port_mac_out4,
			mac_req => mac_req4,
			-- fcs_error_check: out std_logic;
			-- start_of_frame: out std_logic;
			-- end_of_frame: out std_logic;
			inp_block_data_out => data_out4,
			inp_block_port_out => output_port4,
			inp_block_pkt_length => pkt_length_port4
		);
		

end behavioural;