--**************************************************************************
--* FILE      :   rs232_buffered.vhd	                            	  		*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       07.09.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block implements a RS-232 connection. Its baudrate is					*
--* configurable over a generic. This comport contains configurable in- 	*
--* and output buffers. It has te ability to generate interrupts on one		*
--* or more of the following events: Byte received, byte sent, receive		*
--* buffer full, send buffer empty, received a defined byte.				   *
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
ENTITY rs232_buffered IS
	GENERIC (
		clk_frequency		: integer := 10000000;
		baudrate				: integer := 9600;
		sndbuf_size			: integer := 128;
		recbuf_size			: integer := 128
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
END ENTITY rs232_buffered;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF rs232_buffered IS
																									-- BASE + 0x00 = DAT 	R/W
	SIGNAL 	rchr_reg	: std_logic_vector(7 DOWNTO 0);								-- BASE + 0x01 = RCHR	R/W
	SIGNAL 	cfg_reg	: std_logic_vector(6 DOWNTO 0);								-- BASE + 0x02 = CFG		R/W	[SFUL REMP CHAR SEMP RFUL REC SND]
	SIGNAL 	int_reg	: std_logic_vector(4 DOWNTO 0);								-- BASE + 0x03 = INT		R/W		       [CHAR SEMP RFUL REC SND] 
	
	ALIAS		sful			IS cfg_reg(6);
	ALIAS		remp			IS	cfg_reg(5);
	ALIAS		char_inton	IS cfg_reg(4);
	ALIAS		semp_inton	IS cfg_reg(3);
	ALIAS		rful_inton	IS cfg_reg(2);
	ALIAS		rec_inton	IS	cfg_reg(1);
	ALIAS		snd_inton	IS cfg_reg(0);
	ALIAS		char_int		IS	int_reg(4);
	ALIAS		semp_int		IS int_reg(3);
	ALIAS		rful_int		IS	int_reg(2);
	ALIAS		rec_int		IS	int_reg(1);
	ALIAS		snd_int		IS	int_reg(0);
	
	
	SIGNAL 	send		: std_logic;
	SIGNAL 	busy_old	: std_logic;
	SIGNAL 	do_rdy	: std_logic;
	SIGNAL 	drec		: std_logic_vector(7 DOWNTO 0);
	SIGNAL	busy		: std_logic;
	
	TYPE 		rec_ram_type IS ARRAY ((recbuf_size-1) DOWNTO 0) OF std_logic_vector(7 DOWNTO 0);
	SIGNAL	rec_ram			: rec_ram_type;
	SIGNAL 	rec_ram_raddr	: integer RANGE 0 TO recbuf_size-1;
	SIGNAL	rec_ram_waddr	: integer RANGE 0 TO recbuf_size-1;
	SIGNAL	rec_ram_data	: std_logic_vector(7 DOWNTO 0);
	SIGNAL	rec_ram_fill	: integer RANGE 0 TO recbuf_size;
	
	TYPE 		snd_ram_type IS ARRAY ((sndbuf_size-1) DOWNTO 0) OF std_logic_vector(7 DOWNTO 0);
	SIGNAL	snd_ram			: snd_ram_type;
	SIGNAL 	snd_ram_raddr	: integer RANGE 0 TO sndbuf_size-1;
	SIGNAL	snd_ram_waddr	: integer RANGE 0 TO sndbuf_size-1;
	SIGNAL	snd_ram_data	: std_logic_vector(7 DOWNTO 0);
	SIGNAL	snd_ram_fill	: integer RANGE 0 TO sndbuf_size;
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
		data_in 	=> snd_ram_data,
		data_out =>	drec,
		rx			=> rx,
		tx			=> tx
	);	

