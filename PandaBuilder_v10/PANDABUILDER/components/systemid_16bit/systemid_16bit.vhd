--**************************************************************************
--* FILE      :   systemid_16bit.vhd	                          	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       26.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                         	*
--* This block is a systemID. It contains only two read-only HW-registers	*
--* which hold a generic defined number. This component can be used to 		*
--* read out the Hardware Version in the Software.									*
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
ENTITY systemid_16bit IS
	GENERIC (
		id_highbyte		: integer := 1;
		id_lowbyte		: integer := 0
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		adr				: IN	std_logic;
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic
	);
END ENTITY systemid_16bit;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF systemid_16bit IS
	CONSTANT LOW_REG	:	std_logic := '0';												-- BASE + 0x00 = LOW		R
	CONSTANT	HIGH_REG	:	std_logic := '1';												-- BASE + 0x01 = HIGH 	R
BEGIN

----------------------------------------------------------------------------
--  read_id Process
----------------------------------------------------------------------------
read_id : PROCESS(clk, res_n)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		dout <= (OTHERS => '0');
	-- Read ID
	ELSIF rising_edge(clk) THEN
		IF adr = LOW_REG THEN
			dout <= std_logic_vector(to_unsigned(id_lowbyte, 8));
		ELSE
			dout <= std_logic_vector(to_unsigned(id_highbyte, 8));
		END IF;
	END IF;
END PROCESS read_id;

END ARCHITECTURE rtl;
