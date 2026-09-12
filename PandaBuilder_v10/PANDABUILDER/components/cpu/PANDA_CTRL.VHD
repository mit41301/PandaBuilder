--*************************************************************************
--* FILE      :   panda_ctrl.vhd		                            	  		  *
--* PROJECT   :   Panda                      									  *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       28.04.2008  Bründler Oliver    File written              	  *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This block contains the control unit of the Panda processor  			  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************


LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	USE ieee.numeric_std.all;
	
LIBRARY work;
	USE work.panda_pkg.all;
	
ENTITY panda_ctrl IS
	GENERIC (stack_depth 	: positive := 6;
				num_of_ints 	: positive := 1;
				interrupts_on	: boolean := true;
				indir_on			: boolean := true;
				stack_as_ram 	: boolean := false;
				user_stack_on	: boolean := false;
				adv_skips_on	: boolean := true;
				dat_on_sstack	: boolean := false);
	PORT (-- Standard
			clk 			: IN	std_ulogic;												
			res_n			: IN 	std_ulogic;
			-- Interface to panda_alu
			akku_op		: OUT akku_ops;											
			akku_do_op	: OUT std_ulogic;
			operand		: OUT data_t;	 
			skip			: IN 	std_ulogic;
			akku_in		: IN  data_t;
			-- Interface to panda_bus
			bus_adr		: OUT data_adr_t;
			bus_op		: OUT bus_ops;												
			bus_do_op	: OUT std_ulogic;
			-- Databus
			bus_data		: IN	data_t;
			bus_wait		: IN 	std_ulogic;
			-- Instructionbus
			inst			: IN 	inst_t;	
			inst_adr 	: OUT inst_adr_t;
			inst_wait	: IN 	std_ulogic;
			inst_read	: OUT std_ulogic;
			-- Interrupts
			interrupts	: IN 	std_ulogic_vector((num_of_ints-1) DOWNTO 0);
			-- Interface to panda_debugger
			int_en_dbg	: OUT	std_ulogic);			
END ENTITY panda_ctrl;

