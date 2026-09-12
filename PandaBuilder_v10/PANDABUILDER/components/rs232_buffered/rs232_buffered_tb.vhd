--**************************************************************************
--* FILE      :   rs232_buffered_tb.vhd		                       	  		*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       07.09.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* Testbench for rs232_buffered.vhd													*
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
ENTITY rs232_buffered_tb IS
END ENTITY rs232_buffered_tb;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF rs232_buffered_tb IS
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
	CONSTANT RCHR_REG : std_logic_vector(1 DOWNTO 0) := "01";
	CONSTANT CFG_REG : std_logic_vector(1 DOWNTO 0) := "10";
	CONSTANT INT_REG : std_logic_vector(1 DOWNTO 0) := "11";
	CONSTANT SFUL : std_logic_vector(7 DOWNTO 0) := X"40";
	CONSTANT REMP : std_logic_vector(7 DOWNTO 0) := X"20";
	CONSTANT CHAR : std_logic_vector(7 DOWNTO 0) := X"10";
	CONSTANT SEMP : std_logic_vector(7 DOWNTO 0) := X"08";
	CONSTANT RFUL : std_logic_vector(7 DOWNTO 0) := X"04";
	CONSTANT REC : std_logic_vector(7 DOWNTO 0) := X"02";
	CONSTANT SND : std_logic_vector(7 DOWNTO 0) := X"01";
	
BEGIN

