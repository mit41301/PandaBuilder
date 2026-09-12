--**************************************************************************
--* FILE      :   output_port.vhd		                            	  		*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       21.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is a simple output port. The port width is configurable		*
--* through a generic.																		*
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
ENTITY output_port IS
	GENERIC (
		port_width		: integer := 8
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
		pout				: OUT	std_logic_vector((port_width-1) DOWNTO 0)
	);
END ENTITY output_port;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF output_port IS
	SIGNAL pout_reg : std_logic_vector((port_width-1) DOWNTO 0);				-- BASE + 0x00 = POUT 	R/W
BEGIN

----------------------------------------------------------------------------
--  write_port Process
----------------------------------------------------------------------------
write_port : PROCESS(clk, res_n)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		pout_reg <= (OTHERS => '0');
	ELSIF rising_edge(clk) THEN
		IF cs = '1' THEN
			-- Write to Port
			IF wr = '1' THEN
				pout_reg <= din((port_width-1) DOWNTO 0);
			END IF;
		END IF;
	END IF;
END PROCESS write_port;

-- Assign Output
pout <= pout_reg;

----------------------------------------------------------------------------
--  read_port Process
----------------------------------------------------------------------------
read_port : PROCESS(pout_reg)
BEGIN
	dout <= (OTHERS => '0');
	dout((port_width-1) DOWNTO 0) <= pout_reg;
END PROCESS read_port;

END ARCHITECTURE rtl;
