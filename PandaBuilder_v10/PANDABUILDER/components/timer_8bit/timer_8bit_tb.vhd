--**************************************************************************
--* FILE      :   timer_8bit_tb.vhd		                          	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       22.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* Testbench for tmr_8bit.vhd
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
ENTITY timer_8bit_tb IS
END ENTITY timer_8bit_tb;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF timer_8bit_tb IS
	SIGNAL clk, res_n, cs, wr, rd, int : std_logic;
	SIGNAL adr : std_logic_vector(1 DOWNTO 0);
	SIGNAL din, dout : std_logic_vector(7 DOWNTO 0);
	
	PROCEDURE write_reg(	CONSTANT reg	: IN	std_logic_vector(1 DOWNTO 0);
								CONSTANT val	: IN	std_logic_vector(7 DOWNTO 0);
								SIGNAL 	adr	: OUT	std_logic_vector(1 DOWNTO 0);
								SIGNAL 	cs		: OUT	std_logic;
								SIGNAL 	wr		: OUT	std_logic;
								SIGNAL 	din	: OUT	std_logic_vector(7 DOWNTO 0)) IS
	BEGIN
		cs <= '1';
		wr <= '1';
		din <= val;
		adr <= reg;
		WAIT FOR 100 ns;
		wr <= '0';
		WAIT FOR 100 ns;
		cs <= '0';	
	END PROCEDURE;
	
	PROCEDURE read_reg(	CONSTANT reg	: IN	std_logic_vector(1 DOWNTO 0);
								CONSTANT val	: IN	std_logic_vector(7 DOWNTO 0);
								SIGNAL 	adr	: OUT	std_logic_vector(1 DOWNTO 0);
								SIGNAL 	cs		: OUT	std_logic;
								SIGNAL 	rd		: OUT	std_logic;
								SIGNAL 	dout	: IN	std_logic_vector(7 DOWNTO 0)) IS
	BEGIN
		cs <= '1';
		rd <= '1';
		adr <= reg;
		WAIT FOR 100 ns;
		rd <= '0';
		WAIT FOR 100 ns;
		cs <= '0';	
		ASSERT val = dout REPORT "Read unexpected Value from Register" SEVERITY error;
	END PROCEDURE;
	
	CONSTANT TMR_REG : std_logic_vector(1 DOWNTO 0) := "00";
	CONSTANT RLD_REG : std_logic_vector(1 DOWNTO 0) := "01";
	CONSTANT CFG_REG : std_logic_vector(1 DOWNTO 0) := "10";
	CONSTANT UPDOWN : std_logic_vector(7 DOWNTO 0) := X"08";
	CONSTANT RELOAD : std_logic_vector(7 DOWNTO 0) := X"04";
	CONSTANT RUN : std_logic_vector(7 DOWNTO 0) := X"02";
	CONSTANT INTON : std_logic_vector(7 DOWNTO 0) := X"01";
	CONSTANT INT_REG : std_logic_vector(1 DOWNTO 0) := "11";
	
BEGIN

I1 : entity work.timer_8bit
GENERIC MAP (
	clk_frequency => 10000000,
	resolution_us => 5
)
PORT MAP (
	clk => clk,
	res_n => res_n,
	cs => cs,
	adr => adr,
	din => din,
	dout => dout,
	wr => wr,
	rd => rd,
	int => int
);

do_clk : PROCESS
BEGIN	
	clk <= '1';
	WAIT FOR 50 ns;
	clk <= '0';
	WAIT FOR 50 ns;
END PROCESS do_clk;

do_res_n : PROCESS
BEGIN
	res_n <= '0';
	WAIT FOR 200 ns;
	res_n <= '1';
	WAIT;
END PROCESS;

do_test : PROCESS
BEGIN
	-- Wait for Reset
	WAIT FOR 500 ns;
	
	-- Test Timer Stopped
	ASSERT false REPORT "Test Timer Stopped" SEVERITY note;
	write_reg(CFG_REG, UPDOWN, adr, cs, wr, din);
	WAIT FOR 5.5 us;
	read_reg(TMR_REG, X"00", adr, cs, rd, dout);
	
	-- Test Correct Resolution
	ASSERT false REPORT "Test Correct Resolution" SEVERITY note;
	write_reg(CFG_REG, (UPDOWN OR RUN), adr, cs, wr, din);
	WAIT FOR 20.5 us;
	read_reg(TMR_REG, X"04", adr, cs, rd, dout);
	
	-- Test Overflow without Interrupt
	ASSERT false REPORT "Test Overflow without Interrupt, without Reload" SEVERITY note;
	write_reg(CFG_REG, X"00", adr, cs, wr, din);
	write_reg(TMR_REG, X"02", adr, cs, wr, din);
	write_reg(CFG_REG, RUN, adr, cs, wr, din);
	WAIT FOR 15.5 us;
	ASSERT int = '0' REPORT "Unexpected Interrupt" SEVERITY error;
	read_reg(TMR_REG, X"FF", adr, cs, rd, dout);
	read_reg(INT_REG, X"01", adr, cs, rd, dout);
	
	-- Test Clear Interrupt
	ASSERT false REPORT "Test Interrupt Clear" SEVERITY note;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Test Auto Relaod and Interrupt
	ASSERT false REPORT "Test Interrupt and Auto Reload" SEVERITY note;
	write_reg(RLD_REG, X"03", adr, cs, wr, din);
	write_reg(CFG_REG, (RELOAD OR RUN OR INTON), adr, cs, wr, din);
	write_reg(TMR_REG, X"02", adr, cs, wr, din);
	WAIT FOR 15.5 us;
	ASSERT int = '1' REPORT "Interrupt was not triggered" SEVERITY error;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "Interrupt was not cleared" SEVERITY error;
	WAIT FOR 19 us;
	ASSERT int = '0' REPORT "Unexpected Interrupt" SEVERITY error;
	WAIT FOR 1.5 us;
	ASSERT int = '1' REPORT "Interrupt was not triggered" SEVERITY error;
	WAIT;
	
END PROCESS;

END ARCHITECTURE rtl;
