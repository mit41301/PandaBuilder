--**************************************************************************
--* FILE      :   fifo_8bit_tb.vhd		                          	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       26.01.2009  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* Testbench for fifo_8bit.vhd
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
ENTITY fifo_8bit_tb IS
END ENTITY fifo_8bit_tb;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF fifo_8bit_tb IS
	SIGNAL clk, res_n, cs, wr, rd : std_logic := '0';
	SIGNAL adr : std_logic_vector(1 DOWNTO 0) := "00";
	SIGNAL din, dout : std_logic_vector(7 DOWNTO 0) := "00000000";
	SIGNAL end_sim : boolean := false;
	
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
	
	CONSTANT DAT_REG : std_logic_vector(1 DOWNTO 0) := "00";
	CONSTANT SEL_REG : std_logic_vector(1 DOWNTO 0) := "01";
	CONSTANT STATUS_REG : std_logic_vector(1 DOWNTO 0) := "10";
	CONSTANT FULL : std_logic_vector(7 DOWNTO 0) := X"01";
	CONSTANT EMPTY : std_logic_vector(7 DOWNTO 0) := X"02";
BEGIN

I1 : entity work.fifo_8bit
GENERIC MAP (
	num_of_fifos => 2,
	size_of_fifos => 4
)
PORT MAP (
	clk => clk,
	res_n => res_n,
	cs => cs,
	adr => adr,
	din => din,
	dout => dout,
	wr => wr,
	rd => rd
);

do_clk : PROCESS
BEGIN	
	clk <= '1';
	WAIT FOR 50 ns;
	clk <= '0';
	WAIT FOR 50 ns;
	IF end_sim THEN
		WAIT;
	END IF;
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
	
	-- Test FIFO function
	ASSERT false REPORT "Test FIFO function" SEVERITY NOTE;
	read_reg(STATUS_REG, X"02", adr, cs, rd, dout);
	write_reg(DAT_REG, X"01", adr, cs, wr, din); 
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	write_reg(DAT_REG, X"02", adr, cs, wr, din);
	write_reg(DAT_REG, X"03", adr, cs, wr, din);
	write_reg(DAT_REG, X"04", adr, cs, wr, din);
	write_reg(DAT_REG, X"05", adr, cs, wr, din);
	read_reg(STATUS_REG, X"01", adr, cs, rd, dout);
	read_reg(DAT_REG, X"01", adr, cs, rd, dout);
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	read_reg(DAT_REG, X"02", adr, cs, rd, dout);
	read_reg(DAT_REG, X"03", adr, cs, rd, dout);
	read_reg(DAT_REG, X"04", adr, cs, rd, dout);
	read_reg(STATUS_REG, X"02", adr, cs, rd, dout);
	read_reg(DAT_REG, X"01", adr, cs, rd, dout);
	read_reg(DAT_REG, X"01", adr, cs, rd, dout);
	
	-- Test Selection
	ASSERT false REPORT "TEST FIFO selection" SEVERITY NOTE;
	--write
	write_reg(SEL_REG, X"01", adr, cs, wr, din);
	read_reg(STATUS_REG, X"02", adr, cs, rd, dout);
	write_reg(DAT_REG, X"01", adr, cs, wr, din); 
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	write_reg(SEL_REG, X"02", adr, cs, wr, din);
	read_reg(STATUS_REG, X"02", adr, cs, rd, dout);
	write_reg(DAT_REG, X"02", adr, cs, wr, din); 
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	write_reg(SEL_REG, X"01", adr, cs, wr, din);
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	write_reg(DAT_REG, X"03", adr, cs, wr, din); 
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	write_reg(SEL_REG, X"02", adr, cs, wr, din);
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	write_reg(DAT_REG, X"04", adr, cs, wr, din); 
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	--read
	write_reg(SEL_REG, X"01", adr, cs, wr, din);
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	read_reg(DAT_REG, X"01", adr, cs, rd, dout); 
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	write_reg(SEL_REG, X"02", adr, cs, wr, din);
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	read_reg(DAT_REG, X"02", adr, cs, rd, dout); 
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	write_reg(SEL_REG, X"01", adr, cs, wr, din);
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	read_reg(DAT_REG, X"03", adr, cs, rd, dout); 
	read_reg(STATUS_REG, X"02", adr, cs, rd, dout);
	write_reg(SEL_REG, X"02", adr, cs, wr, din);
	read_reg(STATUS_REG, X"00", adr, cs, rd, dout);
	read_reg(DAT_REG, X"04", adr, cs, rd, dout); 
	read_reg(STATUS_REG, X"02", adr, cs, rd, dout);
	end_sim <= true;
	WAIT;
	
END PROCESS;

END ARCHITECTURE rtl;
