--*************************************************************************
--* FILE      :   panda_debugger.vhd                            	  		  *
--* PROJECT   :   Panda                      									  *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       28.04.2008  Bründler Oliver    File written              	  *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This block contains the debugger of the Panda processor  				  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************


LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	
LIBRARY work;
	USE work.panda_pkg.all;
	
ENTITY panda_debugger IS
	GENERIC (interrupts_on	: boolean := true;		-- Interrupts On/Off
				indir_on 		: boolean := true;		-- Indirect Adressing On/Off
				mul_on			: boolean := false;		-- Multiplication On/Off
				mac_for_mul		: boolean := false;		-- MAC instead of Multiplication On/Off
				user_stack_on	: boolean := false;		-- User Stack On/Off 
				clk_frequency : integer := 10000000);	-- Clock frequency
	PORT(	--Standard
			clk				: IN	std_ulogic;
			res_n				: IN	std_ulogic;
			-- Controller I/Os
			inst_adr 		: IN	inst_adr_t;
			inst_read		: IN	std_ulogic;
			inst_wait_in	: IN	std_ulogic;
			inst_wait_out	: OUT std_ulogic;
			res_n_out		: OUT std_ulogic;
			-- Interface to panda_bus
			indir_adr		: IN 	data_adr_t;
			stack_ptr		: IN	data_adr_t;
			-- Interface to panda_alu
			akku				: IN	data_t;
			carry				: IN 	std_ulogic_vector(0 DOWNTO 0);
			reg_b				: IN 	data_t;
			reg_c				: IN 	data_t;
			reg_d				: IN	data_t;
			-- Interface to panda_ctrl
			int_en			: IN 	std_ulogic;
			-- Serial Debugger Interface
			tx					: OUT std_ulogic;
			rx					: IN 	std_ulogic);
END ENTITY panda_debugger;

ARCHITECTURE rtl OF panda_debugger IS
	
	-- Signals betweet panda_debug_control and VHDL_COMPORT		
	SIGNAL send, busy, do_rdy : std_ulogic;
	SIGNAL data_to_com : std_ulogic_vector(7 downto 0);
	SIGNAL data_from_com : std_logic_vector(7 downto 0);
	
	-- Other internal Signals
	SIGNAL inst_wait_int, res_n_int : std_ulogic;

	COMPONENT panda_comport
		GENERIC (databits : integer := 8;
					baudrate : integer := 115200;
					clk_frequency: integer := 10000000);
		PORT (-- Standard				
				clk 		:  IN  std_logic;
				res_n 	:  IN  std_logic;
				-- RS-232 Interface
				rx 		:  IN  std_logic;
				tx 		:  OUT std_logic;
				-- Parallel Interface
				send 		:  IN  std_logic;
				busy 		:  OUT std_logic;
				do_rdy 	:  OUT std_logic;
				data_in 	:  IN  std_logic_vector((databits-1) downto 0);		
				data_out :  OUT std_logic_vector((databits-1) downto 0));
	END COMPONENT panda_comport;
	
	COMPONENT panda_debug_control
		GENERIC (interrupts_on	: boolean := true;	-- Interrupts On/Off
					indir_on 		: boolean := true;	-- Indirect Adressing On/Off
					mul_on			: boolean := false;	-- Multiplication On/Off
					mac_for_mul		: boolean := false;	-- MAC instead of Multiplication On/Off
					user_stack_on	: boolean := false);	-- User Stack On/Off 
		PORT( -- Standard
				clk 				: IN	std_ulogic;
				res_n				: IN	std_ulogic;
				-- Interface to VHDL_COMPORT
				send 				:  OUT std_ulogic;
				busy 				:  IN  std_ulogic;
				do_rdy 			:  IN  std_ulogic;
				data_in 			:  IN  std_ulogic_vector(7 DOWNTO 0);		
				data_out 		:  OUT std_ulogic_vector(7 DOWNTO 0);
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
				reg_c				: IN 	data_t;
				reg_d				: IN 	data_t;
				int_en			: IN  std_ulogic);
	END COMPONENT panda_debug_control;
BEGIN

	inst_wait_out <= inst_wait_in OR inst_wait_int;
	res_n_out <= res_n AND res_n_int;

	comport_I1 : panda_comport 
		GENERIC MAP(databits => 8,
						baudrate => 115200,
						clk_frequency => clk_frequency)														
		 PORT MAP  (clk => clk,
						res_n => res_n,
						rx => rx,
						tx => tx,
						send => send,
						busy => busy,
						do_rdy => do_rdy,
						data_in => std_logic_vector(data_to_com),		
						data_out => data_from_com);
														
	panda_debug_control_I1 : panda_debug_control 
		GENERIC MAP(interrupts_on => interrupts_on,
						indir_on => indir_on,
						mul_on => mul_on,
						mac_for_mul	=> mac_for_mul,
						user_stack_on => user_stack_on)
		PORT MAP	  (clk => clk,				
						res_n => res_n,
						send => send,
						busy => busy,
						do_rdy => do_rdy,
						data_in => std_ulogic_vector(data_from_com),		
						data_out => data_to_com,
						inst_adr => inst_adr,
						inst_read => inst_read,
						inst_wait_in => inst_wait_in,
						inst_wait_out => inst_wait_int,
						res_n_out => res_n_int,
						indir_adr => indir_adr,
						stack_ptr => stack_ptr,
						akku => akku,
						carry => carry,
						reg_b => reg_b,
						reg_c	=> reg_c,
						reg_d => reg_d,
						int_en => int_en);
END ARCHITECTURE rtl;
			