ARCHITECTURE rtl OF panda_ctrl IS
	-- Statemachine to Control the CPU
	TYPE state IS (fetch, preop, calc, reset, interrupt);
	SIGNAL current_state, next_state : state;
	
	-- Stack 
	TYPE stack_type IS ARRAY ((stack_depth-1) DOWNTO 0) OF sysstack_t;
	-- Only normal implementation
	SIGNAL normal_stack : stack_type;
	-- Only RAM implementation
	SIGNAL ram_stack : stack_type;
	SUBTYPE stack_pointer_t IS integer RANGE 0 to stack_depth;
	SIGNAL stack_pointer : stack_pointer_t;
	SIGNAL stackram_wr : std_ulogic;
	SIGNAL stackram_out : sysstack_t;
	SIGNAL stackdat : data_t;				-- Not used, just to prevent PC 
	
	-- Others
	SIGNAL inst_reg : inst_t;					-- Current Instruction
	SIGNAL op : all_ops;							-- Current Operation	
	SIGNAL int_en : std_ulogic;				-- Interrupt Enable	
	SIGNAL programmcounter : inst_adr_t;	-- Programmcounter (pc)
	SIGNAL inst_wait_reg : std_logic;		-- inst_wait 1clk delayed

	-- Pushes the pc on the normal stack 
	PROCEDURE push_stack_normal (			pc 	: IN 		inst_adr_t;
										  SIGNAL stack	: INOUT stack_type) IS
	BEGIN
		FOR i IN 1 TO (stack_depth-1) LOOP
			stack(stack_depth - i) <= stack(stack_depth - i - 1);
		END LOOP;
		stack(0)((sysstack_width-1) DOWNTO (inst_adr_width-1)) <= (OTHERS => 'X');
		--stack(0)((inst_adr_width-1) DOWNTO 0) <= std_ulogic_vector(unsigned(pc) + 1);		
		stack(0)((inst_adr_width-1) DOWNTO 0) <= pc;
	END PROCEDURE push_stack_normal;
	
	-- Pushes the pc on the RAM stack 
	PROCEDURE push_stack_ram (SIGNAL stackram_wr		: OUT 	std_ulogic;
									  SIGNAL stack_pointer	: INOUT	stack_pointer_t) IS
	BEGIN
		stack_pointer <= (stack_pointer + 1) mod stack_depth;
		stackram_wr <= '1';
	END PROCEDURE push_stack_ram;

	-- Loads the pc from the normal stack
	PROCEDURE pop_stack_normal (SIGNAL pc		: OUT		inst_adr_t;
										 SIGNAL stack  : INOUT 	stack_type) IS
	BEGIN
		pc <= stack(0)((inst_adr_width-1) DOWNTO 0);
		FOR i IN 0 TO (stack_depth-2) LOOP
			stack(i) <= stack(i+1);
		END LOOP;
	END PROCEDURE pop_stack_normal;
	
	-- Loads the pc from the RAM stack
	PROCEDURE pop_stack_ram (SIGNAL pc					: OUT		std_ulogic_vector;							
									 SIGNAL stack_pointer	: INOUT	stack_pointer_t;
									 SIGNAL stackram_out		: IN 		sysstack_t) IS
	BEGIN
		pc <= stackram_out(pc'LEFT DOWNTO 0);
		stack_pointer <= (stack_pointer - 1) mod stack_depth;
	END PROCEDURE pop_stack_ram;
	
BEGIN

	int_en_dbg <= int_en;
	
	op <= get_op_from_code(inst_reg);		
	
	op1 : IF dat_on_sstack AND stack_as_ram GENERATE
		operand <= bus_data WHEN mem_read_from_bus_op(get_bus_op(get_op_from_code(inst_reg)), 
																					indir_on, user_stack_on) ELSE
					  stackram_out((data_width-1) DOWNTO 0) WHEN op = pops_i ELSE
					  inst_reg((data_width-1) DOWNTO 0);
	END GENERATE op1;
	op2 : IF NOT (dat_on_sstack AND stack_as_ram) GENERATE
		operand <= bus_data WHEN mem_read_from_bus_op(get_bus_op(get_op_from_code(inst_reg)), 
																					indir_on, user_stack_on) ELSE
					  inst_reg((data_width-1) DOWNTO 0);
	END GENERATE op2;
	
	bus_adr <= inst_reg((data_adr_width-1) DOWNTO 0);
	akku_op <= get_akku_op(op);
	bus_op <= get_bus_op(op);
	
	akku_do_op <= '1' WHEN next_state = calc ELSE '0';
	
	bus_do_op <= '1' WHEN next_state = preop AND current_state = fetch ELSE '0';
	
	inst_read <= '1' WHEN next_state = fetch ELSE '0';

	inst_adr <= programmcounter;
	
	save_instruction : PROCESS(clk, res_n)
	BEGIN
		IF rising_edge(clk) THEN
			inst_wait_reg <= inst_wait;
			IF next_state = fetch THEN
				inst_reg <= inst;
			END IF;
		END IF;
	END PROCESS save_instruction;
	
	fsm_clocked : PROCESS(clk, res_n)
	BEGIN
		IF res_n = '0' THEN
			current_state <= reset;
		ELSIF rising_edge(clk) THEN
			current_state <= next_state;
		END IF;
	END PROCESS fsm_clocked;
																															 											
	fsm_comb : PROCESS(current_state, op, skip, bus_wait, inst_wait_reg, clk, interrupts, int_en)
	BEGIN
		CASE current_state IS

			-- Fetch Instruction
			WHEN fetch 	=>	IF (inst_wait_reg = '0') THEN
									IF (get_bus_op(op) = nop_i AND NOT op_is_skip(op, adv_skips_on)) THEN
										next_state <= calc;
									ELSE
										next_state <= preop;
									END IF;
								ELSE
									next_state <= fetch;
								END IF;

			WHEN preop 	=> IF bus_wait = '0' THEN
									next_state <= calc;
								ELSE
									next_state <= preop;
								END IF;

			-- Execute Operation
			WHEN calc	=> IF unsigned(interrupts) /= 0 AND int_en = '1' AND interrupts_on THEN
									next_state <= interrupt;
								ELSE
									next_state <= fetch;
								END IF;
			
			-- Interrupt
			WHEN interrupt => next_state <= fetch;

			-- Undefined States
			WHEN OTHERS => next_state <= fetch;

		END CASE;
	END PROCESS fsm_comb;
	
	
	PC : PROCESS(clk, res_n)
		CONSTANT pcmax : inst_adr_t := (OTHERS => '1');
	BEGIN
		IF res_n = '0' THEN
			programmcounter <= (OTHERS => '0');
			IF interrupts_on THEN
				int_en <= '0';
			END IF;
			IF stack_as_ram THEN
				stack_pointer <= 0;
				stackram_wr <= '0';
			END IF;
		ELSIF rising_edge(clk) THEN
		
			-- Default Value for stackram_wr
			IF stack_as_ram THEN
				stackram_wr <= '0';
			END IF;
			
			-- Interrupt
			IF next_state = interrupt THEN
				FOR int_nr IN 0 TO (num_of_ints-1) LOOP
					IF interrupts(int_nr) = '1' THEN
						programmcounter <= std_ulogic_vector(to_unsigned((to_integer(unsigned(pcmax)) - int_nr) mod 2**inst_adr_width, inst_adr_width));
					END IF;
				END LOOP;
				
				IF stack_as_ram THEN
					push_stack_ram(stackram_wr, stack_pointer);	
				ELSE
					push_stack_normal(programmcounter, normal_stack);
				END IF;
				
				int_en <= '0';
				
			-- Skip Instructions
			ELSIF next_state = preop AND current_state = fetch THEN
				IF op_is_skip(op, adv_skips_on) THEN
					programmcounter <= std_ulogic_vector(unsigned(programmcounter) + 1);
				END IF;
			
			
			-- Normal Instructons
			ELSIF next_state = calc THEN ---(current_state = fetch AND inst_wait_reg = '0') THEN
					IF op = si_i AND interrupts_on THEN
						int_en <= inst_reg(0);
					END IF;
					
					IF skip = '1' OR NOT op_is_skip(op, adv_skips_on) THEN
						CASE op IS
							WHEN jmp_i		=> programmcounter <= inst_reg((inst_adr_width-1) DOWNTO 0);
							WHEN call_i		=> programmcounter <= inst_reg((inst_adr_width-1) DOWNTO 0);
													IF stack_as_ram THEN
														push_stack_ram(stackram_wr, stack_pointer);	
													ELSE
														push_stack_normal(std_ulogic_vector(unsigned(programmcounter)+1), normal_stack);
													END IF;
							WHEN ret_i		=> IF stack_as_ram THEN
														pop_stack_ram(programmcounter, stack_pointer, stackram_out);
													ELSE
														pop_stack_normal(programmcounter, normal_stack);
													END IF;
							WHEN reti_i		=> IF interrupts_on THEN
														IF stack_as_ram THEN
															pop_stack_ram(programmcounter, stack_pointer, stackram_out);
														ELSE
															pop_stack_normal(programmcounter, normal_stack);
														END IF;
														int_en <= '1';
													ELSE
														programmcounter <= std_ulogic_vector(unsigned(programmcounter) + 1);
													END IF;
							WHEN pushs_i	=> IF dat_on_sstack AND stack_as_ram THEN
														push_stack_ram(stackram_wr, stack_pointer);
													END IF;
													programmcounter <= std_ulogic_vector(unsigned(programmcounter) + 1);
							WHEN pops_i		=> IF dat_on_sstack AND stack_as_ram THEN
														pop_stack_ram(stackdat, stack_pointer, stackram_out);
													END IF;
													programmcounter <= std_ulogic_vector(unsigned(programmcounter) + 1);
							WHEN OTHERS		=> programmcounter <= std_ulogic_vector(unsigned(programmcounter) + 1);
						END CASE;
					END IF;
			END IF;
		END IF;
	END PROCESS PC;
	
	-- Stack Memory (Only if Stack is implemented as RAM)
	stackram1 : IF stack_as_ram GENERATE
		RAM : PROCESS(clk)
			VARIABLE word_to_write : sysstack_t;
		BEGIN
			IF rising_edge(clk) THEN
				IF stackram_wr = '1' THEN
					ram_stack(stack_pointer) <= std_ulogic_vector(word_to_write);
				END IF;
				stackram_out <= ram_stack(stack_pointer);	
				IF op = pushs_i AND dat_on_sstack THEN
					word_to_write((sysstack_width-1) DOWNTO (data_width-1)) := (OTHERS => 'X');
					word_to_write((data_width-1) DOWNTO 0) := akku_in;
				ELSIF op = call_i THEN
					word_to_write((sysstack_width-1) DOWNTO (inst_adr_width-1)) := (OTHERS => 'X');
					word_to_write((inst_adr_width-1) DOWNTO 0) := std_ulogic_vector(unsigned(programmcounter) + 1);		
				ELSE -- Interrupt
					word_to_write((sysstack_width-1) DOWNTO (inst_adr_width-1)) := (OTHERS => 'X');
					word_to_write((inst_adr_width-1) DOWNTO 0) := programmcounter;							
				END IF;
			END IF;			
		END PROCESS RAM;
	END GENERATE stackram1;
			
END ARCHITECTURE rtl;