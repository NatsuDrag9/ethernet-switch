library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity address_fifo_wrapper is
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
end address_fifo_wrapper;

architecture behavioural of address_fifo_wrapper is

	component address_fifo
		port(
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
			rdreq		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			empty		: OUT STD_LOGIC ;
			full		: OUT STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
		);
	end component;

	-- FIFO signals
	signal r_en_add: std_logic;	-- Address FIFO read enable
	signal EOF_add: std_logic := '0';		-- EOF to separate addresses of two packets
	signal w_en_add: std_logic;	-- Address FIFO write enable
	signal fifo_full_add: std_logic; -- Address FIFO full flag
	signal fifo_empty_add: std_logic; -- Address FIFO empty flag
	signal r_add_counter: integer range 0 to 20 := 0; -- Counter read SRC and DESR address from FIFO for MAC Learning
	signal wr_add_counter: integer range 0 to 1550 := 0; -- Counter to write SRC and DEST address from input packet into FIFO
	signal EOF_out: std_logic;
	signal temp_add_ack: std_logic := '0';
	signal fifo_data_add: std_logic_vector(7 downto 0); -- Gets data from fifo
	signal temp_src_add: std_logic_vector(47 downto 0) := (others => '0');	-- Temporary signal for src address
	signal temp_dest_add: std_logic_vector(47 downto 0) := (others => '0');	-- Temporary signal for dest address
	
begin
	
	store_address: address_fifo 
		port map(
			clock => add_clock,
			data(7 downto 0) => add_data_in,
			data(8) => EOF_add,
			rdreq	=> r_en_add,
			wrreq	=> w_en_add,
			empty	=> fifo_empty_add,
			full => fifo_full_add,
			q(7 downto 0) => fifo_data_add,
			q(8) => EOF_out
		);
		
	add_ack <= temp_add_ack;
	src_address <= temp_src_add;
	dest_address <= temp_dest_add;
	-- add_data_out <= fifo_data_add;
	
	-- Writing to the address FIFO
	process(add_reset, add_clock)
		begin
			if (add_reset = '1') then
				w_en_add <= '0';
				wr_add_counter <= 0;

			elsif (rising_edge(add_clock)) then
				if (add_rx_ctrl = '1') then
					if(wr_add_counter >= 7 and wr_add_counter < 19) then
						if(wr_add_counter = 18) then
							EOF_add <= '1';
						else
							EOF_add <= '0';
						end if;
						w_en_add <= '1';
						-- wr_add_counter <= wr_add_counter + 1;
					elsif (wr_add_counter = 19) then
						w_en_add <= '0';
						EOF_add <= '1';
					end if;
					wr_add_counter <= wr_add_counter + 1;
				else
					wr_add_counter <= 0;
				end if;
			end if;
	end process;
	
	
	-- Reading address from FIFO
	process(add_reset, add_clock)
		begin
			if (add_reset = '1') then
				r_en_add <= '0';
				r_add_counter <= 0;
				temp_add_ack <= '0';
				temp_dest_add <= (others => '0');
				temp_src_add <= (others => '0');
			elsif (rising_edge(add_clock)) then	
				if (add_req = '1') then
					if (r_add_counter > 1 and r_add_counter <= 7) then
						temp_dest_add((r_add_counter-1)*8-1 downto (r_add_counter-2)*8) <= fifo_data_add;
					elsif (r_add_counter > 7 and r_add_counter <= 11) then
						temp_src_add((r_add_counter-7)*8-1 downto (r_add_counter-8)*8) <= fifo_data_add;
					end if;
					r_en_add <= '1';
					r_add_counter <= r_add_counter + 1;
				elsif (r_add_counter > 11 and r_add_counter <= 13) then
					temp_src_add((r_add_counter-7)*8-1 downto (r_add_counter-8)*8) <= fifo_data_add;
						if (r_add_counter = 13) then
							temp_add_ack <= '1';
						else
							temp_add_ack <= '0';
						end if;
						r_en_add <= '1';
						r_add_counter <= r_add_counter + 1;
				else
					r_en_add <= '0';
					r_add_counter <= 0;
				end if;
			end if;
	end process;

end behavioural;