--**************************************************************************
--* FILE      :   pwm_port.vhd			                            	  		*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       23.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is a PWM modulated output. Its modulation frequency and		*
--* resolutions in bits can be configured trough generics.						*
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
ENTITY pwm_port IS
	GENERIC (
		clk_frequency	: integer := 10000000;
		pwm_frequency	: integer := 10000;
		pwm_res_bits	: integer := 8
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		-- *** External Ports ***
		pwm				: OUT	std_logic
	);
END ENTITY pwm_port;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF pwm_port IS
	SIGNAL value_reg	: std_logic_vector((pwm_res_bits-1) DOWNTO 0);			-- BASE + 0x00 = VALUE 	R/W			
BEGIN

----------------------------------------------------------------------------
--  modulation Process
----------------------------------------------------------------------------
modulation : PROCESS(clk, res_n)
	CONSTANT MAXCOUNT_PRES	: integer := (((10*clk_frequency)/(((2**pwm_res_bits)-1)*pwm_frequency))-5)/10;
	VARIABLE prescaler		: integer RANGE 0 TO MAXCOUNT_PRES;
	CONSTANT MAXCOUNT_PWM	: integer := (2**pwm_res_bits)-2;
	VARIABLE pwm_count		: integer RANGE 0 TO MAXCOUNT_PWM;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		prescaler := 0;
		pwm_count := 0;
		pwm <= '0';
	ELSIF rising_edge(clk) THEN
		-- Prescaler and PWM Counter
		IF prescaler = MAXCOUNT_PRES THEN
			prescaler := 0;
			IF pwm_count = MAXCOUNT_PWM THEN
				pwm_count := 0;
			ELSE
				pwm_count := pwm_count + 1;
			END IF;
		ELSE
			prescaler := prescaler + 1;
		END IF;
		
		-- PWM Output
		IF pwm_count = unsigned(value_reg) THEN
			pwm <= '0';
		ELSIF pwm_count = 0 THEN
			pwm <= '1';
		END IF;			
	END IF;
END PROCESS modulation;

----------------------------------------------------------------------------
--  write_reg Process
----------------------------------------------------------------------------
write_reg : PROCESS(clk, res_n)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		value_reg <= (OTHERS => '0');
	ELSIF rising_edge(clk) THEN
		-- Write Access
		IF cs = '1' THEN
			IF wr = '1' THEN										
				value_reg <= din((pwm_res_bits-1) DOWNTO 0);
			END IF;
		END IF;
	END IF;
END PROCESS write_reg;

----------------------------------------------------------------------------
--  read_reg Process
----------------------------------------------------------------------------
read_reg : PROCESS(value_reg)
BEGIN
	dout <= (OTHERS => '0');
	dout((pwm_res_bits-1) DOWNTO 0) <= value_reg;
END PROCESS read_reg;

END ARCHITECTURE rtl;
