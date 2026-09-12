--*************************************************************************
--* FILE      :   panda_alu.vhd		                            	  		  *
--* PROJECT   :   Panda                      									  *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       28.04.2008  Bründler Oliver    File written              	  *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This block contains the arithmetic logic unit of the Panda processor  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************

LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	USE ieee.numeric_std.all;
	
LIBRARY work;
	USE work.panda_pkg.all;
	ENTITY panda_alu IS
	GENERIC(carry_arith_on  : boolean := true;
			  mul_on				: boolean := false;
			  mac_for_mul		: boolean := false;
			  adv_skips_on		: boolean := true);
	PORT (-- Standard
			clk 			: IN	std_ulogic;		
			res_n			: IN 	std_ulogic;
			-- Interface to panda_ctrl
			operation	: IN	akku_ops;			
			do_op			: IN	std_ulogic;
			operand		: IN 	data_t;
			skip			: OUT	std_ulogic;
			-- Interface to panda_bus
			akku			: OUT data_t;	-- goes to debugger too
			-- Interface to panda_debugger
			carry_dbg	: OUT std_ulogic_vector(0 DOWNTO 0);
			reg_b_dbg	: OUT data_t;
			reg_c_dbg	: OUT data_t;
			reg_d_dbg	: OUT data_t);
END ENTITY panda_alu;


ARCHITECTURE rtl OF panda_alu IS
	SIGNAL result : std_ulogic_vector(data_width DOWNTO 0);			-- Combinatorial Result of Operation
	SIGNAL result_2 : data_t;													-- 2nd Word of Multiplication / MAC result
	SIGNAL result_3 : data_t;													-- 3dr Word of MAC result
	SIGNAL akku_int : data_t;													-- Akkumulator	Register
	SIGNAL akkub_int : data_t;													-- 2nd Register for Multiplication / MAC
	SIGNAL akkuc_int : data_t;													-- 3rd Register for MAC
	SIGNAL akkud_int : data_t;													-- 4th Register for MAC
	SIGNAL carry : std_ulogic_vector(0 DOWNTO 0);						-- Carry
