--**************************************************************************
--* FILE      :   rs232_simple.vhd		                            	  		*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       31.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block implements a simple RS-232 connection. Its baudrate is		*
--* configurable over a generic. This comport does not contain any buffers	*
--* for incoming and outgoing data. It generates interrupts if a byte is 	*
--* received or sent.
--*                                                                       	*
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   	*
--**************************************************************************

----------------------------------------------------------------------------
--  Libraries
----------------------------------------------------------------------------
LIBRARY ieee;
	USE ieee.std_logic_1164.all;

----------------------------------------------------------------------------
--  Entity
----------------------------------------------------------------------------
ENTITY rs232_simple IS
	GENERIC (
		clk_frequency		: integer := 10000000;
		baudrate				: integer := 9600
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		adr				: IN	std_logic_vector(1 DOWNTO 0);
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		int				: OUT	std_logic;
		-- *** External Ports ***
		rx					: IN	std_logic;
		tx					: OUT	std_logic
	);
END ENTITY rs232_simple;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF rs232_simple IS
	SIGNAL 	dat_reg 	: std_logic_vector(7 DOWNTO 0);								-- BASE + 0x00 = DAT 	R/W
	SIGNAL 	cfg_reg	: std_logic_vector(1 DOWNTO 0);								-- BASE + 0x01 = CFG		R/W	[BUSY REC SND]
	SIGNAL 	int_reg	: std_logic_vector(1 DOWNTO 0);								-- BASE + 0x02 = INT		R/W	[REC SND] 
	
	ALIAS		rec_inton	IS	cfg_reg(1);
	ALIAS		snd_inton	IS cfg_reg(0);
	ALIAS		rec_int		IS	int_reg(1);
	ALIAS		snd_int		IS	int_reg(0);
	
	SIGNAL 	send		: std_logic;
	SIGNAL 	busy		: std_logic;
	SIGNAL 	busy_old	: std_logic;
	SIGNAL 	do_rdy	: std_logic;
BEGIN

----------------------------------------------------------------------------
--  comport
----------------------------------------------------------------------------
comport_I1 : entity work.comport
	GENERIC MAP (
		databits 		=> 8,
		baudrate 		=> baudrate,
		clk_frequency 	=> clk_frequency
	)
	PORT MAP (
		clk 		=> clk,
		res_n 	=> res_n,
		send 		=> send,
		busy 		=> busy,
		do_rdy	=> do_rdy,
		data_in 	=> din,
		data_out =>	dat_reg,
		rx			=> rx,
		tx			=> tx
	);	

----------------------------------------------------------------------------
--  access_reg Process
----------------------------------------------------------------------------
access_reg : PROCESS(clk, res_n)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		cfg_reg <= (OTHERS => '0');
		int_reg <= (OTHERS => '0');
		dout <= (OTHERS => '0');
		busy_old <= '0';
		int <= '0';
	ELSIF rising_edge(clk) THEN
		-- Generate Interrupts
		int <= (rec_int AND rec_inton) OR (snd_int AND snd_inton);
		rec_int <= rec_int OR do_rdy;
		snd_int <= snd_int OR (busy_old AND NOT(busy));
		busy_old <= busy;
		-- Register Access
		send <= '0';
		IF cs = '1' THEN
			-- Write Access
			IF wr = '1' THEN
				CASE adr IS
					WHEN "00" =>	send <= '1';										-- DAT
										snd_int <= '0';	
					WHEN "01" =>	cfg_reg <= din(1 DOWNTO 0);					-- CFG
					WHEN "10" =>	int_reg <= int_reg AND din(1 DOWNTO 0);	-- INT
					WHEN OTHERS => NULL;
				END CASE;
			-- Read Access
			ELSIF rd = '1' THEN
				dout <= (OTHERS => '0');
				CASE adr IS 
					WHEN "00" =>	dout <= dat_reg;									-- DAT
										rec_int <= '0';
					WHEN "01" =>	dout(2) <= busy;									-- CFG
										dout(1 DOWNTO 0) <= cfg_reg;		
					WHEN "10" =>	dout(1 DOWNTO 0) <= int_reg;					-- INT
					WHEN OTHERS => dout <= (OTHERS => 'X');
				END CASE;
			END IF;				
		END IF;
	END IF;
END PROCESS access_reg;

END ARCHITECTURE rtl;
