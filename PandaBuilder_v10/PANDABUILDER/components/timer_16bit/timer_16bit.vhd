--**************************************************************************
--* FILE      :   timer_16bit.vhd		                            	  		*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       22.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is a 16-Bit Timer. Its resolutions is configurable through	*
--* Generics. Different Settings can be Made through the Configuration		*
--* Register. Timer Register must be read/written over a shadow register	*
--* to provide consistent values over both 8-bit registers.						*
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
ENTITY timer_16bit IS
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
		adr				: IN 	std_logic_vector(2 DOWNTO 0);
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		int				: OUT	std_logic
	);
END ENTITY timer_16bit;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF timer_16bit IS
	
	CONSTANT	TMRL	:	std_logic_vector(2 DOWNTO 0) := "000";		-- BASE + 0x00 = TMRL	R/W
	CONSTANT	TMRH	:	std_logic_vector(2 DOWNTO 0) := "001";		-- BASE + 0x01 = TMRH	R/W
	CONSTANT	RLDL	:	std_logic_vector(2 DOWNTO 0) := "010";		-- BASE + 0x02 = RLDL	R/W
	CONSTANT	RLDH	:	std_logic_vector(2 DOWNTO 0) := "011";		-- BASE + 0x03 = RLDH	R/W
	CONSTANT	SHAD	:	std_logic_vector(2 DOWNTO 0) := "100";		-- BASE + 0x04 = SHAD	-
	CONSTANT	CFG	:	std_logic_vector(2 DOWNTO 0) := "101";		-- BASE + 0x05 = CFG		R/W
	CONSTANT	INT_R	:	std_logic_vector(2 DOWNTO 0) := "110";		-- BASE + 0x06 = INT		R/W
		
	SIGNAL 	tmrl_reg,																		
				tmrh_reg : std_logic_vector(7 DOWNTO 0);																												
	SIGNAL	cfg_reg	: std_logic_vector(3 DOWNTO 0);								
	SIGNAL	int_reg	: std_logic;														
	
	ALIAS		updown IS cfg_reg(3);
	ALIAS		reload IS cfg_reg(2);
	ALIAS		run IS cfg_reg(1);
	ALIAS		inton IS cfg_reg(0);
	
	SIGNAL	tmr, rld	: std_logic_vector(15 DOWNTO 0);
	
	
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
		tmrl_reg <= (OTHERS => '0');
		tmrh_reg <= (OTHERS => '0');
		cfg_reg <= (OTHERS => '0');
		int_reg <= '0';
		tmr <= (OTHERS => '0');
		rld <= (OTHERS => '0');
		prescaler := 0;
	ELSIF rising_edge(clk) THEN
	
		-- Register Access
		IF cs = '1' THEN
			IF wr = '1' THEN															-- Write Access
				CASE adr IS
					WHEN TMRL 	=>	tmrl_reg <= din;								-- TMRL
					WHEN TMRH 	=>	tmrh_reg <= din;								-- TMRH
					WHEN RLDL 	=>	rld(7 DOWNTO 0) <= din;						-- RLDL
					WHEN RLDH 	=>	rld(15 DOWNTO 8) <= din;					-- RLDH
					WHEN SHAD 	=>	NULL;												-- SHAD (Implemented in "Run Timer")
					WHEN CFG 	=>	cfg_reg <= din(3 DOWNTO 0);				-- CFG
					WHEN INT_R 	=>	NULL;												-- INT (Is programmed in "Interrupt Register")
					WHEN OTHERS => NULL;
				END CASE;
			ELSIF rd = '1' THEN														-- Read Access
				dout <= (OTHERS => '0');
				CASE adr IS
					WHEN TMRL 	=>	dout <= tmrl_reg;								-- TMRL
					WHEN TMRH 	=>	dout <= tmrh_reg;								-- TMRH
					WHEN RLDL 	=>	dout <= rld(7 DOWNTO 0);					-- RLDL
					WHEN RLDH 	=>	dout <= rld(15 DOWNTO 8);					-- RLDH
					WHEN SHAD 	=> tmrl_reg <= tmr(7 DOWNTO 0);				-- SHAD (Read Timer, reads 0x00)
										tmrh_reg <= tmr(15 DOWNTO 8);
					WHEN CFG 	=>	dout(3 DOWNTO 0) <= cfg_reg;				-- CFG
					WHEN INT_R 	=>	dout(0) <= int_reg;							-- INT
					WHEN OTHERS => NULL;
				END CASE;
			END IF;
		END IF;
	
	
		-- Run Timer
		IF cs = '1' AND wr = '1' AND adr = SHAD THEN							-- Write Access (Over SHAD)
			tmr <= tmrh_reg & tmrl_reg;
		ELSIF prescaler = MAXCOUNT AND run = '1' THEN						-- Normal Run
			IF reload = '1' AND ((updown = '1' AND tmr = X"FFFF") OR 
				(updown = '0' AND tmr = X"0000")) THEN	
				tmr <= rld;
			ELSE
				IF updown = '1' THEN
					tmr <= std_logic_vector(unsigned(tmr) + 1);
				ELSE
					tmr <= std_logic_vector(unsigned(tmr) - 1);
				END IF;
			END IF;
		END IF;
		
		-- Interrupt Register
		IF cs = '1' AND wr = '1' AND adr = INT_R THEN						-- Write Access
			int_reg <= din(0);
		ELSIF prescaler = MAXCOUNT AND run = '1' AND							-- Detection
			((updown = '1' AND tmr = X"FFFF") OR 
			(updown = '0' AND tmr = X"0000")) THEN
			int_reg <= '1';
		END IF;
		
		-- Prescaler
		IF (prescaler = MAXCOUNT) OR												
			(cs = '1' AND wr = '1' AND adr = SHAD)THEN						-- Reset on SHAD Access 
			prescaler := 0;
		ELSE
			prescaler := prescaler + 1;
		END IF;
	END IF;
END PROCESS do_timer;

-- Assign Interrupt Output
int <= int_reg WHEN inton = '1' ELSE '0';

END ARCHITECTURE rtl;
