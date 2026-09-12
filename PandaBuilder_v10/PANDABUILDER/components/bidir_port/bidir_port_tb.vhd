--**************************************************************************
--* FILE      :   bidir_port_tb.vhd		                          	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       22.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* Testbench for Bidirectional Port of Panda Builder.							*
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
ENTITY bidir_port_tb IS
	GENERIC (
		synchronize		: boolean := true
	);
END ENTITY bidir_port_tb;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF bidir_port_tb IS
	SIGNAL	clk, res_n, cs, wr, rd : std_logic;
	SIGNAL 	din, dout, dout_res : std_logic_vector(7 DOWNTO 0);
	SIGNAL 	adr : std_logic_vector(1 DOWNTO 0);
	SIGNAL 	pio, pio_res : std_logic_vector(4 DOWNTO 0);
	

		
BEGIN		

pio_res <= To_X01(pio);				
dout_res <= To_X01(dout);																		

I1 : entity work.bidir_port
GENERIC MAP (
	port_width => 5,
	synchronize => synchronize
)
PORT MAP (
	clk => clk,
	res_n => res_n,
	cs => cs,
	wr => wr,
	rd => rd,
	din => din,
	dout => dout,
	adr => adr,
	pio => pio
);

do_clk : PROCESS
BEGIN
	clk <= '0';
	WAIT FOR 50 ns;
	clk <= '1';
	WAIT FOR 50 ns;
END PROCESS;

do_res : PROCESS
BEGIN
	res_n <= '0';
	WAIT FOR 200 ns;
	res_n <= '1';
	WAIT;
END PROCESS;

do_test : PROCESS
	VARIABLE res : std_logic_vector(4 DOWNTO 0);
BEGIN
	-- Test Reset High Z
	WAIT FOR 500 ns;
	ASSERT pio = "UUUUU" REPORT "Error 1" SEVERITY error;
	-- Test no Write when cs = '0'
	adr <= "10";
	wr <= '1';
	din <= "10000111";
	WAIT FOR 100 ns;
	wr <= '0';
	WAIT FOR 400 ns;
	ASSERT pio = "UUUUU" REPORT "Error 2" SEVERITY error;
	-- Test External Input to High Z
	pio <= "HHHLL";
	WAIT FOR 500 ns;
	ASSERT pio_res = "11100" REPORT "Error 3" SEVERITY error;
	-- Test write to TRIS
	wr <= '1';
	cs <= '1';
	WAIT FOR 100 ns;
	wr <= '0';
	WAIT FOR 400 ns;
	ASSERT pio_res = "00100" REPORT "Error 4" SEVERITY error;
	-- Test write to POUT
	adr <= "00";
	wr <= '1';
	din <= "00010101";
	WAIT FOR 100 ns;
	wr <= '0';
	cs <= '0';
	WAIT FOR 400 ns;
	ASSERT pio_res = "10100" REPORT "Error 5" SEVERITY error;
	-- Test read from PIN
	adr <= "01";
	rd <= '1';
	cs <= '1';
	WAIT FOR 100 ns;
	rd <= '0';
	cs <= '0';
	WAIT FOR 400 ns;
	ASSERT dout_res = "00010100" REPORT "Error 6" SEVERITY error;
	-- Test read from POUT
	adr <= "00";
	rd <= '1';
	cs <= '1';
	WAIT FOR 100 ns;
	rd <= '0';
	cs <= '0';
	WAIT FOR 400 ns;
	ASSERT dout_res = "00010101" REPORT "Error 7" SEVERITY error;
	-- Test read from TRIS
	adr <= "10";
	rd <= '1';
	cs <= '1';
	WAIT FOR 100 ns;
	rd <= '0';
	cs <= '0';
	WAIT FOR 400 ns;
	ASSERT dout_res = "00000111" REPORT "Error 8" SEVERITY error; 
	WAIT FOR 500 ns;
	WAIT;
END PROCESS;
	
	
	


END ARCHITECTURE rtl;
