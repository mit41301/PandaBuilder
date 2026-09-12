--*************************************************************************
--* FILE      :   panda_debug_control.vhd		                             *
--* PROJECT   :   Panda                      									  *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       28.04.2008  Bründler Oliver    File written              	  *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This block contains the control unit of the Panda debugger  			  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************


LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	USE ieee.numeric_std.all;
	
LIBRARY work;
	USE work.panda_pkg.all;
	USE work.ASCII_CODE.all;
	
ENTITY panda_debug_control IS
	GENERIC (interrupts_on	: boolean := true;	-- Interrupts On/Off
				indir_on 		: boolean := true;	-- Indirect Adressing On/Off
				mul_on			: boolean := false;	-- Multiplication On/Off
				mac_for_mul		: boolean := false;	-- MAC instead of Multiplication On/Off
				user_stack_on	: boolean := false);	-- User Stack On/Off 
	PORT( -- Standard
			clk 	: IN	std_ulogic;
			res_n	: IN	std_ulogic;
			-- Interface to VHDL_COMPORT
			send 		:  OUT  std_ulogic;
			busy 		:  IN std_ulogic;
			do_rdy 	:  IN std_ulogic;
			data_in 	:  IN  std_ulogic_vector(7 DOWNTO 0);		
			data_out :  OUT std_ulogic_vector(7 DOWNTO 0);
			-- Interface to PANDA Processor
			inst_adr 		: IN	inst_adr_t;
			inst_read		: IN	std_ulogic;
			inst_wait_in	: IN	std_ulogic;
			inst_wait_out	: OUT std_ulogic;
			res_n_out		: OUT std_ulogic;
			indir_adr		: IN 	data_adr_t;
			stack_ptr		: IN	data_adr_t;
			akku				: IN	data_t;
			carry				: IN 	std_ulogic_vector(0 DOWNTO 0);
			reg_b				: IN 	data_t;
			reg_c				: IN	data_t;
			reg_d				: IN 	data_t;
			int_en			: IN  std_ulogic);
END ENTITY panda_debug_control;

