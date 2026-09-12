--**************************************************************************
--* FILE      :   fifo_8bit.vhd		                            	  			*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       26.01.2009  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block implements multiple 8-bit fifos. Number and Size of the    	*
--* FIFOs is changable through generics.											   *
--*																								*
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
ENTITY fifo_8bit IS
	GENERIC (
		num_of_fifos 	: integer := 3;		-- Number of FIFOs = 2^num_of_fifos (maximal 256 FIFOs)
		size_of_fifos	: integer := 64		-- Size of FIFOs
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		adr				: IN 	std_logic_vector(1 DOWNTO 0);
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic
	);
END ENTITY fifo_8bit;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF fifo_8bit IS															-- BASE + 0x00 = DAT		R/W
	SIGNAL 	sel_reg	: std_logic_vector(num_of_fifos-1 DOWNTO 0);				-- BASE + 0x01 = SEL		R/W
																									-- BASE + 0x02 = STATUS	R		[empty full]
	TYPE		st_type	IS ARRAY (2**num_of_fifos-1 DOWNTO 0) OF std_logic;
	SIGNAL	full		:	st_type;
	SIGNAL	empty		:	st_type;

	TYPE 		fifo_ram_type 	IS ARRAY ((2**num_of_fifos)*size_of_fifos -1 DOWNTO 0) OF std_logic_vector(7 DOWNTO 0);
	SIGNAL	fifo_ram			: fifo_ram_type;
	SIGNAL 	fifo_ram_raddr	: integer RANGE 0 TO (size_of_fifos * 2**num_of_fifos)-1;
	TYPE		waddr_type		IS ARRAY (2**num_of_fifos-1 DOWNTO 0) OF integer RANGE 0 TO size_of_fifos-1;
	SIGNAL	fifo_ram_waddr	: waddr_type;
	SIGNAL	fifo_ram_fill	: integer RANGE 0 TO size_of_fifos;
	SIGNAL	data_out			: std_logic_vector(7 DOWNTO 0);

BEGIN

----------------------------------------------------------------------------
--  communication Process
----------------------------------------------------------------------------
communication : PROCESS(clk, res_n)
BEGIN
	IF res_n = '0' THEN
		sel_reg <= (OTHERS => '0');
	ELSIF rising_edge(clk) THEN
		IF cs = '1' THEN
			IF wr = '1' THEN
				CASE adr IS
					WHEN "00" =>	NULL;														-- DAT (implemented in fifo_control)	
					WHEN "01" =>	sel_reg <= din(num_of_fifos-1 DOWNTO 0);		-- SEL
					WHEN "10" =>	NULL;														-- STATUS (read only)
					WHEN OTHERS => NULL;
				END CASE;
			ELSIF rd = '1' THEN
				CASE adr IS
					WHEN "00" =>	dout <= data_out;														-- DAT
					WHEN "01" =>	dout(num_of_fifos-1 DOWNTO 0) <= sel_reg;						-- SEL
					WHEN "10" => 	dout <= (0 => full(to_integer(unsigned(sel_reg))),			-- STATUS
													1 => empty(to_integer(unsigned(sel_reg))),
													OTHERS => '0');
					WHEN OTHERS => dout <= (OTHERS => '0');
				END CASE;
			END IF;
		END IF;
	END IF;
END PROCESS communication;

----------------------------------------------------------------------------
--  FIFO Control
----------------------------------------------------------------------------
fifo_control : PROCESS(res_n, clk, sel_reg)
	TYPE ram_fill_type IS ARRAY (2**num_of_fifos-1 DOWNTO 0) OF integer RANGE 0 TO size_of_fifos;
	VARIABLE ram_fill_var : ram_fill_type;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		fifo_ram_waddr <= (OTHERS => 0);
		ram_fill_var := (OTHERS => 0);
		empty <= (OTHERS => '1');
		full <= (OTHERS => '0');
	ELSIF rising_edge(clk) THEN
		IF cs = '1' THEN
			IF adr = "00" THEN
				IF wr = '1' AND full(to_integer(unsigned(sel_reg))) = '0' THEN
					ram_fill_var(to_integer(unsigned(sel_reg))) := ram_fill_var(to_integer(unsigned(sel_reg)))+1;
					fifo_ram_waddr(to_integer(unsigned(sel_reg))) <= (fifo_ram_waddr(to_integer(unsigned(sel_reg)))+1) MOD size_of_fifos;
				ELSIF rd = '1' AND empty(to_integer(unsigned(sel_reg))) = '0' THEN
					ram_fill_var(to_integer(unsigned(sel_reg))) := ram_fill_var(to_integer(unsigned(sel_reg)))-1;
				END IF;
			END IF;
		END IF;
		-- Generate Status Signals
		IF ram_fill_var(to_integer(unsigned(sel_reg))) = 0 THEN empty(to_integer(unsigned(sel_reg))) <= '1'; ELSE empty(to_integer(unsigned(sel_reg))) <= '0'; END IF;
		IF ram_fill_var(to_integer(unsigned(sel_reg))) = size_of_fifos THEN full(to_integer(unsigned(sel_reg))) <= '1'; ELSE full(to_integer(unsigned(sel_reg))) <= '0'; END IF;
	END IF;
	fifo_ram_fill <= ram_fill_var(to_integer(unsigned(sel_reg)));
END PROCESS fifo_control;

-- Concurrent Signals
fifo_ram_raddr <= ((fifo_ram_waddr(to_integer(unsigned(sel_reg))) + size_of_fifos - fifo_ram_fill) MOD size_of_fifos) + size_of_fifos * to_integer(unsigned(sel_reg));


----------------------------------------------------------------------------
--  FIFO RAM
----------------------------------------------------------------------------
fifo_ram_pr : PROCESS(clk) 
BEGIN
 	IF rising_edge(clk) THEN
 		IF wr = '1' AND full(to_integer(unsigned(sel_reg))) = '0' THEN
 			fifo_ram(fifo_ram_waddr(to_integer(unsigned(sel_reg))) + size_of_fifos * to_integer(unsigned(sel_reg))) <= din;
 		END IF;
 		data_out <= fifo_ram(fifo_ram_raddr);
 	END IF;
END PROCESS fifo_ram_pr;

END ARCHITECTURE rtl;