BEGIN

	akku <= akku_int;
	carry_dbg <= carry;
	reg_b_dbg <= akkub_int;
	reg_c_dbg <= akkuc_int;
	reg_d_dbg <= akkud_int;
	
	-- Processes the Operations, result MSB is Carry
	calculate : PROCESS (operation, operand, akku_int, carry, akkub_int, akkuc_int, akkud_int)
		VARIABLE mul_res : std_ulogic_vector((2*data_width-1) DOWNTO 0);
		VARIABLE mac_res : std_ulogic_vector((3*data_width-1) DOWNTO 0);
	BEGIN
	
		-- Multiplication Result higher Word / MAC
		IF mul_on THEN
			IF mac_for_mul THEN
				mac_res := std_ulogic_vector(signed(akkud_int & akkuc_int & akkub_int)+(signed(akku_int)*signed(operand)));
				result_2 <= mac_res((2*data_width-1) DOWNTO data_width);
				result_3 <= mac_res((3*data_width-1) DOWNTO (2*data_width));
			ELSE
				mul_res := std_ulogic_vector(unsigned(akku_int)*unsigned(operand));
				CASE operation IS
					WHEN mul_i 		=>	result_2 <= mul_res((2*data_width-1) DOWNTO data_width);
					WHEN xchg_i		=>	result_2 <= akku_int;
					WHEN OTHERS		=> result_2 <= akkub_int;
				END CASE;
			END IF;
		END IF;
		
		-- Normal Operation Result
		CASE operation IS
			WHEN ld_i		=>	result <= carry & operand;
			WHEN add_i		=> result <= std_ulogic_vector(unsigned('0' & akku_int) + unsigned('0' & operand));
			WHEN sub_i 		=> result <= std_ulogic_vector(unsigned('0' & akku_int) - unsigned('0' & operand));
			WHEN rol_i		=> result <= akku_int((data_width-1) DOWNTO 0) & carry;
			WHEN ror_i		=> result <= akku_int(0) & carry & akku_int((data_width-1) DOWNTO 1);
			WHEN and_i		=> result <= carry & (akku_int AND operand);
			WHEN or_i		=> result <= carry & (akku_int OR operand);
			WHEN xor_i		=> result <= carry & (akku_int XOR operand);
			WHEN sc_i		=> result <= operand(0) & akku_int;
			WHEN addc_i		=> IF carry_arith_on THEN
										result <= std_ulogic_vector(unsigned('0' & akku_int) + unsigned(operand) + unsigned(carry));
									ELSE
										result <= carry & akku_int;
									END IF;
			WHEN subc_i		=> IF carry_arith_on THEN
										result <= std_ulogic_vector(unsigned('0' & akku_int) - unsigned(operand) - unsigned(carry));
									ELSE
										result <= carry & akku_int;
									END IF;
			WHEN swap_i		=> result <= carry & akku_int((data_width/2-1) DOWNTO 0) & akku_int((data_width-1) DOWNTO (data_width/2));
			WHEN mul_i		=> IF mul_on THEN
										IF mac_for_mul THEN
											result <= carry & mac_res((data_width-1) DOWNTO 0);	
										ELSE
											result <= carry & mul_res((data_width-1) DOWNTO 0);
										END IF;
									ELSE
										result <= carry & akku_int;
									END IF;								
			WHEN xchg_i		=> IF mul_on THEN
										IF mac_for_mul THEN
											CASE operand(1 DOWNTO 0) IS
												WHEN "00" => result <= carry & akkub_int;
												WHEN "01" => result <= carry & akkuc_int;
												WHEN "10" => result <= carry & akkud_int;
												WHEN OTHERS => result <= carry & akku_int;
											END CASE;
										ELSE
											result <= carry & akkub_int;
										END IF;
									ELSE
										result <= carry & akku_int;
									END IF;
			WHEN OTHERS		=> result <= carry & akku_int;
		END CASE;
	END PROCESS calculate;
	
	-- Stores the result to akku and carry
	store : PROCESS(clk, res_n)
	BEGIN
		IF res_n = '0' THEN
			akku_int <= (OTHERS => '0');
			carry <= "0";
			IF mul_on THEN
				akkub_int <= (OTHERS => '0');
				IF mac_for_mul THEN
					akkuc_int <= (OTHERS => '0');
					akkud_int <= (OTHERS => '0');
				END IF;
			END IF;
		ELSIF rising_edge(clk) THEN
		
			-- Store akku and carry
			IF do_op = '1' THEN  
				akku_int <= result((data_width-1) DOWNTO 0);
				carry <= result(data_width DOWNTO data_width);
				
			-- Store additional Registers
				-- With MAC	
				IF mul_on AND mac_for_mul THEN
					IF operation = mul_i THEN
						akkub_int <= result((data_width-1) DOWNTO 0);
						akkuc_int <= result_2;
						akkud_int <= result_3;
					ELSIF operation = xchg_i THEN
						CASE operand(1 DOWNTO 0) IS
							WHEN "00" => akkub_int <= akku_int;
							WHEN "01" => akkuc_int <= akku_int;
							WHEN "10" => akkud_int <= akku_int;
							WHEN "11" => akkub_int <= (OTHERS => '0');
											 akkuc_int <= (OTHERS => '0');
											 akkud_int <= (OTHERS => '0');
							WHEN OTHERS => NULL;
						END CASE;
					END IF;	
					
				-- With Mul
				ELSIF mul_on THEN
					akkub_int <= result_2;
				END IF;
								
			END IF;
		END IF;
	END PROCESS store;
	
	skip_decide : PROCESS(operation, operand, akku_int, carry)
	BEGIN
		CASE operation IS
			WHEN c_i		=> skip <= carry(0);
			WHEN nc_i	=> skip <= NOT carry(0);
			WHEN b_i		=> IF (akku_int > operand) AND adv_skips_on THEN
									skip <= '1';
								ELSE
									skip <= '0';
								END IF;
			WHEN s_i		=> IF (akku_int < operand) AND adv_skips_on THEN
									skip <= '1';
								ELSE
									skip <= '0';
								END IF;
			WHEN eq_i	=> IF (akku_int = operand) THEN
									skip <= '1';
								ELSE
									skip <= '0';
								END IF;
			WHEN neq_i	=> IF (akku_int /= operand) THEN
									skip <= '1';
								ELSE
									skip <= '0';
								END IF;
			WHEN OTHERS => skip <= '0';
		END CASE;
	END PROCESS skip_decide;

END ARCHITECTURE rtl;