--**************************************************************************
--* FILE      :   bidir_port.vhd		                            	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       21.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is a simple bidirectional port. The port width is 				*
--* configurable through a generic. Another generic defines wether the     *
--* input data should be synchronized or not.										*
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
ENTITY bidir_port IS
	GENERIC (
		port_width		: integer := 8;
		synchronize		: boolean := true
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***t
		cs					: IN	std_logic;
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		adr				: IN  std_logic_vector(1 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		-- *** External Ports ***
		pio				: INOUT	std_logic_vector((port_width-1) DOWNTO 0)
	);
END ENTITY bidir_port;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF bidir_port IS	
	SIGNAL	port_reg,																		-- BASE + 0x00 = POUT	R/W
																									-- BASE + 0x01 = PIN		R
				tris_reg : std_logic_vector((port_width-1) DOWNTO 0);				-- BASE + 0x02 = TRIS	R/W
	SIGNAL 	sync_reg : std_logic_vector((port_width-1) DOWNTO 0); 
BEGIN																									

----------------------------------------------------------------------------
--  write_port Process
----------------------------------------------------------------------------
write_port : PROCESS(clk, res_n)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		tris_reg <= (OTHERS => '1');
		sync_reg <= (OTHERS => '0');
		port_reg <= (OTHERS => '0');
		dout <= (OTHERS => '0');
	ELSIF rising_edge(clk) THEN
		IF cs = '1' THEN
			-- Write Registers
			IF wr = '1' THEN
				CASE adr IS
					WHEN "00" => 	port_reg <= din((port_width-1) DOWNTO 0); 	-- PORT
					WHEN "10" => 	tris_reg <= din((port_width-1) DOWNTO 0); 	-- TRIS
					WHEN OTHERS => NULL;
				END CASE;
			END IF;
			-- Read Registers
			dout <= (OTHERS => '0');
			CASE adr IS
				WHEN "00" => 	dout((port_width-1) DOWNTO 0) <= port_reg;		-- PORT
				WHEN "01" =>	IF synchronize THEN										-- PIN
										dout((port_width-1) DOWNTO 0) <= sync_reg;
									ELSE
										dout((port_width-1) DOWNTO 0) <= pio;
									END IF;	
				WHEN "10" =>	dout((port_width-1) DOWNTO 0) <= tris_reg;		-- TRIS
				WHEN OTHERS => dout((port_width-1) DOWNTO 0) <= (OTHERS => 'X');
			END CASE;
		END IF;
		-- Synchronize
		sync_reg <= pio;
	END IF;
END PROCESS write_port;

----------------------------------------------------------------------------
--  set_pio Process
----------------------------------------------------------------------------
set_pio : PROCESS(port_reg, tris_reg)
BEGIN
	FOR i IN 0 TO port_width-1 LOOP
		IF tris_reg(i) = '1' THEN
			pio(i) <= 'Z';
		ELSE
			pio(i) <= port_reg(i);
		END IF;
	END LOOP;
END PROCESS set_pio;


END ARCHITECTURE rtl;
