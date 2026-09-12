--**************************************************************************
--* FILE      :   watchdog.vhd		                            	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       28.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is a watchdog. Its period can be configured over a generic	*
--* and the watchdog can be reset with a write signal. It can be 				*
--* configured to generate an interrupt or an external signal if the			*
--* watchdog is not reset before it reaches zero.
--*                                                                       	*
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   	*
--**************************************************************************

----------------------------------------------------------------------------
--  Libraries
----------------------------------------------------------------------------
LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	USE ieee.numeric_std.all;

----------------------------------------------------------------------------
--  Entity
----------------------------------------------------------------------------
ENTITY watchdog IS
	GENERIC (
		clk_frequency 	: integer := 10000000;
		period_ms		: integer := 1000			-- Timeout Period
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		adr				: IN 	std_logic;
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		int				: OUT	std_logic;
		-- *** External Ports ***
		tout_n			: OUT std_logic
	);
END ENTITY watchdog;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF watchdog IS
	 																								-- BASE + 0x00 = RST		W
	SIGNAL	cfg_reg	: std_logic_vector(1 DOWNTO 0);								-- BASE + 0x01 = CFG 	R/W	[INTON EXTON]
	SIGNAL	int_reg	: std_logic;
	SIGNAL	res_n_sync : std_logic_vector(1 DOWNTO 0);														
	
	ALIAS		exton IS cfg_reg(0);
	ALIAS		inton IS cfg_reg(1);
BEGIN

----------------------------------------------------------------------------
--  wd_timer Process
----------------------------------------------------------------------------
wd_timer : PROCESS(clk)
	CONSTANT	PRESCALEMAX	: integer := clk_frequency / 1000 - 1;
	VARIABLE wd_counter 	: integer RANGE 0 TO period_ms;
	VARIABLE prescaler 	: integer RANGE 0 TO PRESCALEMAX;
BEGIN
	IF rising_edge(clk) THEN
		-- Reset
		IF (res_n_sync(1) = '0') OR (cs = '1' AND wr = '1' AND adr = '0') THEN
			tout_n <= '1';
			int_reg <= '0';
			wd_counter := period_ms;
			prescaler := PRESCALEMAX;
		-- Watchdog Timer
		ELSE
			-- Timeout
			IF wd_counter = 0 THEN
				IF exton = '1' THEN
					tout_n <= '0';
				END IF;
				int_reg <= '1';
			-- Normal Run
			ELSE
				IF prescaler = 0 THEN
					prescaler := PRESCALEMAX;
					wd_counter := wd_counter - 1;
				ELSE
					prescaler := prescaler - 1;
				END IF;
			END IF;
		END IF;
		res_n_sync(1) <= res_n_sync(0);
		res_n_sync(0) <= res_n;		
	END IF;
END PROCESS wd_timer;

-- Assign Interrupt Output
int <= int_reg AND inton;

----------------------------------------------------------------------------
--  cfg_access Process
----------------------------------------------------------------------------
cfg_access : PROCESS(res_n, clk)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		cfg_reg <= "01";
	ELSIF rising_edge(clk) THEN
		-- Write Access
		IF cs = '1' AND wr = '1' AND adr = '1' THEN
			cfg_reg <= din(1 DOWNTO 0);
		END IF;
	END IF;
END PROCESS cfg_access;

dout(7 DOWNTO 2) <= (OTHERS => '0');
dout(1 DOWNTO 0) <= cfg_reg;



END ARCHITECTURE rtl;
