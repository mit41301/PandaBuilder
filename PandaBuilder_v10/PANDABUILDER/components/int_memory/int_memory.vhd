--**************************************************************************
--* FILE      :   int_memory.vhd		                            	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       24.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block implements a RAM with configurable address width.				*
--* The RAM is not initialized.															*
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
ENTITY int_memory IS
	GENERIC (
		address_width	: integer := 8
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		adr				: IN 	std_logic_vector((address_width-1) DOWNTO 0);
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic
	);
END ENTITY int_memory;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF int_memory IS
	TYPE 		ram_type IS ARRAY (((2**address_width)-1) DOWNTO 0) OF std_logic_vector(7 DOWNTO 0);
	SIGNAL	ram	: ram_type;
BEGIN

----------------------------------------------------------------------------
--  access_ram Process
----------------------------------------------------------------------------
access_ram : PROCESS(clk, ram, res_n)
BEGIN
	IF rising_edge(clk) THEN
		dout <= ram(to_integer(unsigned(adr)));
		IF wr = '1' AND cs = '1' THEN
			ram(to_integer(unsigned(adr))) <= din;
		END IF;
	END IF;
END PROCESS access_ram;


END ARCHITECTURE rtl;
