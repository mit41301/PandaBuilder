--**************************************************************************
--* FILE      :   ext_interrupt.vhd	                            	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       25.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is an external interrupt. It can be configured to be 			*
--* triggered on a rising or falling edge of the input signal or on a 		*
--* high or low state of the input signal. It can also be configured to		*
--* synchronize the input signal or not through a generic.						*
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
ENTITY ext_interrupt IS
	GENERIC (
		synchronize		: boolean := true
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		adr				: IN	std_logic;
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		int				: OUT	std_logic;
		-- *** External Ports ***
		ext_int			: IN	std_logic
	);
END ENTITY ext_interrupt;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF ext_interrupt IS
	SIGNAL 	trig_reg	: std_logic_vector(3 DOWNTO 0);								-- BASE + 0x00 = TRIG	R/W
	SIGNAL 	ena_reg	: std_logic_vector(3 DOWNTO 0);								-- BASE + 0x01 = ENA		R/W
	
	CONSTANT	RISEBIT	: integer := 0;
	CONSTANT FALLBIT	: integer := 1;
	CONSTANT HIGHBIT	: integer := 2;
	CONSTANT LOWBIT	: integer := 3;	
	
	SIGNAL 	int_sync : std_logic;
	SIGNAL 	int_use 	: std_logic;
BEGIN

----------------------------------------------------------------------------
--  synchronize_int Process
----------------------------------------------------------------------------
synchronize_int : PROCESS(clk, res_n)
	VARIABLE sync_reg : std_logic;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		sync_reg := '0';
		int_sync <= '0';
	-- Synchronize
	ELSIF rising_edge(clk) THEN
		int_sync <= sync_reg;
		sync_reg := ext_int;
	END IF;
END PROCESS synchronize_int;

int_use <= int_sync WHEN synchronize ELSE ext_int;

----------------------------------------------------------------------------
--  reg_access Process
----------------------------------------------------------------------------
reg_access : PROCESS(clk, res_n)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		ena_reg <= (OTHERS => '0');
		dout <= (OTHERS => '0');
	ELSIF rising_edge(clk) THEN
		IF cs = '1' THEN
			-- Write Access
			IF wr = '1' AND adr = '1' THEN							-- ENA (TRIG is implemented in "detect_int"
				ena_reg <= din(3 DOWNTO 0);		
			-- Read Access
			ELSIF rd = '1' THEN
				dout <= (OTHERS => '0');
				CASE adr IS
					WHEN '0' => dout(3 DOWNTO 0) <= trig_reg;		-- TRIG
									dout(7) <= int_use;
					WHEN '1'	=>	dout(3 DOWNTO 0) <= ena_reg;		-- ENA
					WHEN OTHERS => NULL;
				END CASE;
			END IF;
		END IF;
	END IF;
END PROCESS reg_access;

----------------------------------------------------------------------------
--  detect_int Process
----------------------------------------------------------------------------
detect_int : PROCESS(clk, res_n)
	VARIABLE last_int : std_logic;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		trig_reg <= (OTHERS => '0');
		last_int := '0';
		int <= '0';
	ELSIF rising_edge(clk) THEN
		-- Write Access
		IF wr = '1' AND cs = '1' AND adr = '0' THEN
			trig_reg <= trig_reg AND din(3 DOWNTO 0);
		-- Detect Interrupt
		ELSE
			trig_reg(RISEBIT) <= trig_reg(RISEBIT) OR (NOT(last_int) AND int_use);
			trig_reg(FALLBIT) <= trig_reg(FALLBIT) OR (last_int AND NOT(int_use));
			trig_reg(HIGHBIT) <= trig_reg(HIGHBIT) OR int_use;
			trig_reg(LOWBIT)	<= trig_reg(LOWBIT) OR NOT(int_use);
		END IF;
		last_int := int_use;
		
		-- Generate CPU Interrupt
		int <= '0';
		FOR i IN 0 TO 3 LOOP
			IF (trig_reg(i) AND ena_reg(i)) = '1' THEN
				int <= '1';
			END IF;
		END LOOP;
		
	END IF;
END PROCESS detect_int;



END ARCHITECTURE rtl;
