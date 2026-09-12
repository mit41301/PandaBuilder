--**************************************************************************
--* FILE      :   rs232_simple_tb.vhd		                       	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       31.08.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* Testbench for rs232_simple.vhd														*
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
ENTITY rs232_simple_tb IS
END ENTITY rs232_simple_tb;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF rs232_simple_tb IS
	SIGNAL clk, res_n, cs, wr, rd, int : std_logic;
	SIGNAL adr : std_logic_vector(1 DOWNTO 0);
	SIGNAL din, dout : std_logic_vector(7 DOWNTO 0);
	SIGNAL rx, tx : std_logic;
	
	CONSTANT BAUD_TIME : time := (1 sec)/115200;
	
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
	
	PROCEDURE send_rs232(CONSTANT data	: IN	std_logic_vector(7 DOWNTO 0);
								SIGNAL 	tx		: OUT	std_logic) IS
	BEGIN
		tx <= '0';
		WAIT FOR BAUD_TIME;
		FOR i IN 0 TO 7 LOOP
			tx <= data(i);
			WAIT FOR BAUD_TIME;
		END LOOP;
		tx <= '1';
		WAIT FOR BAUD_TIME;
	END PROCEDURE;
	
	PROCEDURE rec_rs232(	CONSTANT expected	: IN	std_logic_vector(7 DOWNTO 0);
								SIGNAL 	rx			: IN	std_logic) IS
		VARIABLE data : std_logic_vector(7 DOWNTO 0);
	BEGIN
		IF rx = '1' THEN
			WAIT UNTIL rx = '0' FOR 10*BAUD_TIME;
			ASSERT rx = '0' REPORT "No Startbit detected" SEVERITY error;
		END IF;
		WAIT FOR BAUD_TIME/2;
		FOR i IN 0 TO 7 LOOP
			WAIT FOR BAUD_TIME;
			data(i) := rx;
		END LOOP;
		ASSERT data = expected REPORT "Received unexpected Data over RS232" SEVERITY error;
		WAIT FOR BAUD_TIME*1.5;
		ASSERT rx = '1' REPORT "Stop Bit not sent" SEVERITY error;
	END PROCEDURE;
	
	CONSTANT DAT_REG : std_logic_vector(1 DOWNTO 0) := "00";
	CONSTANT CFG_REG : std_logic_vector(1 DOWNTO 0) := "01";
	CONSTANT INT_REG : std_logic_vector(1 DOWNTO 0) := "10";
	CONSTANT BUSY : std_logic_vector(7 DOWNTO 0) := X"04";
	CONSTANT REC : std_logic_vector(7 DOWNTO 0) := X"02";
	CONSTANT SND : std_logic_vector(7 DOWNTO 0) := X"01";
	
BEGIN

I1 : entity work.rs232_simple
GENERIC MAP (
	clk_frequency => 10000000,
	baudrate => 115200
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
	rx => rx,
	tx => tx
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
	rx <= '1';
	wr <= '0';
	rd <= '0';
	cs <= '0';
	-- Wait for Reset
	WAIT FOR 500 ns;
	
	-- Interrupts can not be set
	ASSERT false REPORT "*** Interrupts cannot be set ***" SEVERITY note;
	write_reg(INT_REG, X"FF", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Check RS-232 receive without interrupt
	ASSERT false REPORT "*** Receive without Interrupt ***" SEVERITY note;
	send_rs232(X"C5", rx);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, REC, adr, cs, rd, dout);
	read_reg(DAT_REG, X"C5", adr, cs, rd, dout);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Check RS-232 receive with interrupt (Clear interrupt via dataread)
	ASSERT false REPORT "*** Receive with Interrupt, Clear via read DAT ***" SEVERITY note;
	write_reg(CFG_REG, REC, adr, cs, wr, din);
	send_rs232(X"F0", rx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, REC, adr, cs, rd, dout);
	read_reg(DAT_REG, X"F0", adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Check RS-232 receive with interrupt (Clear interrupt via Interrupt write)
	ASSERT false REPORT "*** Receive with Interrupt, Clear via write INT ***" SEVERITY note;
	send_rs232(X"32", rx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, REC, adr, cs, rd, dout);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Check RS-232 send without interrupt
	ASSERT false REPORT "*** Send without Interrupt ***" SEVERITY note;
	write_reg(DAT_REG, X"C3", adr, cs, wr, din);
	read_reg(CFG_REG, (REC OR BUSY), adr, cs, rd, dout);
	rec_rs232(X"C3", tx);
	read_reg(CFG_REG, REC, adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, SND, adr, cs, rd, dout);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Check RS-232 send with Interrupt (Clear via datawrite)
	ASSERT false REPORT "*** Send with Interrupt, Clear via write DAT ***" SEVERITY note;
	write_reg(CFG_REG, SND, adr, cs, wr, din);
	write_reg(DAT_REG, X"3C", adr, cs, wr, din);
	rec_rs232(X"3C", tx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	write_reg(DAT_REG, X"55", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	
	-- Check RS-232 send with Interrupt (Clear via Interrupt write)
	ASSERT false REPORT "*** Send with Interrupt, Clear via write INT ***" SEVERITY note;
	rec_rs232(X"55", tx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	
	-- Check clear only one interrupt
	ASSERT false REPORT "*** Cear only one Interrupt ***" SEVERITY note;
	write_reg(CFG_REG, (REC OR SND), adr, cs, wr, din);
	write_reg(DAT_REG, X"55", adr, cs, wr, din);
	send_rs232(X"CC", rx);
	WAIT FOR BAUD_TIME;
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, (REC OR SND), adr, cs, rd, dout);
	write_reg(INT_REG, REC, adr, cs, wr, din);
	read_reg(INT_REG, REC, adr, cs, rd, dout);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	
	WAIT;
	
END PROCESS;

END ARCHITECTURE rtl;
