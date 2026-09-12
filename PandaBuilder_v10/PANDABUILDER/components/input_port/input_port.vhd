--**************************************************************************
--* FILE      :   input_port.vhd		                            	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       21.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is a simple input port. The port width is configurable		*
--* through a generic. Another generic defines wether the input data 		*
--* be synchronized or not.																*
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
ENTITY input_port IS
	GENERIC (
		port_width		: integer := 8;
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
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		-- *** External Ports ***
		pin				: IN	std_logic_vector((port_width-1) DOWNTO 0)
	);
END ENTITY input_port;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF input_port IS
	SIGNAL pin_sync : std_logic_vector((port_width-1) DOWNTO 0);	-- BASE + 0x00 = 	PIN R
BEGIN

----------------------------------------------------------------------------
--  synchronize_port Process
----------------------------------------------------------------------------
synchronize_port : PROCESS(clk, res_n)
	VARIABLE sync_reg : std_logic_vector((port_width-1) DOWNTO 0);
BEGIN
	-- Reset
	IF res_n = '0' THEN
		sync_reg := (OTHERS => '0');
		pin_sync <= (OTHERS => '0');
	-- Synchronize
	ELSIF rising_edge(clk) THEN
		pin_sync <= sync_reg;
		sync_reg := pin;
	END IF;
END PROCESS synchronize_port;

----------------------------------------------------------------------------
--  read_port Process
----------------------------------------------------------------------------
read_port : PROCESS(pin_sync, pin)
BEGIN
	dout <= (OTHERS => '0');
	IF synchronize THEN
		dout((port_width-1) DOWNTO 0) <= pin_sync;
	ELSE
		dout((port_width-1) DOWNTO 0) <= pin;
	END IF;
END PROCESS read_port;


END ARCHITECTURE rtl;