----------------------------------------------------------------------------
--  access_reg Process
----------------------------------------------------------------------------
access_reg : PROCESS(clk, res_n)
	VARIABLE busy_out : std_logic;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		cfg_reg(4 DOWNTO 0) <= (OTHERS => '0');
		snd_int <= '0';
		rec_int <= '0';
		char_int <= '0';
		rchr_reg <= (OTHERS => '0');
		dout <= (OTHERS => '0');
		busy_old <= '0';
		int <= '0';
	ELSIF rising_edge(clk) THEN
		-- Generate Interrupts
		int <= 	(rec_int AND rec_inton) OR (snd_int AND snd_inton) OR
					(rful_int AND rful_inton) OR (semp_int AND semp_inton) OR
					(char_int AND char_inton);
		rec_int <= rec_int OR do_rdy;
		snd_int <= snd_int OR (busy_old AND NOT(busy));
		IF do_rdy = '1' AND drec = rchr_reg THEN
			char_int <= '1';
		END IF;
		busy_old <= busy;
		-- Register Access
		IF cs = '1' THEN
			-- Write Access
			IF wr = '1' THEN
				CASE adr IS
					WHEN "00" =>	snd_int <= '0';									-- DAT (Implemented in access_buf)
					WHEN "01" => 	rchr_reg <= din;									-- RCHR
					WHEN "10" =>	cfg_reg(4 DOWNTO 0) <= din(4 DOWNTO 0);	-- CFG
					WHEN "11" =>	snd_int <= snd_int AND din(0);
										rec_int <= rec_int AND din(1);				-- INT
										char_int <= char_int AND din(4);
					WHEN OTHERS => NULL;
				END CASE;
			-- Read Access
			ELSIF rd = '1' THEN
				dout <= (OTHERS => '0');
				CASE adr IS 
					WHEN "00" =>	dout <= rec_ram_data;							-- DAT
										rec_int <= '0';	
										char_int <= '0';		
					WHEN "01" =>	dout <= rchr_reg;									-- RCHR
					WHEN "10" =>	dout(6 DOWNTO 0) <= cfg_reg;					-- CFG
					WHEN "11" =>	dout(4 DOWNTO 0) <= int_reg;					-- INT
					WHEN OTHERS => dout <= (OTHERS => 'X');
				END CASE;
			END IF;				
		END IF;
	END IF;
END PROCESS access_reg;

----------------------------------------------------------------------------
--  Recieve Buffer
----------------------------------------------------------------------------
rec_buf : PROCESS(res_n, clk)
	VARIABLE rec_ram_fill_var : integer RANGE 0 TO recbuf_size;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		rec_ram_waddr <= 0;
		rec_ram_fill_var := 0;
	ELSIF rising_edge(clk) THEN
		-- Write Buffer
		IF (do_rdy = '1') AND (rful_int = '0') THEN
			rec_ram_fill_var := rec_ram_fill_var+1;
			rec_ram_waddr <= (rec_ram_waddr+1) MOD recbuf_size;
		END IF;
		-- Read Buffer
		IF (cs = '1') AND (rd = '1') AND (adr = "00") AND (remp = '0') THEN
			rec_ram_fill_var := rec_ram_fill_var-1;
		END IF;
	END IF;
	rec_ram_fill <= rec_ram_fill_var;
END PROCESS rec_buf;
rec_ram_raddr <= (rec_ram_waddr+recbuf_size-rec_ram_fill) MOD recbuf_size;
rful_int <= '1' WHEN rec_ram_fill = recbuf_size ELSE '0';
remp <= '1' WHEN rec_ram_fill = 0 ELSE '0';


rec_ram_pr : PROCESS(clk) 
BEGIN
 	IF rising_edge(clk) THEN
 		IF (do_rdy  = '1') AND (rful_int = '0') THEN
 			rec_ram(rec_ram_waddr) <= drec;
 		END IF;
 		rec_ram_data <= rec_ram(rec_ram_raddr);
 	END IF;
END PROCESS rec_ram_pr;

 				

----------------------------------------------------------------------------
--  Send Buffer
----------------------------------------------------------------------------
snd_buf : PROCESS(res_n, clk)
	VARIABLE sent : boolean;
	VARIABLE snd_ram_fill_var : integer RANGE 0 TO sndbuf_size;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		snd_ram_waddr <= 0;
		sent := false;
		snd_ram_fill_var := 0;
	ELSIF rising_edge(clk) THEN
		-- Write Buffer
		IF (cs = '1') AND (wr = '1') AND (adr = "00") AND (sful = '0') THEN
			snd_ram_fill_var := snd_ram_fill_var+1;
			snd_ram_waddr <= (snd_ram_waddr+1) MOD sndbuf_size;
		END IF;
		-- Read Buffer
		IF (busy = '0') AND (semp_int = '0') AND (sent = false) THEN
			send <= '1';
			sent := true;
			snd_ram_fill_var := snd_ram_fill_var-1;
		ELSE
			send <= '0';
			sent := false;
		END IF;
	END IF;
	snd_ram_fill <= snd_ram_fill_var;
END PROCESS snd_buf;
snd_ram_raddr <= (snd_ram_waddr+sndbuf_size-snd_ram_fill) MOD sndbuf_size;
sful <= '1' WHEN snd_ram_fill = sndbuf_size ELSE '0';
semp_int <= '1' WHEN snd_ram_fill = 0 ELSE '0';

snd_ram_pr : PROCESS(clk) 
BEGIN
  	IF rising_edge(clk) THEN	
  		snd_ram_data <= snd_ram(snd_ram_raddr);	
  		IF (cs = '1') AND (wr = '1') AND (adr = "00") AND (sful = '0') THEN
  			snd_ram(snd_ram_waddr) <= din;			
  		END IF;		
  	END IF;
END PROCESS snd_ram_pr;

END ARCHITECTURE rtl;
