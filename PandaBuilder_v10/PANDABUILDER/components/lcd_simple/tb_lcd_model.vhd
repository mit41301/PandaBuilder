--**************************************************************************
--* FILE      :   tb_lcd_model.vhd		                            	  		*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       04.09.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block simulates an LCD for the testbench.									*
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
ENTITY tb_lcd_model IS
	PORT (
		-- *** External Ports ***
		rs					: IN std_logic;
		rw					: IN std_logic;
		en					: IN std_logic;
		dbus				: INOUT std_logic_vector(7 DOWNTO 0)
	);
END ENTITY tb_lcd_model;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF tb_lcd_model IS
	SIGNAL busy : std_logic := '0';
	SIGNAL dbus_del : std_logic_vector(7 DOWNTO 0);

BEGIN
dbus_del <= (7 => busy, OTHERS => '0') WHEN (rs = '0' AND rw = '1' AND en = '1') ELSE
				(OTHERS => 'Z') WHEN (rw = '0') ELSE
				(OTHERS => 'U');
					
dbus <= TRANSPORT dbus_del AFTER 100 ns;
        
----------------------------------------------------------------------------
--  check_dbus Process
----------------------------------------------------------------------------  
check_dbus : PROCESS(dbus)
BEGIN
	FOR i IN 0 TO 7 LOOP
		ASSERT dbus(i) /= 'X' REPORT "Collision on LCD databus" SEVERITY error;
	END LOOP;
END PROCESS check_dbus;		  

----------------------------------------------------------------------------
--  do_outp Process
----------------------------------------------------------------------------
do_outp : PROCESS(rs,rw,en,dbus)
BEGIN
	IF falling_edge(en) THEN
		IF rw = '0' THEN
			busy <= TRANSPORT '1', 
					  				'0' AFTER 10 us;
			IF rs = '0' THEN
				ASSERT false REPORT "Command written to LCD" SEVERITY note;
			ELSE
				ASSERT false REPORT "Data written to LCD" SEVERITY note;
			END IF;
		END IF;
	END IF;
END PROCESS do_outp;

----------------------------------------------------------------------------
--  Timing Assertions
----------------------------------------------------------------------------  
-- *** Enable Cycle ***
PROCESS
BEGIN
	WAIT UNTIL rising_edge(en);
	WAIT UNTIL rising_edge(en) FOR 1200 ns;
	ASSERT NOT(rising_edge(en)) REPORT "Enable Cycle Time Violation" SEVERITY error;
END PROCESS;

-- *** Enable Puse Width ***
PROCESS
BEGIN
	WAIT UNTIL en = '1';
	WAIT UNTIL en = '0' FOR 460 ns;
	ASSERT en = '1' REPORT "Enable Pulse Width Violation" SEVERITY error;
END PROCESS;

-- *** Address Hold time ***
PROCESS
BEGIN
	WAIT UNTIL falling_edge(en);
	WAIT UNTIL rw'event OR rs'event FOR 10 ns;
	ASSERT NOT(rw'event OR rs'event) REPORT "Address Hold Time Violation" SEVERITY error;
END PROCESS;

-- *** Data Setup Time ***
PROCESS
BEGIN
	WAIT UNTIL falling_edge(en);
	ASSERT dbus'last_event > 80 ns REPORT "Data Setup Time Violation" SEVERITY error;
END PROCESS;

-- *** Data Hold Time
PROCESS
BEGIN
	WAIT UNTIL falling_edge(en);
	WAIT UNTIL dbus'event FOR 10 ns;
	ASSERT NOT(dbus'event) REPORT "Data Hold Time Violation" SEVERITY error;
END PROCESS;		


END ARCHITECTURE rtl;
