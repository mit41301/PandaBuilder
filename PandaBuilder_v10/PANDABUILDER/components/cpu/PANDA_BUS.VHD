--*************************************************************************
--* FILE      :   panda_bus.vhd		                            	  		  *
--* PROJECT   :   Panda                      									  *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       28.04.2008  Bründler Oliver    File written              	  *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This block contains the bus unit of the Panda processor  				  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************


LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	USE ieee.numeric_std.all;
	
LIBRARY work;
	USE work.panda_pkg.all;
	
ENTITY panda_bus IS
	GENERIC (indir_on 		: boolean := true;
				user_stack_on	: boolean := false);
	PORT (-- Standard
			clk 				: IN	std_ulogic;					
			res_n				: IN 	std_ulogic;
			-- Interface to panda_ctrl
			operation 		: IN 	bus_ops;									
			do_op				: IN 	std_ulogic;
			data_ready		: IN 	std_ulogic;
			adr_int			: IN 	data_adr_t;			
			-- Interface to panda_alu
			akku_in			: IN 	data_t;																
			-- Databus
			data_adr			: OUT data_adr_t;
			wr					: OUT std_ulogic;
			rd					: OUT std_ulogic;
			-- Interface to panda_debugger
			stack_ptr_dbg 	: OUT data_adr_t;
			indir_adr_dbg	: OUT data_adr_t);
END ENTITY panda_bus;

ARCHITECTURE rtl OF panda_bus IS
	SIGNAL indir_adr : data_adr_t;  		-- Indirect Adress Register
	SIGNAL stack_ptr : data_adr_t;		-- Stackpointer
BEGIN
	
	stack_ptr_dbg <= stack_ptr;
	indir_adr_dbg <= indir_adr;
	
	-- Overadressing
	oa1 : IF (NOT indir_on) AND (NOT user_stack_on) GENERATE
		data_adr <= adr_int;
	END GENERATE oa1;
	oa2 : IF (NOT indir_on) AND user_stack_on GENERATE
		data_adr <= stack_ptr WHEN operation = push_i ELSE
						std_ulogic_vector(unsigned(stack_ptr) + 1) WHEN operation = pop_i ELSE
						adr_int;
	END GENERATE oa2;
	oa3 : IF indir_on AND (NOT user_stack_on) GENERATE
		data_adr <= indir_adr WHEN (operation = ldid_i OR operation = stid_i) ELSE
						adr_int;
	END GENERATE oa3;
	oa4 : IF indir_on AND user_stack_on GENERATE
		data_adr <= indir_adr WHEN (operation = ldid_i OR operation = stid_i) ELSE
						stack_ptr WHEN operation = push_i ELSE
						std_ulogic_vector(unsigned(stack_ptr) + 1) WHEN operation = pop_i ELSE
						adr_int;
	END GENERATE oa4;	
	
	
	-- Write Signal	
	wr1 : IF (NOT indir_on) AND (NOT user_stack_on) GENERATE
		wr <= do_op WHEN operation = st_i  ELSE
				'0';
	END GENERATE wr1;
	wr2 : IF (NOT indir_on) AND user_stack_on GENERATE
		wr <= do_op WHEN (operation = st_i OR operation = push_i) ELSE
				'0';
	END GENERATE wr2;
	wr3 : IF indir_on AND (NOT user_stack_on) GENERATE
		wr <= do_op WHEN (operation = st_i OR operation = stid_i) ELSE
				'0';
	END GENERATE wr3;
	wr4 : IF indir_on AND user_stack_on GENERATE
		wr <= do_op WHEN (operation = st_i OR operation = stid_i OR operation = push_i) ELSE
				'0';
	END GENERATE wr4;
	
	-- Read Signal	
	rd <= do_op WHEN mem_read_from_bus_op(operation, indir_on, user_stack_on) ELSE
			'0';	
	
	-- Manages the indirect Adress Pointer	
	reg : IF indir_on GENERATE			
		manage_indir_adr : PROCESS (clk, res_n)
		BEGIN
			IF res_n = '0' THEN
				indir_adr <= (OTHERS => '0');
			ELSIF rising_edge(clk) THEN
				IF data_ready = '1' THEN
					CASE operation IS
						WHEN ldid_i | stid_i	|
							  chidi_i			=> indir_adr <= std_ulogic_vector(unsigned(indir_adr) + unsigned(adr_int));
						WHEN sidl_i				=> IF data_adr_width >= data_width THEN
															indir_adr((data_width-1) mod data_adr_width DOWNTO 0) <= akku_in((data_width-1) mod data_adr_width DOWNTO 0);
														ELSE
															indir_adr((data_adr_width-1) mod data_width DOWNTO 0) <= akku_in((data_adr_width-1) mod data_width DOWNTO 0);
														END IF;
						WHEN sidh_i				=> IF data_adr_width > data_width THEN
															indir_adr((data_adr_width-1) DOWNTO data_width) <= akku_in((data_adr_width - data_width - 1) DOWNTO 0);
														END IF;
						WHEN sidi_i				=> indir_adr <= adr_int;
						WHEN spid_i				=> indir_adr <= stack_ptr;
						WHEN OTHERS				=> NULL;
					END CASE;
				END IF;
			END IF;
		END PROCESS manage_indir_adr;
	END GENERATE;	
	
	-- Manages the Stackpointer
	stack : IF user_stack_on GENERATE
		manage_stack_pointer : PROCESS (clk, res_n)
		BEGIN
			IF res_n = '0' THEN
				stack_ptr <= (OTHERS => '0');
			ELSIF rising_edge(clk) THEN
				IF data_ready = '1' THEN
					CASE operation IS
						WHEN sspi_i	=> stack_ptr <= adr_int;
						WHEN push_i	=> stack_ptr <= std_ulogic_vector(unsigned(stack_ptr) - 1);
						WHEN pop_i 	=> stack_ptr <= std_ulogic_vector(unsigned(stack_ptr) + 1);
						WHEN OTHERS	=> NULL;
					END CASE;
				END IF;
			END IF;
		END PROCESS manage_stack_pointer;
	END GENERATE stack;		
END ARCHITECTURE rtl;