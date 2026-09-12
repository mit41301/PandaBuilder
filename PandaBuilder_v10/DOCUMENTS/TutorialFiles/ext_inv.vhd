--**************************************************************************
--* FILE      :   ext_inv.vhd		                            	  				*
--* PROJECT   :   PandaBuilder Tutorial             							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       30.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*			
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
ENTITY ext_inv IS
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		din				: IN	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		-- *** External Ports ***
		sig_in			: IN	std_logic_vector(3 DOWNTO 0);
		sig_out			: OUT	std_logic_vector(3 DOWNTO 0)
	);
END ENTITY ext_inv;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF ext_inv IS
	SIGNAL inv_en : std_logic;																-- BASE + 0x00 = EN 		W
BEGIN

----------------------------------------------------------------------------
--  write_en Process
----------------------------------------------------------------------------
write_en : PROCESS(clk, res_n)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		inv_en <= '0';
	ELSIF rising_edge(clk) THEN
		IF cs = '1' THEN
			-- Write to Port
			IF wr = '1' THEN
				inv_en <= din(0);
			END IF;
		END IF;
	END IF;
END PROCESS write_en;

-- Assign Output
sig_out <= 	sig_in WHEN inv_en = '0' ELSE NOT(sig_in); 
			

END ARCHITECTURE rtl;
