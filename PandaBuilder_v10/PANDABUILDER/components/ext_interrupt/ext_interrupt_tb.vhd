--**************************************************************************
--* FILE      :   ext_interrupt_tb.vhd	                          	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       22.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* Testbench for ext_interrupt.vhd														*
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
ENTITY ext_interrupt_tb IS
END ENTITY ext_interrupt_tb;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF ext_interrupt_tb IS
	SIGNAL clk, res_n, cs, wr, rd, int, adr, ext_int : std_logic;
	SIGNAL din, dout : std_logic_vector(7 DOWNTO 0);
	
	PROCEDURE write_reg(	CONSTANT reg	: IN	std_logic;
								CONSTANT val	: IN	std_logic_vector(7 DOWNTO 0);
								SIGNAL 	adr	: OUT	std_logic;
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
	
	PROCEDURE read_reg(	CONSTANT reg	: IN	std_logic;
								CONSTANT val	: IN	std_logic_vector(7 DOWNTO 0);
								SIGNAL 	adr	: OUT	std_logic;
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
	
	CONSTANT TRIG_REG : std_logic := '0';
	CONSTANT ENA_REG : std_logic := '1';
	
BEGIN

I1 : entity work.ext_interrupt
GENERIC MAP (
	synchronize => true
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
	ext_int => ext_int
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
	ext_int <= '0';
	-- Wait for Reset
	WAIT FOR 800 ns;
	
	-- Test Read Trig
	ASSERT false REPORT "Test Read Trig" SEVERITY note;
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(TRIG_REG, X"08", adr, cs, rd, dout);
	
	-- Test Write Ena-Reg, no Interrupt
	ASSERT false REPORT "Test Write Ena-Reg no Interrupt" SEVERITY note;
	write_reg(ENA_REG, X"01", adr, cs, wr, din);
	WAIT FOR 500 ns;
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	
	-- Test Write Ena-Reg, Interrupt
	ASSERT false REPORT "Test Write Ena-Reg, Interrupt" SEVERITY note;
	write_reg(ENA_REG, X"09", adr, cs, wr, din);
	ASSERT int = '1' REPORT "Interrupt was not Triggered" SEVERITY error;
	
	-- Test Read Ena Reg
	ASSERT false REPORT "Test read Ena Reg" SEVERITY note;
	read_reg(ENA_REG, X"09", adr, cs, rd, dout);
	
	-- Test Write Trig to clear Interrupt
	ASSERT false REPORT "Test Clear Interrupt" SEVERITY note;
	ext_int <= '1';
	WAIT FOR 500 ns;
	write_reg(TRIG_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	
	-- Test Read state and High
	ASSERT false REPORT "Test Read state and High" SEVERITY note;
	read_reg(TRIG_REG, X"84", adr, cs, rd, dout);
	write_reg(TRIG_REG, X"00", adr, cs, wr, din);
	read_reg(TRIG_REG, X"84", adr, cs, rd, dout);
	
	-- Test Falling edge and Low
	ASSERT false REPORT "Test Falling edge and Low" SEVERITY note;
	ext_int <= '0';
	WAIT FOR 500 ns;
	read_reg(TRIG_REG, X"0E", adr, cs, rd, dout);
	write_reg(TRIG_REG, X"01", adr, cs, wr, din);
	read_reg(TRIG_REG, X"08", adr, cs, rd, dout);
	
	-- Test Rising edge and High
	ASSERT false REPORT "Test Rising edge and High" SEVERITY note;
	ext_int <= '1';
	WAIT FOR 500 ns;
	read_reg(TRIG_REG, X"8D", adr, cs, rd, dout);
	write_reg(TRIG_REG, X"02", adr, cs, wr, din);
	read_reg(TRIG_REG, X"84", adr, cs, rd, dout);
	
	-- Test ENA bits
	ASSERT false REPORT "Test Ena Bits" SEVERITY note;
	ext_int <= '0';
	WAIT FOR 500 ns;
	ext_int <= '1';
	WAIT FOR 500 ns;
	write_reg(ENA_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	write_reg(ENA_REG, X"01", adr, cs, wr, din);
	ASSERT int = '1' REPORT "Interrupt was not triggered" SEVERITY error;
	write_reg(ENA_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	write_reg(ENA_REG, X"02", adr, cs, wr, din);
	ASSERT int = '1' REPORT "Interrupt was not triggered" SEVERITY error;
	write_reg(ENA_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	write_reg(ENA_REG, X"04", adr, cs, wr, din);
	ASSERT int = '1' REPORT "Interrupt was not triggered" SEVERITY error;
	write_reg(ENA_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	write_reg(ENA_REG, X"08", adr, cs, wr, din);
	ASSERT int = '1' REPORT "Interrupt was not triggered" SEVERITY error;
	write_reg(ENA_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	write_reg(ENA_REG, X"F0", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected INterrupt" SEVERITY error;
	
	ASSERT false REPORT "Test ended" SEVERITY note;
	
	WAIT;
	
END PROCESS;

END ARCHITECTURE rtl;
