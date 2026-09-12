--*************************************************************************
--* FILE      :   panda_comport.vhd                           	  		 	  *
--* PROJECT   :   PANDA		                    									  *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       30.05.2008  Bründler Oliver    File written              	  *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This block contains a complete RS-232 interface 			  				  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************


-- NOTE!!!
-- fclk must be at leat 16 x baudrate

------------------------------------------------------------------------------
--  Libraries
------------------------------------------------------------------------------
LIBRARY ieee;
	USE ieee.std_logic_1164.all; 

------------------------------------------------------------------------------
--  Entity
------------------------------------------------------------------------------	
ENTITY panda_comport IS 
	GENERIC(
		databits 					: integer := 8;			-- Number of Databits
		baudrate 					: integer := 9600;		-- Baudrate 
		clk_frequency				: integer := 25000000	-- clk Frequency in Hz
	);
	PORT(
		clk 			: IN	std_logic;											-- Clock
		res_n 		: IN  std_logic;											-- Reset
		rx 			: IN  std_logic;											-- Receive Line
		tx 			: OUT std_logic;											-- Transmit Line
		send 			: IN  std_logic;											-- Send Command
		data_in 		: IN  std_logic_vector((databits-1) downto 0);	-- Send Data
		busy 			: OUT std_logic;											-- Busy Output
		do_rdy 		: OUT std_logic;											-- Data received Output
		data_out 	: OUT std_logic_vector((databits-1) downto 0)	-- Received Data
	);
END panda_comport;

------------------------------------------------------------------------------
--  Architecture
------------------------------------------------------------------------------
ARCHITECTURE rtl OF panda_comport IS 
	SIGNAL rx0, rx1 	: std_logic;	-- rx synchronization Registers
	SIGNAL sync			: std_logic;	-- Synchronization trigger
	SIGNAL baud_sync	: std_logic;	-- Synchronized Baudrate Pulses (for Receiving)
	SIGNAL baud			: std_logic;	-- Unsynchronized Bauddrate Pulses (for Sending)
	CONSTANT divider 	: integer := clk_frequency / (2*databits*baudrate);
	CONSTANT f_clk_en : integer := clk_frequency / divider;
	SIGNAL clk_en 		: std_logic;
BEGIN

------------------------------------------------------------------------------
--  clkdiv Process
------------------------------------------------------------------------------	
clkdiv : PROCESS(clk, res_n)
	VARIABLE counter : integer RANGE 1 TO divider;
BEGIN
	IF res_n = '0' THEN
		counter := 1;
		clk_en <= '1';
	ELSIF rising_edge(clk) THEN
		IF counter = divider THEN
			counter := 1;
			clk_en <= '1';
		ELSE
			counter := counter + 1;
			clk_en <= '0';
		END IF;
	END IF;
END PROCESS clkdiv;


------------------------------------------------------------------------------
--  synchronize_rx Process
------------------------------------------------------------------------------
synchronize_rx : PROCESS(clk, res_n)
BEGIN
	IF res_n = '0' THEN
		rx0 <= '1';
		rx1 <= '1';
	ELSIF rising_edge(clk) THEN
		rx0 <= rx;
		rx1 <= rx0;
	END IF;
END PROCESS synchronize_rx;

------------------------------------------------------------------------------
--  receive Process
------------------------------------------------------------------------------
receive : PROCESS(clk, res_n)
	VARIABLE shift_reg 	: std_logic_vector(databits DOWNTO 0); 	-- Shift Register for Receiving
	VARIABLE rx_old 		: std_logic;										-- las Value of rx
	TYPE state IS (idle,					-- No Transfer						-- State Type
						start,				-- Startbit
						rec);					-- Data
	VARIABLE current_state 	: state;											-- State