I1 : entity work.rs232_buffered
GENERIC MAP (
	clk_frequency => 10000000,
	baudrate => 115200,
	sndbuf_size => 4,
	recbuf_size => 4
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
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	
	-- Check RS-232 receive without interrupt
	ASSERT false REPORT "*** Receive without Interrupt ***" SEVERITY note;
	send_rs232(X"C5", rx);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, (REC OR SEMP), adr, cs, rd, dout);
	read_reg(DAT_REG, X"C5", adr, cs, rd, dout);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	
	-- Check RS-232 receive with interrupt (Clear interrupt via dataread)
	ASSERT false REPORT "*** Receive with Interrupt, Clear via read DAT ***" SEVERITY note;
	write_reg(CFG_REG, REC, adr, cs, wr, din);
	send_rs232(X"F0", rx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, (REC OR SEMP), adr, cs, rd, dout);
	read_reg(DAT_REG, X"F0", adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	
	-- Check RS-232 receive with interrupt (Clear interrupt via Interrupt write)
	ASSERT false REPORT "*** Receive with Interrupt, Clear via write INT ***" SEVERITY note;
	send_rs232(X"32", rx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, (REC OR SEMP), adr, cs, rd, dout);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	
	-- Check RS-232 send without interrupt
	ASSERT false REPORT "*** Send without Interrupt ***" SEVERITY note;
	write_reg(DAT_REG, X"C3", adr, cs, wr, din);
	read_reg(CFG_REG, REC, adr, cs, rd, dout);
	rec_rs232(X"C3", tx);
	read_reg(CFG_REG, REC, adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, (SND OR SEMP), adr, cs, rd, dout);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	
	-- Check RS-232 send with Interrupt (Clear via datawrite)
	ASSERT false REPORT "*** Send with Interrupt, Clear via write DAT ***" SEVERITY note;
	write_reg(CFG_REG, SND, adr, cs, wr, din);
	write_reg(DAT_REG, X"3C", adr, cs, wr, din);
	rec_rs232(X"3C", tx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	write_reg(DAT_REG, X"55", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	
	-- Check RS-232 send with Interrupt (Clear via Interrupt write)
	ASSERT false REPORT "*** Send with Interrupt, Clear via write INT ***" SEVERITY note;
	rec_rs232(X"55", tx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	
	-- Check clear only one interrupt
	ASSERT false REPORT "*** Cear only one Interrupt ***" SEVERITY note;
	write_reg(CFG_REG, (REC OR SND), adr, cs, wr, din);
	write_reg(DAT_REG, X"55", adr, cs, wr, din);
	send_rs232(X"CC", rx);
	WAIT FOR BAUD_TIME;
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, (REC OR SND OR SEMP), adr, cs, rd, dout);
	write_reg(INT_REG, REC, adr, cs, wr, din);
	read_reg(INT_REG, (REC OR SEMP), adr, cs, rd, dout);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	
	-- Check Receive until Full (without interrupt)
	ASSERT false REPORT "*** Receive until Full without Interrupt ***" SEVERITY note;
	read_reg(DAT_REG, X"32", adr, cs, rd, dout);
	read_reg(DAT_REG, X"CC", adr, cs, rd, dout);
	write_reg(CFG_REG, X"00", adr, cs, wr, din);
	read_reg(CFG_REG, REMP, adr, cs, rd, dout);
	send_rs232(X"C1", rx);
	read_reg(CFG_REG, X"00", adr, cs, rd, dout);
	send_rs232(X"C2", rx);
	send_rs232(X"C3", rx);
	send_rs232(X"C4", rx);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, (SEMP OR REC OR RFUL), adr, cs, rd, dout);
	send_rs232(X"C5", rx);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, (SEMP OR REC OR RFUL), adr, cs, rd, dout);
	read_reg(DAT_REG, X"C1", adr, cs, rd, dout);
	read_reg(INT_REG, (SEMP), adr, cs, rd, dout);
	read_reg(DAT_REG, X"C2", adr, cs, rd, dout);
	read_reg(CFG_REG, X"00", adr, cs, rd, dout);
	read_reg(DAT_REG, X"C3", adr, cs, rd, dout);
	read_reg(CFG_REG, X"00", adr, cs, rd, dout);
	read_reg(DAT_REG, X"C4", adr, cs, rd, dout);
	read_reg(CFG_REG, REMP, adr, cs, rd, dout);
	read_reg(DAT_REG, X"C1", adr, cs, rd, dout);
	read_reg(DAT_REG, X"C1", adr, cs, rd, dout);
	read_reg(CFG_REG, REMP, adr, cs, rd, dout);
	
	-- Check Receive until Full (interrupt)
	ASSERT false REPORT "*** Receive until Full with Interrupt ***" SEVERITY note;
	write_reg(CFG_REG, RFUL, adr, cs, wr, din);
	read_reg(CFG_REG, (REMP OR RFUL), adr, cs, rd, dout);
	send_rs232(X"C1", rx);
	read_reg(CFG_REG, RFUL, adr, cs, rd, dout);
	send_rs232(X"C2", rx);
	send_rs232(X"C3", rx);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	send_rs232(X"C4", rx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, (SEMP OR REC OR RFUL), adr, cs, rd, dout);
	send_rs232(X"C5", rx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, (SEMP OR REC OR RFUL), adr, cs, rd, dout);
	read_reg(DAT_REG, X"C1", adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, (SEMP), adr, cs, rd, dout);
	read_reg(DAT_REG, X"C2", adr, cs, rd, dout);
	read_reg(CFG_REG, RFUL, adr, cs, rd, dout);
	read_reg(DAT_REG, X"C3", adr, cs, rd, dout);
	read_reg(DAT_REG, X"C4", adr, cs, rd, dout);
	read_reg(CFG_REG, (REMP OR RFUL), adr, cs, rd, dout);
	read_reg(DAT_REG, X"C1", adr, cs, rd, dout);
	write_reg(CFG_REG, X"00", adr, cs, wr, din);
	read_reg(CFG_REG, REMP, adr, cs, rd, dout);
	
	-- Check Send until Empty (without interrupt)
	ASSERT false REPORT "*** Send until Empty without Interrupt ***" SEVERITY note;
	write_reg(CFG_REG, X"00", adr, cs, wr, din);
	read_reg(CFG_REG, REMP, adr, cs, rd, dout);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	write_reg(DAT_REG, X"A1", adr, cs, wr, din);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	read_reg(CFG_REG, REMP, adr, cs, rd, dout);
	write_reg(DAT_REG, X"A2", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	write_reg(DAT_REG, X"A3", adr, cs, wr, din);
	write_reg(DAT_REG, X"A4", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	read_reg(CFG_REG, REMP, adr, cs, rd, dout);
	write_reg(DAT_REG, X"A5", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	read_reg(CFG_REG, (REMP OR SFUL), adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	rec_rs232(X"A1", tx);
	read_reg(CFG_REG, REMP, adr, cs, rd, dout);
	rec_rs232(X"A2", tx);
	rec_rs232(X"A3", tx);
	rec_rs232(X"A4", tx);
	rec_rs232(X"A5", tx);
	read_reg(INT_REG, (SEMP OR SND), adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	
	-- Check Send until Empty (with interrupt)
	ASSERT false REPORT "*** Send until Empty with Interrupt ***" SEVERITY note;
	write_reg(CFG_REG, SEMP, adr, cs, wr, din);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(CFG_REG, (REMP OR SEMP), adr, cs, rd, dout);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	write_reg(DAT_REG, X"A1", adr, cs, wr, din);
	WAIT FOR 200 ns;
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	read_reg(CFG_REG, (REMP OR SEMP), adr, cs, rd, dout);
	write_reg(DAT_REG, X"A2", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	write_reg(DAT_REG, X"A3", adr, cs, wr, din);
	write_reg(DAT_REG, X"A4", adr, cs, wr, din);
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	read_reg(CFG_REG, (REMP OR SEMP), adr, cs, rd, dout);
	write_reg(DAT_REG, X"A5", adr, cs, wr, din);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, X"00", adr, cs, rd, dout);
	read_reg(CFG_REG, (REMP OR SFUL OR SEMP), adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	rec_rs232(X"A1", tx);
	read_reg(CFG_REG, (REMP OR SEMP), adr, cs, rd, dout);
	rec_rs232(X"A2", tx);
	rec_rs232(X"A3", tx);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	rec_rs232(X"A4", tx);	
	rec_rs232(X"A5", tx);
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, (SEMP OR SND), adr, cs, rd, dout);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	
	-- Check receive Char Interrupt
	ASSERT false REPORT "*** Receive Char Interrupt ***" SEVERITY note;
	write_reg(CFG_REG, X"10", adr, cs, wr, din);
	write_reg(INT_REG, X"00", adr, cs, wr, din);
	write_reg(RCHR_REG, X"D5", adr, cs, wr, din);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	read_reg(RCHR_REG, X"D5", adr, cs, rd, dout);
	send_rs232(X"C5", rx);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(INT_REG, (SEMP OR REC), adr, cs, rd, dout);
	send_rs232(X"D5", rx);	
	ASSERT int = '1' REPORT "no Interrupt triggered" SEVERITY error;
	read_reg(INT_REG, (SEMP OR CHAR OR REC), adr, cs, rd, dout);
	read_reg(DAT_REG, X"C5", adr, cs, rd, dout);
	read_reg(INT_REG, SEMP, adr, cs, rd, dout);
	ASSERT int = '0' REPORT "unexpected Interrupt" SEVERITY error;
	read_reg(DAT_REG, X"D5", adr, cs, rd, dout);
	
	ASSERT false REPORT "Test ended" SEVERITY note;
	WAIT;
	
END PROCESS;

END ARCHITECTURE rtl;
