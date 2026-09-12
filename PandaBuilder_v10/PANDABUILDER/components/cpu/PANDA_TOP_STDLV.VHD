--*************************************************************************
--* FILE      :   panda_top_stdlv.vhd                            	  		  *
--* PROJECT   :   Panda                      									  *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       28.04.2008  Bründler Oliver    File written              	  *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This block is the top module of the panda processor  					  *
--* All I/Os are std_logic / std_logic_vector									  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************

LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	
LIBRARY work;
	USE work.panda_pkg.all;
	
ENTITY panda_top_stdlv IS
	GENERIC (stack_depth 	: positive := 6;			-- Depth of Stack
				num_of_ints 	: positive := 1;			-- Number of Interrupts
				interrupts_on	: boolean := true;		-- Interrupts On/Off
				indir_on 		: boolean := true;		-- Indirect Adressing On/Off
				carry_arith_on	: boolean := true;		-- Carry Arithmetic On/Off
				adv_skips_on	: boolean := true;		-- Advanced Skips On/Off
				mul_on			: boolean := false;		-- Multiplication On/Off
				mac_for_mul		: boolean := false;		-- MAC instead of Multiplication On/Off
				user_stack_on	: boolean := false;		-- User Stack On/Off 
				stack_as_ram	: boolean := false;		-- Stack is implemented as RAM (for FPGAs) 
				dat_on_sstack	: boolean := false;		-- Data can be pushed on System Stack
				debug_on			: boolean := false;		-- Debugger On/Off
				clk_frequency	: integer := 10000000);	-- Clock Frequency (for Debugger)
	PORT (-- Standard
			clk 			: IN 	std_logic;
			res_n 		: IN 	std_logic;
			-- Instruction Bus
			inst			: IN 	std_logic_vector(inst_t'LEFT DOWNTO 0);	
			inst_adr 	: OUT std_logic_vector(inst_adr_t'LEFT DOWNTO 0);
			inst_wait	: IN 	std_logic;
			inst_read	: OUT std_logic;
			-- Data Bus
			data_in		: IN 	std_logic_vector(data_t'LEFT DOWNTO 0);			
			data_out		: OUT std_logic_vector(data_t'LEFT DOWNTO 0);
			data_adr		: OUT std_logic_vector(data_adr_t'LEFT DOWNTO 0);
			wr				: OUT std_logic;
			rd				: OUT std_logic;
			data_wait	: IN 	std_logic;
			-- Interrupts
			interrupts 	: IN 	std_logic_vector((num_of_ints-1) DOWNTO 0);
			-- Debugger Interface
			rx				: IN	std_logic;
			tx				: OUT	std_logic;
			res_n_dbg	: OUT std_logic);
END ENTITY panda_top_stdlv;

ARCHITECTURE rtl OF panda_top_stdlv IS
	-- Signals between CTRL and ALU
	SIGNAL akku_op : akku_ops; 
	SIGNAL akku_do_op, skip : std_ulogic;
	SIGNAL operand : data_t;
	
	-- Signals between CTRL and BUS
	SIGNAL bus_op : bus_ops;
	SIGNAL bus_do_op : std_ulogic;
	SIGNAL bus_adr : data_adr_t;
	
	-- Signals betweend ALU and BUS
	SIGNAL akku : data_t;
		
	-- Signals for Debugger
	SIGNAL inst_adr_int : inst_adr_t;
	SIGNAL inst_wait_int, res_n_int, inst_read_int, int_en : std_ulogic;
	SIGNAL stack_ptr, indir_adr : data_adr_t;
	SIGNAL reg_b, reg_c, reg_d : data_t;
	SIGNAL carry : std_ulogic_vector(0 DOWNTO 0);
	
	-- Conversion std_ulogic <-> std_logic
	SIGNAL data_adr_con : std_ulogic_vector(data_adr_t'LEFT DOWNTO 0);
	SIGNAL wr_con, rd_con : std_ulogic;
	SIGNAL tx_con : std_ulogic;

	COMPONENT panda_ctrl
		GENERIC (stack_depth 	: positive := 6;
					num_of_ints 	: positive := 1;
					interrupts_on	: boolean := true;
					indir_on			: boolean := true;
					stack_as_ram	: boolean := false;
					user_stack_on	: boolean := false;
					adv_skips_on	: boolean := true;
					dat_on_sstack	: boolean := false);
		PORT (clk 			: IN	std_ulogic;													-- Standard
				res_n			: IN 	std_ulogic;
				akku_op		: OUT akku_ops;													-- ALU Interface
				akku_do_op	: OUT std_ulogic;
				operand		: OUT data_t;
				skip			: IN 	std_ulogic;
				akku_in		: IN 	data_t;
				bus_adr		: OUT data_adr_t;													-- Bus Interface
				bus_op		: OUT bus_ops;														
				bus_do_op	: OUT std_ulogic;
				bus_data		: IN	data_t;
				bus_wait		: IN 	std_ulogic;
				inst			: IN 	inst_t;														-- Instruction Bus
				inst_adr 	: OUT inst_adr_t;
				inst_wait	: IN 	std_ulogic;
				inst_read	: OUT std_ulogic;
				interrupts	: IN 	std_ulogic_vector((num_of_ints-1) DOWNTO 0);		-- Interrupts
				int_en_dbg	: OUT std_ulogic);												-- Debugger			
	END COMPONENT panda_ctrl;
	
	COMPONENT panda_alu
		GENERIC (carry_arith_on : boolean := true;
					mul_on			: boolean := false;
					mac_for_mul		: boolean := false;
					adv_skips_on	: boolean := true);
		PORT (clk 			: IN	std_ulogic;							-- Standard
				res_n			: IN 	std_ulogic;
				operation	: IN	akku_ops;							-- CTRL Interface
				do_op			: IN	std_ulogic;
				operand		: IN 	data_t;
				skip			: OUT	std_ulogic;
				akku			: OUT data_t;								-- Bus Interface
				carry_dbg	: OUT std_ulogic_vector(0 DOWNTO 0);-- Debugger Interface
				reg_b_dbg	: OUT data_t;
				reg_c_dbg	: OUT data_t;
				reg_d_dbg	: OUT data_t);	
	END COMPONENT panda_alu;
	
	COMPONENT panda_bus
		GENERIC (indir_on 		: boolean := true;
					user_stack_on	: boolean := false);
			PORT (clk 				: IN	std_ulogic;		-- Standard
					res_n				: IN 	std_ulogic;
					operation 		: IN 	bus_ops;			-- CTRL Interface
					do_op				: IN 	std_ulogic;
					data_ready		: IN	std_ulogic;
					adr_int			: IN	data_adr_t;			
					akku_in			: IN 	data_t;			-- ALU Interface			
					data_adr			: OUT data_adr_t; 	-- Data Bus
					wr					: OUT std_ulogic;
					rd					: OUT std_ulogic;
					stack_ptr_dbg	: OUT	data_adr_t;		-- Debugger Interface
					indir_adr_dbg	: OUT data_adr_t);
	END COMPONENT panda_bus;
	
	COMPONENT panda_debugger
		GENERIC (interrupts_on	: boolean := true;		-- Interrupts On/Off
					indir_on 		: boolean := true;		-- Indirect Adressing On/Off
					mul_on			: boolean := false;		-- Multiplication On/Off
					mac_for_mul		: boolean := false;		-- MAC instead of Multiplication On/Off
					user_stack_on	: boolean := false;		-- User Stack On/Off 
					clk_frequency : integer := 10000000);	-- Clock frequency
		PORT (clk				: IN	std_ulogic;		--Standard
				res_n				: IN	std_ulogic;			
				inst_adr 		: IN	inst_adr_t;		-- Controller I/Os
				inst_read		: IN	std_ulogic;
				inst_wait_in	: IN	std_ulogic;
				inst_wait_out	: OUT std_ulogic;
				res_n_out		: OUT std_ulogic;			
				indir_adr		: IN 	data_adr_t;		-- Interface to panda_bus
				stack_ptr		: IN	data_adr_t;				
				akku				: IN	data_t;			-- Interface to panda_alu
				carry				: IN 	std_ulogic_vector(0 DOWNTO 0);
				reg_b				: IN 	data_t;
				reg_c				: IN 	data_t;
				reg_d				: IN	data_t;				
				int_en			: IN 	std_ulogic;		-- Interface to panda_ctrl				
				tx					: OUT std_ulogic;		-- Serial Debugger Interface
				rx					: IN 	std_ulogic);
	END COMPONENT panda_debugger;
BEGIN


	
	data_out <= std_logic_vector(akku);
	inst_adr <= std_logic_vector(inst_adr_int);
	inst_read <= std_logic(inst_read_int);
	res_n_dbg <= std_logic(res_n_int);
	data_adr <= std_logic_vector(data_adr_con);
	wr <= std_logic(wr_con);
	rd <= std_logic(rd_con);
	
	deb1 : IF NOT debug_on GENERATE
		tx <= '1';
		inst_wait_int <= std_ulogic(inst_wait);
		res_n_int <= std_ulogic(res_n);
	END GENERATE deb1;

	panda_ctrl_I1 : panda_ctrl 
		GENERIC MAP (stack_depth 	=> stack_depth,
						 num_of_ints	=> num_of_ints,
						 interrupts_on => interrupts_on,
						 indir_on 		=> indir_on,
						 stack_as_ram 	=> stack_as_ram,
						 user_stack_on => user_stack_on,
						 adv_skips_on 	=> adv_skips_on,
						 dat_on_sstack => dat_on_sstack)
		PORT MAP 	(clk			=> std_ulogic(clk),
						 res_n		=> res_n_int,
						 akku_op 	=> akku_op,
						 akku_do_op => akku_do_op,
						 operand 	=> operand,
						 skip			=> skip,
						 akku_in		=> akku,
						 bus_adr		=> bus_adr,
						 bus_op		=> bus_op,
						 bus_do_op 	=> bus_do_op,
						 bus_data	=> std_ulogic_vector(data_in),
						 bus_wait	=> std_ulogic(data_wait),
						 inst			=> std_ulogic_vector(inst),
						 inst_adr	=> inst_adr_int,
						 inst_wait	=> inst_wait_int,
						 inst_read  => inst_read_int,
						 interrupts => std_ulogic_vector(interrupts),
						 int_en_dbg	=> int_en);
	
	panda_alu_I1 : panda_alu 	
		GENERIC MAP (carry_arith_on 	=> carry_arith_on,
						 mul_on 				=> mul_on,
						 mac_for_mul		=> mac_for_mul,
						 adv_skips_on		=> adv_skips_on)
		PORT MAP (clk			=> std_ulogic(clk),				  
					 res_n		=> res_n_int,
					 operation	=> akku_op,
					 do_op		=> akku_do_op,
					 operand		=> operand((data_width-1) DOWNTO 0),
					 skip			=> skip,
					 akku			=> akku,
					 carry_dbg	=> carry,
					 reg_b_dbg	=> reg_b,
					 reg_c_dbg	=> reg_c,
					 reg_d_dbg	=> reg_d);
							
	panda_bus_I1 : panda_bus 	
		GENERIC MAP (indir_on 		=> indir_on,
						 user_stack_on => user_stack_on)
		PORT MAP	(clk				=> std_ulogic(clk),
					 res_n			=> res_n_int,
					 operation		=> bus_op,
					 do_op			=> bus_do_op,
					 data_ready		=> akku_do_op,
					 adr_int			=> bus_adr,
					 akku_in			=> akku,
					 data_adr		=> data_adr_con,
					 wr				=> wr_con,
					 rd				=> rd_con,
					 stack_ptr_dbg	=> stack_ptr,
					 indir_adr_dbg	=> indir_adr);
					
	deb2 : IF debug_on GENERATE
		panda_debugger_I1 : panda_debugger
			GENERIC MAP(interrupts_on	=> interrupts_on,
							indir_on 		=> indir_on,
							mul_on			=> mul_on,
							mac_for_mul		=> mac_for_mul,
							user_stack_on	=> user_stack_on,
							clk_frequency 	=> clk_frequency)
			PORT MAP(clk				=> std_ulogic(clk),
						res_n				=> std_ulogic(res_n),		
						inst_adr 		=> inst_adr_int,
						inst_read		=> inst_read_int,
						inst_wait_in	=> std_ulogic(inst_wait),
						inst_wait_out	=> inst_wait_int,
						res_n_out		=> res_n_int,		
						indir_adr		=> indir_adr,
						stack_ptr		=> stack_ptr,			
						akku				=> akku,
						carry				=> carry,
						reg_b				=> reg_b,
						reg_c				=> reg_c,
						reg_d				=> reg_d,				
						int_en			=> int_en,			
						tx					=> tx_con,
						rx					=> std_ulogic(rx));
						
						tx <= std_logic(tx_con);
	END GENERATE deb2;
	
	
END ARCHITECTURE rtl;