BEGIN
	-- Reset
	IF res_n = '0' THEN
		do_rdy <= '0';
		data_out <= (OTHERS => '0');
		sync <= '0';
		rx_old := '1';
		current_state := idle;
	ELSIF RISING_EDGE(clk) THEN
		CASE current_state IS	
			-- No Transfer
			WHEN idle => 	do_rdy <= '0';
								-- Synchronization of Baud Generator
								IF rx0 = '0' AND rx_old = '1' THEN
									sync <= '1';
									current_state := start;
								END IF;			
			-- Startbit and Shiftregister inizalization
			WHEN start => 	sync <= '0';
								shift_reg(databits) := '0';
								shift_reg(databits-1 DOWNTO 0) := (OTHERS => '1');
								IF baud_sync = '1' THEN
									current_state := rec;									
								END IF;			
			-- Data Receiving
			WHEN rec =>		IF baud_sync = '1' THEN
									shift_reg := rx & shift_reg(databits DOWNTO 1);
								-- Data Output
								ELSIF shift_reg(0) = '0' THEN
									data_out <= shift_reg(databits DOWNTO 1);
									do_rdy <= '1';
									current_state := idle;
								END IF;
			WHEN OTHERS =>	current_state := idle;
		END CASE;
		rx_old := rx1;
	END IF;
END PROCESS receive;	

------------------------------------------------------------------------------
--  send Process
------------------------------------------------------------------------------
sending : PROCESS(clk, res_n)
	VARIABLE shift_reg 		: std_logic_vector(databits DOWNTO 0);											-- Shift Register for sending
	VARIABLE stop_bit 		: std_logic;																			-- Stop Bit Sent
	VARIABLE bit_cnt 			: integer RANGE 0 TO databits+1;													-- Bit Counter
BEGIN
	-- Reset
	IF res_n = '0' THEN
		tx <= '1';
		busy <= '0';
		shift_reg := (0 => '0', OTHERS => '1');
		bit_cnt := databits-1;
		stop_bit := '1';
	ELSIF RISING_EDGE(clk) THEN			
		-- Read Data
		IF send = '1' AND stop_bit = '1' THEN
			shift_reg := data_in & '0';
			busy <= '1';
			stop_bit := '0';	
			bit_cnt := 0;		
		-- Send Data
		ELSIF baud = '1' THEN						
			-- End of Transfer (including Stopbit)
			IF bit_cnt = databits+1 THEN
				IF stop_bit = '0' THEN
					tx <= '1';
					stop_bit := '1';
				ELSE
					busy <= '0';
				END IF;										
			-- Data Transfer
			ELSIF stop_bit = '0' THEN
				tx <= shift_reg(0);
				shift_reg := '1' & shift_reg(databits DOWNTO 1);
				bit_cnt := bit_cnt + 1;
			END IF;
		END IF;
	END IF;
END PROCESS sending;

------------------------------------------------------------------------------
--  baudgen Process
------------------------------------------------------------------------------
baudgen : PROCESS(clk, res_n)
	VARIABLE counter, 																		-- counter for Clockdividing
				sync_point : integer RANGE 0 TO (f_clk_en / baudrate)-1; 		-- Sync Point for baud_sync
BEGIN
	-- Reset
	IF res_n = '0' THEN
		baud <= '0';
		baud_sync <= '0';
		counter := 0;
	ELSIF RISING_EDGE(clk) THEN		
		-- Generation of baud
		IF counter = 0 AND clk_en = '1' THEN
			baud <= '1';
		ELSE
			baud <= '0';
		END IF;		
		-- Generation of baud_sync
		IF counter = sync_point AND clk_en = '1' THEN
			baud_sync <= '1';
		ELSE
			baud_sync <= '0';
		END IF;		
		-- synchronization of baud_sync
		IF sync = '1' THEN
			IF counter >= (f_clk_en / baudrate)/2 THEN 
				sync_point := counter - (f_clk_en / baudrate)/2;
			ELSE
				sync_point := counter + (f_clk_en / baudrate)/2;
			END IF; 
		END IF;		
		-- Counter
		IF clk_en = '1' THEN
			IF counter = (f_clk_en / baudrate)-1 THEN
				counter := 0;
			ELSE
				counter := counter + 1;
			END IF;
		END IF;
	END IF;
END PROCESS baudgen;

END ARCHITECTURE rtl;
