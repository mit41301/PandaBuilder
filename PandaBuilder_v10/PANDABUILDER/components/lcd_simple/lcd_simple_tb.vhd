--**************************************************************************
--* FILE      :   lcd_simple_tb.vhd		                       	  				*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       04.09.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* Testbench for lcd_simple.vhd															*
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
ENTITY lcd_simple_tb IS
END ENTITY lcd_simple_tb;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF lcd_simple_tb IS
	SIGNAL clk, res_n, cs, wr, rd, int : std_logic;
	SIGNAL adr : std_logic_vector(1 DOWNTO 0);
	SIGNAL din, dout : std_logic_vector(7 DOWNTO 0);
	SIGNAL rw, rs, en : std_logic;
	SIGNAL dbus : std_logic_vector(7 DOWNTO 0);
	
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
	
	CONSTANT INST_REG : std_logic_vector(1 DOWNTO 0) := "00";
	CONSTANT DATA_REG : std_logic_vector(1 DOWNTO 0) := "01";
	CONSTANT STATE_REG : std_logic_vector(1 DOWNTO 0) := "10";
	CONSTANT INT_REG	: std_logic_vector(1 DOWNTO 0) := "11";
	CONSTANT BUSY : std_logic_vector(7 DOWNTO 0) := X"02";
	CONSTANT INTON : std_logic_vector(7 DOWNTO 0) := X"01";
	
BEGIN

I1 : entity work.lcd_simple
GENERIC MAP (
	clk_frequency => 10000000
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
	int => int,
	rs => rs,
	rw => rw,
	en => en,
	dbus => dbus
);

I2 : entity work.tb_lcd_model
PORT MAP (
	rs => rs,
	rw => rw,
	en => en,
	dbus => dbus
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
	wr <= '0';
	rd <= '0';
	cs <= '0';
	-- Wait for Reset
	WAIT FOR 500 ns;
	
	-- Interrupt can not be set
	ASSERT false REPORT "*** Interrupt cannot be set ***" SEVERITY note;
	write_reg(INT_REG, X"FF", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Write Command without interrupt
	ASSERT false REPORT "*** Write Command without interrupt ***" SEVERITY note;
	write_reg(INST_REG, X"F0", adr, cs, wr, din);
	read_reg(STATE_REG, X"02", adr, cs, rd, dout);
	WAIT FOR 40 us;
	read_reg(STATE_REG, X"00", adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"01", adr, cs, rd, dout);
	
	-- Interrupt Clear
	ASSERT false REPORT "*** Interrupt clear ***" SEVERITY note;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Write Data without interrupt
	ASSERT false REPORT "*** Write Data without interrupt ***" SEVERITY note;
	write_reg(DATA_REG, X"0F", adr, cs, wr, din);
	read_reg(STATE_REG, X"02", adr, cs, rd, dout);
	WAIT FOR 40 us;
	read_reg(STATE_REG, X"00", adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"01", adr, cs, rd, dout);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Write Command with interrupt
	ASSERT false REPORT "*** Write Command with interrupt ***" SEVERITY note;
	write_reg(STATE_REG, X"01", adr, cs, wr, din);
	write_reg(INST_REG, X"F0", adr, cs, wr, din);
	read_reg(STATE_REG, X"03", adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	WAIT FOR 40 us;
	read_reg(STATE_REG, X"01", adr, cs, rd, dout);
	ASSERT int = '1' REPORT "Interrupt was not generated" SEVERITY error;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Write Data with interrupt
	ASSERT false REPORT "*** Write Data with interrupt ***" SEVERITY note;
	write_reg(DATA_REG, X"0F", adr, cs, wr, din);
	read_reg(STATE_REG, X"03", adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	WAIT FOR 40 us;
	read_reg(STATE_REG, X"01", adr, cs, rd, dout);
	ASSERT int = '1' REPORT "Interrupt was not generated" SEVERITY error;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	
	WAIT;
	
END PROCESS;

END ARCHITECTURE rtl;
