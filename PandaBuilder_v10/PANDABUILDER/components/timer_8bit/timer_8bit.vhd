--**************************************************************************
--* FILE      :   timer_8bit.vhd		                            	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       22.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is a 8-Bit Timer. Its resolutions is configurable through	*
--* Generics. Different Settings can be Made through the Configuration		*
--* Register.
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
ENTITY timer_8bit IS
	GENERIC (
		clk_frequency 	: integer := 10000000;
		resolution_us	: integer := 1000
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		adr				: IN 	std_logic_vector(1 DOWNTO 0);
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		int				: OUT	std_logic
	);
END ENTITY timer_8bit;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF timer_8bit IS
	SIGNAL 	tmr_reg,																			-- BASE + 0x00 = TMR		R/W
				rld_reg	: std_logic_vector(7 DOWNTO 0);								-- BASE + 0x01 = RLD 	R/W
	SIGNAL	cfg_reg	: std_logic_vector(3 DOWNTO 0);								-- BASE + 0x02	= CFG		R/W	[UPDOWN RELOAD RUN INTON]
	SIGNAL	int_reg	: std_logic;														-- BASE + 0x03 = INT		R/W	
	
	ALIAS		updown IS cfg_reg(3);
	ALIAS		reload IS cfg_reg(2);
	ALIAS		run IS cfg_reg(1);
	ALIAS		inton IS cfg_reg(0);
BEGIN

----------------------------------------------------------------------------
--  do_timer Process
----------------------------------------------------------------------------
do_timer : PROCESS(clk, res_n)
	CONSTANT MAXCOUNT : integer := (((clk_frequency / 1000) * resolution_us)/1000)-1;
	VARIABLE prescaler : integer RANGE 0 TO MAXCOUNT;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		tmr_reg <= (OTHERS => '0');
		rld_reg <= (OTHERS => '0');
		cfg_reg <= (OTHERS => '0');
		int_reg <= '0';
		prescaler := 0;
	ELSIF rising_edge(clk) THEN
	
		-- Register Access
		IF cs = '1' THEN
			IF wr = '1' THEN															-- Write Access
				CASE adr IS
					WHEN "00" =>	NULL;												-- TMR (Is programmed in "Run Timer")
					WHEN "01" => 	rld_reg <= din;								-- RLD
					WHEN "10" =>	cfg_reg <= din(3 DOWNTO 0);				-- CFG
					WHEN "11" =>	NULL;												-- INT (Is programmed in "Interrupt Register")
					WHEN OTHERS => NULL;
				END CASE;
			ELSIF rd = '1' THEN														-- Read Access
				dout <= (OTHERS => '0');
				CASE adr IS
					WHEN "00" =>	dout <= tmr_reg;								-- TMR
					WHEN "01" =>	dout <= rld_reg;								-- RLD
					WHEN "10" =>	dout(3 DOWNTO 0) <= cfg_reg;				-- CFG
					WHEN "11" =>	dout(0) <= int_reg;							-- INT
					WHEN OTHERS => NULL;
				END CASE;
			END IF;
		END IF;
	
	
		-- Run Timer
		IF cs = '1' AND wr = '1' AND adr = "00" THEN							-- Write Access
			tmr_reg <= din;
		ELSIF prescaler = MAXCOUNT AND run = '1' THEN						-- Normal Run
			IF reload = '1' AND ((updown = '1' AND tmr_reg = X"FF") OR 
				(updown = '0' AND tmr_reg = X"00")) THEN	
				tmr_reg <= rld_reg;
			ELSE
				IF updown = '1' THEN
					tmr_reg <= std_logic_vector(unsigned(tmr_reg) + 1);
				ELSE
					tmr_reg <= std_logic_vector(unsigned(tmr_reg) - 1);
				END IF;
			END IF;
		END IF;
		
		-- Interrupt Register
		IF cs = '1' AND wr = '1' AND adr = "11" THEN
			int_reg <= din(0);
		ELSIF prescaler = MAXCOUNT AND run = '1' AND
			((updown = '1' AND tmr_reg = X"FF") OR 
			(updown = '0' AND tmr_reg = X"00")) THEN
			int_reg <= '1';
		END IF;
		
		-- Prescaler
		IF (prescaler = MAXCOUNT) OR (cs = '1' AND wr = '1' AND adr = "00")THEN
			prescaler := 0;
		ELSE
			prescaler := prescaler + 1;
		END IF;
	END IF;
END PROCESS do_timer;

-- Assign Interrupt Output
int <= int_reg WHEN inton = '1' ELSE '0';

END ARCHITECTURE rtl;
