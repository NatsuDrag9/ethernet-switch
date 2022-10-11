library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity rxctrl_delay is
	port (
				rx_ctrl_clk: in std_logic;
				rx_ctrl : in std_logic;
				start_of_frame: out std_logic;	-- SOF for data corresponding to each port
				end_of_frame: out std_logic		-- EOF for data corresponding to each port
				-- rx_ctrl_d: out std_logic
			);

end rxctrl_delay;

architecture behavioural of rxctrl_delay is
	signal rx_ctrl_delayed: std_logic;
	
begin
	-- rx_ctrl_d <= rx_ctrl_delayed;
	-- Register to delay rx_ctrl
	process (rx_ctrl_clk)
		begin
			if rising_edge(rx_ctrl_clk) then
				rx_ctrl_delayed <= rx_ctrl;
			end if;
	end process;
	
	-- Generating SOF and EOF bits for each port using delayed rx control signal
	process(rx_ctrl, rx_ctrl_delayed)
		begin
			if (rx_ctrl = '1' and rx_ctrl_delayed = '0') then
				start_of_frame <= '1';
			else
				start_of_frame <= '0';
			end if;
			if (rx_ctrl = '0' and rx_ctrl_delayed = '1') then
				end_of_frame <= '1';
			else
				end_of_frame <= '0';
			end if;
	end process;
end behavioural;