ARCHITECTURE rtl OF panda_debug_control IS
	SIGNAL ie_vect : std_ulogic_vector(0 DOWNTO 0);	
		
	SIGNAL brakepoint0 : inst_adr_t;
	SIGNAL breakpoint_en : std_ulogic;

	TYPE rec_state_t IS (wait_command, read_param, execute_command);
	SIGNAL current_rec_state : rec_state_t;
	SIGNAL next_rec_state : rec_state_t;
	
	TYPE snd_state_t IS (idle, wait_cycle, send_instadr, send_akku, 
								send_carry, send_ie, send_indir, send_b, send_c,
								send_d, send_stackptr, send_cr);
	SIGNAL current_snd_state : snd_state_t;
	SIGNAL next_snd_state : snd_state_t;
	
	SIGNAL value_sent : boolean;
	SIGNAL send_int : std_ulogic;
	
	TYPE dbg_state_t IS (stop, step, run, reset);
	SIGNAL current_dbg_state : dbg_state_t;
	SIGNAL next_dbg_state : dbg_state_t;
	
	SIGNAL was_brkpt, is_brkpt : boolean;
	
	SIGNAL param : debug_param_t;
	TYPE command_t IS (run, breakpoint, step, stop, reset, brenable, none);
	SIGNAL command : command_t;
	CONSTANT RUN_COMMAND 			: ascii_type := ASCII_r_s;
	CONSTANT BREAKPOINT_COMMAND 	: ascii_type := ASCII_b_s;
	CONSTANT BRENABLE_COMMAND		: ascii_type := ASCII_e_s;
	CONSTANT STEP_COMMAND 			: ascii_type := ASCII_s_s;
	CONSTANT STOP_COMMAND 			: ascii_type := ASCII_h_s;
	CONSTANT RESET_COMMAND 			: ascii_type := ASCII_x_s;
	CONSTANT END_CHAR 				: ascii_type := ASCII_CR;	
	
	-- Sends a Number as HEX followed by a Space Character
	PROCEDURE send_number  (SIGNAL busy 				: IN 		std_logic;
									SIGNAL send_int 			: INOUT	std_logic; 
									VARIABLE sent_nibbles	: INOUT 	integer;
									SIGNAL value_sent			: OUT		boolean;
									SIGNAL data_out			: OUT		std_ulogic_vector(7 DOWNTO 0);
									SIGNAL number				: IN		std_ulogic_vector;
									VARIABLE number_int		: INOUT	std_ulogic_vector) IS 
		CONSTANT nibbles_int : integer := (number_int'LEFT)/4 + 1;
		CONSTANT nibbles : integer := (number'LEFT)/4 + 1;
	BEGIN
		IF busy = '0' AND send_int = '0' THEN
			send_int <= '1';
			IF sent_nibbles < nibbles THEN
				IF sent_nibbles = 0 THEN
					number_int := std_ulogic_vector(to_unsigned(0,number_int'LEFT+1));
					number_int((4*(nibbles_int-nibbles)+number'LEFT) DOWNTO (4*(nibbles_int-nibbles))) := number;
				ELSE
					number_int := number_int((number_int'LEFT-4) DOWNTO 0) & X"0";
				END IF;				
				data_out <= ascii_from_hex(number_int(number_int'LEFT DOWNTO (number_int'LEFT-3)));
			ELSE
				data_out <= ASCII_SPAC;
			END IF;
			sent_nibbles := sent_nibbles + 1;
		END IF;
		IF sent_nibbles > nibbles THEN
			value_sent <= true;
			sent_nibbles := 0;
		END IF;
	END PROCEDURE send_number;
	
BEGIN

	ie_vect(0) <= int_en;
	send <= send_int;

	-- Synchronuous FSM Processes
	fsm_clocked : PROCESS (res_n, clk)
	BEGIN
		IF res_n = '0' THEN
			current_rec_state <= wait_command;
			current_dbg_state <= reset;
			current_snd_state <= idle;
		ELSIF rising_edge(clk) THEN
			current_rec_state <= next_rec_state;
			current_dbg_state <= next_dbg_state;
			current_snd_state <= next_snd_state;
		END IF;
	END PROCESS fsm_clocked;
	
	-- Receive And Executes Commands
	rec_fsm_comb : PROCESS(current_rec_state, do_rdy, data_in)
	BEGIN
		CASE current_rec_state IS
			WHEN wait_command	=> IF do_rdy = '1' THEN
											CASE data_in IS
												WHEN RUN_COMMAND |
													  BREAKPOINT_COMMAND |
													  STEP_COMMAND |
													  STOP_COMMAND |
													  RESET_COMMAND |
													  BRENABLE_COMMAND	=> next_rec_state <= read_param;
												WHEN OTHERS 				=> next_rec_state <= wait_command;
											END CASE;
										ELSE
											next_rec_state <= wait_command;
										END IF;
			WHEN read_param	=> IF do_rdy = '1' AND data_in = END_CHAR THEN
											next_rec_state <= execute_command;
										ELSE
											next_rec_state <= read_param;
										END IF;
			WHEN execute_command	=> next_rec_state <= wait_command;
			WHEN OTHERS			=> next_rec_state <= wait_command;
		END CASE;
	END PROCESS rec_fsm_comb;
	
	rec_fsm_writeregs : PROCESS (res_n, clk)
	BEGIN
		IF res_n = '0' THEN
			brakepoint0 <= (OTHERS => '0');
			breakpoint_en <= '0';
		ELSIF rising_edge(clk)THEN
			CASE current_rec_state IS
				-- Read Command
				WHEN wait_command 	=> IF do_rdy = '1' THEN
													CASE data_in IS
														WHEN RUN_COMMAND 			=> command <= run;
														WHEN BREAKPOINT_COMMAND => command <= breakpoint;
														WHEN STEP_COMMAND 		=> command <= step;
														WHEN STOP_COMMAND			=> command <= stop;
														WHEN RESET_COMMAND 		=> command <= reset;
														WHEN BRENABLE_COMMAND	=> command <= brenable;
														WHEN OTHERS 				=> command <= none;
													END CASE;
												END IF;
												param <= (OTHERS => '0');
				-- Read Parameter
				WHEN read_param		=> IF do_rdy = '1' AND next_rec_state = read_param THEN
													FOR i IN 0 TO (param'LEFT/4-1) LOOP
														param((param'LEFT-i*4) DOWNTO (param'LEFT-i*4-3)) <= param((param'LEFT-i*4-4) DOWNTO (param'LEFT-i*4-7));
													END LOOP;
													param(3 DOWNTO 0) <= hex_from_ascii(data_in);
												END IF;
				WHEN execute_command	=> CASE command IS
													WHEN breakpoint 	=> brakepoint0 <= param(inst_adr_width-1 DOWNTO 0);
													WHEN brenable 		=> breakpoint_en <= param(0);
													WHEN OTHERS			=> NULL;
												END CASE; 
				WHEN OTHERS => NULL;
			END CASE;
		END IF;
	END PROCESS rec_fsm_writeregs;
	
	-- Generate Output Stream
	snd_fsm_comb : PROCESS(current_snd_state, current_dbg_state, next_dbg_state, value_sent, inst_read)
	BEGIN
		CASE current_snd_state IS
			WHEN idle				=>	IF current_dbg_state /= stop AND next_dbg_state = stop THEN
												next_snd_state <= wait_cycle;
											ELSE
												next_snd_state <= idle;
											END IF;
			WHEN wait_cycle		=>	IF inst_read = '1' THEN					-- Wait for instaddr to be updated
												next_snd_state <= send_instadr;	
											ELSE
												next_snd_state <= wait_cycle;
											END IF;
			WHEN send_instadr		=> IF value_sent THEN
												next_snd_state <= send_akku;
											ELSE
												next_snd_state <= send_instadr;
											END IF;
			WHEN send_akku			=>	IF value_sent THEN
												next_snd_state <= send_carry;
											ELSE
												next_snd_state <= send_akku;
											END IF;
			WHEN send_carry		=>	IF value_sent THEN
												IF interrupts_on THEN
													next_snd_state <= send_ie;
												ELSIF indir_on THEN
													next_snd_state <= send_indir;
												ELSIF mul_on THEN
													next_snd_state <= send_b;
												ELSIF user_stack_on THEN
													next_snd_state <= send_stackptr;
												ELSE
													next_snd_state <= send_cr;
												END IF;
											ELSE
												next_snd_state <= send_carry;
											END IF;
			WHEN send_ie			=>	IF value_sent THEN
												IF indir_on THEN
													next_snd_state <= send_indir;
												ELSIF mul_on THEN
													next_snd_state <= send_b;
												ELSIF user_stack_on THEN
													next_snd_state <= send_stackptr;
												ELSE
													next_snd_state <= send_cr;
												END IF;
											ELSE
												next_snd_state <= send_ie;
											END IF;
			WHEN send_indir		=>	IF value_sent THEN
												IF mul_on THEN
													next_snd_state <= send_b;
												ELSIF user_stack_on THEN
													next_snd_state <= send_stackptr;
												ELSE
													next_snd_state <= send_cr;
												END IF;
											ELSE
												next_snd_state <= send_indir;
											END IF;
			WHEN send_b				=>	IF value_sent THEN
												IF mac_for_mul THEN
													next_snd_state <= send_c;
												ELSIF user_stack_on THEN
													next_snd_state <= send_stackptr;
												ELSE
													next_snd_state <= send_cr;
												END IF;
											ELSE
												next_snd_state <= send_b;
											END IF;
			WHEN send_c				=> IF value_sent THEN
												next_snd_state <= send_d;
											ELSE
												next_snd_state <= send_c;
											END IF;
			WHEN send_d				=>	IF value_sent THEN
												IF user_stack_on THEN
													next_snd_state <= send_stackptr;
												ELSE
													next_snd_state <= send_cr;
												END IF;
											ELSE
												next_snd_state <= send_d;
											END IF;
			WHEN send_stackptr 	=> IF value_sent THEN	
												next_snd_state <= send_cr;
											ELSE
												next_snd_state <= send_stackptr;
											END IF;
			WHEN send_cr			=>	IF value_sent THEN
												next_snd_state <= idle;
											ELSE
												next_snd_state <= send_cr;
											END IF;
			WHEN OTHERS				=> next_snd_state <= idle;
		END CASE;
	END PROCESS snd_fsm_comb;
	
	snd_fsm_outp : PROCESS (res_n, clk)
		VARIABLE sent_nibbles : integer RANGE 0 TO (biggest_reg_width-1)/4+1 + 1;
		VARIABLE number_int : debug_param_t;
	BEGIN
		IF res_n = '0' THEN
			send_int <= '0';
			value_sent <= false;
		ELSIF rising_edge(clk) THEN
			-- Default Values
			value_sent <= false;
			send_int <= '0';
			
			CASE current_snd_state IS
				WHEN idle				=>	sent_nibbles := 0;
				WHEN send_instadr		=> send_number(busy, send_int, sent_nibbles, value_sent, data_out, inst_adr, number_int);	
				WHEN send_akku			=>	send_number(busy, send_int, sent_nibbles, value_sent, data_out, akku, number_int);	
				WHEN send_carry		=>	send_number(busy, send_int, sent_nibbles, value_sent, data_out, carry, number_int);	
				WHEN send_ie			=> send_number(busy, send_int, sent_nibbles, value_sent, data_out, ie_vect, number_int);	
				WHEN send_indir		=>	send_number(busy, send_int, sent_nibbles, value_sent, data_out, indir_adr, number_int);	
				WHEN send_b				=>	send_number(busy, send_int, sent_nibbles, value_sent, data_out, reg_b, number_int);
				WHEN send_c				=>	send_number(busy, send_int, sent_nibbles, value_sent, data_out, reg_c, number_int);
				WHEN send_d				=>	send_number(busy, send_int, sent_nibbles, value_sent, data_out, reg_d, number_int);
				WHEN send_stackptr 	=> send_number(busy, send_int, sent_nibbles, value_sent, data_out, stack_ptr, number_int);	
				WHEN send_cr			=>	IF busy = '0' AND send_int = '0' THEN	-- Send Carriage Return
													send_int <= '1';
													data_out <= ASCII_CR;
													value_sent <= true;
												END IF;
				WHEN OTHERS				=> data_out <= (OTHERS => 'X');
			END CASE;
		END IF;
	END PROCESS snd_fsm_outp;
				
	-- Control Debug Process
	dbg_fsm_comb : PROCESS (current_rec_state, command, inst_wait_in, inst_adr, is_brkpt, was_brkpt, current_dbg_state, breakpoint_en)
	BEGIN
		IF is_brkpt AND NOT was_brkpt THEN
			next_dbg_state <= stop;
		ELSIF current_rec_state = execute_command THEN
			CASE command IS
				WHEN run			=>	next_dbg_state <= run;
				WHEN step		=>	next_dbg_state <= step;
				WHEN reset		=> next_dbg_state <= reset;
				WHEN stop		=> next_dbg_state <= stop;
				WHEN OTHERS		=> next_dbg_state <= current_dbg_state;
			END CASE;
		ELSE			
			CASE current_dbg_state IS
				WHEN stop	=> next_dbg_state <= stop;
				WHEN step	=>	IF inst_wait_in = '0' THEN
										next_dbg_state <= stop;
									ELSE
										next_dbg_state <= step;
									END IF;
				WHEN reset	=>	next_dbg_state <= stop;
				WHEN run		=>	next_dbg_state <= run;
				WHEN OTHERS	=> next_dbg_state <= run;
			END CASE;
		END IF;
	END PROCESS dbg_fsm_comb;
	
	-- Breakpoint Detection
	is_brkpt <= (inst_adr = brakepoint0) AND (inst_read = '1') AND breakpoint_en = '1';
	brkpt_detection : PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			was_brkpt <= is_brkpt;
		END IF;
	END PROCESS brkpt_detection;
	
	-- Generate Signals for Processor
	res_n_out <= '0' WHEN current_dbg_state = reset ELSE
					 '1';
	inst_wait_out <= '1' WHEN (current_dbg_state = stop) OR (is_brkpt AND NOT was_brkpt) ELSE
						  '0';
	
			
END ARCHITECTURE rtl;
			
			
	
