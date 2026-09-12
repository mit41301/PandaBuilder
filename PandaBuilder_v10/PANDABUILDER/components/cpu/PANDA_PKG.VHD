--*************************************************************************
--* FILE      :   panda_pkg.vhd		                            	  		  *
--* PROJECT   :   Panda                      									  *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       28.04.2008  Bründler Oliver    File written              	  *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This package contains global definitions for the panda processor.	  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************


LIBRARY ieee;
	USE ieee.std_logic_1164.all;

PACKAGE panda_pkg IS
	
	-- Constants
	CONSTANT inst_width : positive := __InstWidth;
	CONSTANT data_width : positive := 8;
	CONSTANT opcode_width : positive := 6;
	CONSTANT data_adr_width : positive := __DataAddrWidth;	
	CONSTANT inst_adr_width : positive := __InstAddrWidth;
	CONSTANT sysstack_width : positive := __SysstackWidth;	-- The bigger one of: data_width, inst_adr_width
	CONSTANT biggest_reg_width : positive := __BiggestRegWidth; -- The biggest one of: data_width, inst_adr_width, data_adr_width

	SUBTYPE inst_t IS std_ulogic_vector((inst_width-1) DOWNTO 0);
	SUBTYPE data_t IS std_ulogic_vector((data_width-1) DOWNTO 0);
	SUBTYPE inst_adr_t IS std_ulogic_vector((inst_adr_width-1) DOWNTO 0);
	SUBTYPE data_adr_t IS std_ulogic_vector((data_adr_width-1) DOWNTO 0);	
	SUBTYPE sysstack_t IS std_ulogic_vector((sysstack_width-1) DOWNTO 0);
	
	SUBTYPE debug_param_t IS std_ulogic_vector(((biggest_reg_width-1)/4+1)*4-1 DOWNTO 0);

	TYPE all_ops IS (-- *** Load / Store ***
							ld_i, 		-- A = Mem 		
							ldi_i, 		-- A = Imm
							ldid_i, 		-- A = (Ind)
							st_i, 		-- Mem = A							
							stid_i,  	-- (Ind) = A
							sidl_i, 		-- IndL = A
							sidh_i, 		-- IndH = A
							sidi_i,		-- Ind = Imm
							chidi_i,		-- Ind = Ind + Imm
							xchg_i,		-- B = A, A = B
							sspi_i,		-- SP = Imm
							push_i,		-- (SP) = A
							pop_i,		-- A = (SP)
							spid_i,		-- Ind = SP
							pushs_i,		-- (SysStack) = A
							pops_i,		-- A = (SysStack)
							-- *** Mathematical / Logical ***
						   add_i, 		-- A = A + Mem
							addi_i, 		-- A = A + Imm
							addid_i,		-- A = A + (Ind)
							addc_i,		-- A = A + Mem + C							
							addci_i,		-- A = A + Imm + C
							addcid_i,	-- A = A + (Ind) + C
							sub_i, 		-- A = A - Mem
							subi_i, 		-- A = A - Imm
							subid_i,		-- A = A - (Ind)
							subc_i,		-- A = A - Mem - C							
							subci_i,		-- A = A - Imm - C
							subcid_i,	-- A = A - (Ind) - C
							mul_i,		-- A & B = A * Mem
							muli_i,		-- A & B = A * Imm
							mulid_i,		-- A & B = A * (Ind)
							rol_i, 		-- A =  (A << 1) & C
							ror_i, 		-- A = C & (A >> 1)
							and_i, 		-- A = A && Mem
							andi_i,		-- A = A && Imm
							andid_i,		-- A = A && (Ind)
							or_i, 		-- A = A || Mem
							ori_i, 		-- A = A || Imm
							orid_i,		-- A = A || (Ind)
							xor_i, 		-- A = A ^^ Mem
							xori_i, 		-- A = A ^^ Imm
							xorid_i,		-- A = A ^^ (Ind)
							swap_i,		-- A = A[Low] & A[High]
							--*** Jumps / Skips ***
							jmp_i,		-- PC = Adr
							call_i, 		-- PC => Stack, PC = Adr
							skc_i, 		-- Skip if C = '1'
							sknc_i, 		-- Skip if C = '0'
							skb_i, 		-- Skip if A > Mem
							skbi_i, 		-- Skip if A > Imm
							skbid_i, 	-- Skip if A > (Ind)
							sks_i, 		-- Skip if A < Mem
							sksi_i, 		-- Skip if A < Imm
							sksid_i,		-- Skip if A < (Ind)
							skeq_i, 		-- Skip if A = Mem
							skeqi_i, 	-- Skip if A = Imm
							skeqid_i,	-- Skip if A = (Ind)
							skneq_i, 	-- Skip if A != Mem
							skneqi_i, 	-- Skip if A != Imm
							skneqid_i,	-- Skip if A != (Ind)
							ret_i, 		-- PC <= Stack
							reti_i, 		-- PC <= Stack, Interrupt Enable
							--*** Control ***
							sc_i, 		-- C = Imm
							si_i, 		-- Interrupt Enalbe = Imm
							nop_i,		-- No Operation
							unused);		
							
	-- Operadions for ALU
	TYPE akku_ops IS	(ld_i, add_i, sub_i, rol_i, ror_i, swap_i,
							 and_i, or_i, xor_i, c_i, nc_i, b_i, s_i, 
							 eq_i, neq_i, sc_i, addc_i, subc_i, nop_i,
							 xchg_i, mul_i);
							 
	-- Operatons for bus
	TYPE bus_ops IS 	(ld_i, st_i, ldid_i, stid_i, chidi_i, spid_i,
							 sidl_i, sidh_i, sidi_i, nop_i, sspi_i, pop_i, push_i);

	-- Get Akku_op out of Op
	FUNCTION get_akku_op (op : all_ops) RETURN akku_ops;

	-- Get Bus_op out of Op
	FUNCTION get_bus_op (operation : all_ops) RETURN bus_ops;

	-- Get Operation from Opcode
	FUNCTION get_op_from_code (code : inst_t) RETURN all_ops;
	
	-- Determines wether a memory read is needed or not (true = memory read is needed)
	FUNCTION mem_read_from_bus_op (bus_op 			: bus_ops;
											 indir_on 		: boolean;
											 user_stack_on	: boolean) RETURN boolean;
	
	-- Determines wether a opcode is a Skip Operation or not (true = skip operation)
	FUNCTION op_is_skip (operation 		: all_ops;
								adv_skips_on	: boolean) RETURN boolean;
END panda_pkg; 

PACKAGE BODY panda_pkg IS	
	
	-- Get Akku_op out of Op
	FUNCTION get_akku_op (op : all_ops) RETURN akku_ops IS
	BEGIN
		CASE op IS 
			WHEN ld_i | ldi_i | ldid_i | 
				  pop_i | pops_i						=> RETURN ld_i;
			WHEN add_i | addi_i | addid_i			=> RETURN add_i;
			WHEN addc_i | addci_i | addcid_i		=> RETURN addc_i;
			WHEN sub_i | subi_i | subid_i			=> RETURN sub_i;
			WHEN subc_i | subci_i | subcid_i		=> RETURN subc_i;
			WHEN rol_i									=> RETURN rol_i;
			WHEN ror_i									=> RETURN ror_i;
			WHEN and_i | andi_i | andid_i			=> RETURN and_i;
			WHEN or_i | ori_i | orid_i				=> RETURN or_i;
			WHEN xor_i | xori_i | xorid_i			=> RETURN xor_i;
			WHEN skc_i 									=> RETURN c_i;
			WHEN sknc_i 								=> RETURN nc_i;
			WHEN skb_i | skbi_i | skbid_i			=> RETURN b_i;
			WHEN sks_i | sksi_i | sksid_i			=> RETURN s_i;
			WHEN skeq_i | skeqi_i | skeqid_i 	=> RETURN eq_i;
			WHEN skneq_i | skneqi_i | skneqid_i	=> RETURN neq_i;
			WHEN sc_i									=> RETURN sc_i;
			WHEN swap_i									=> RETURN swap_i;
			WHEN xchg_i									=> RETURN xchg_i;
			WHEN mul_i | muli_i | mulid_i			=> RETURN mul_i;
			WHEN OTHERS 								=> RETURN nop_i;
		END CASE;
	END FUNCTION get_akku_op;
	
	-- Get Bus_op out of Op
	FUNCTION get_bus_op (operation : all_ops) RETURN bus_ops IS
	BEGIN		
		CASE operation IS
			WHEN ld_i | add_i | sub_i |
				  and_i | or_i | xor_i |
				  skb_i | sks_i | skeq_i |
				  skneq_i | addc_i | 
				  subc_i | mul_i				=> RETURN ld_i;
			WHEN st_i							=> RETURN st_i;
			WHEN ldid_i | addid_i | subid_i |
				  andid_i | orid_i | xorid_i |
				  skbid_i | sksid_i | skeqid_i |
				  skneqid_i | addcid_i | 
				  subcid_i | mulid_i			=> RETURN ldid_i;
			WHEN stid_i							=> RETURN stid_i;
			WHEN sidh_i							=> RETURN sidh_i;
			WHEN sidl_i							=> RETURN sidl_i;
			WHEN sidi_i							=> RETURN sidi_i;
			WHEN chidi_i						=> RETURN chidi_i;
			WHEN sspi_i							=> RETURN sspi_i;
			WHEN push_i							=> RETURN push_i;
			WHEN pop_i							=> RETURN pop_i;
			WHEN spid_i							=> RETURN spid_i;
			WHEN OTHERS							=> RETURN nop_i;
		END CASE;
	END FUNCTION get_bus_op;
	
	-- Get Op from Op-Code
	FUNCTION get_op_from_code (code : inst_t) RETURN all_ops IS
	BEGIN
		CASE code((inst_width-1) DOWNTO (inst_width-opcode_width)) IS
			-- Op-Codes with Dataread (start with "00")
			WHEN "000000" => RETURN ld_i;
			WHEN "000001" => RETURN add_i;
			WHEN "000010" => RETURN sub_i;
			WHEN "000011" => RETURN and_i;
			WHEN "000100" => RETURN or_i;
			WHEN "000101" => RETURN xor_i;
			WHEN "000110" => RETURN skb_i;
			WHEN "000111" => RETURN sks_i;
			WHEN "001000" => RETURN skeq_i;
			WHEN "001001" => RETURN skneq_i;
			WHEN "001010" => RETURN addc_i;
			WHEN "001011" => RETURN subc_i;
			WHEN "001100" => RETURN mul_i;
			WHEN "001101" => RETURN push_i;	-- No Dataread
			WHEN "001110" => RETURN pop_i;	-- No Dataread
			WHEN "001111" => RETURN spid_i;	-- No Dataread
			--  Op-Codes with Immediate Data (start with "01")
			WHEN "010000" => RETURN ldi_i;
			WHEN "010001" => RETURN addi_i;
			WHEN "010010" => RETURN subi_i;
			WHEN "010011" => RETURN andi_i;
			WHEN "010100" => RETURN ori_i;
			WHEN "010101" => RETURN xori_i;
			WHEN "010110" => RETURN skbi_i;
			WHEN "010111" => RETURN sksi_i;
			WHEN "011000" => RETURN skeqi_i;		
			WHEN "011001" => RETURN skneqi_i;
			WHEN "011010" => RETURN addci_i;
			WHEN "011011" => RETURN subci_i;
			WHEN "011100" => RETURN muli_i;
			WHEN "011101" => RETURN si_i;
			WHEN "011110" => RETURN sidi_i;
			WHEN "011111" => RETURN chidi_i;
			-- Op-Codes without Data (start with "10")
			WHEN "100000" => RETURN st_i;
			WHEN "100001" => RETURN stid_i;
			WHEN "100010" => RETURN sidl_i;
			WHEN "100011" => RETURN sidh_i;
			WHEN "100100" => RETURN rol_i;
			WHEN "100101" => RETURN ror_i;
			WHEN "100110" => RETURN jmp_i;
			WHEN "100111" => RETURN call_i;
			WHEN "101000" => RETURN ret_i;
			WHEN "101001" => RETURN sknc_i;
			WHEN "101010" => RETURN skc_i;
			WHEN "101011" => RETURN reti_i;
			WHEN "101100" => RETURN swap_i;
			WHEN "101101" => RETURN sspi_i;
			WHEN "101110" => RETURN xchg_i;
			WHEN "101111" => RETURN sc_i;
			-- Op-Codes with Indirect Data (start with "11")
			WHEN "110000" => RETURN ldid_i;
			WHEN "110001" => RETURN addid_i;
			WHEN "110010" => RETURN subid_i;
			WHEN "110011" => RETURN andid_i;
			WHEN "110100" => RETURN orid_i;
			WHEN "110101" => RETURN xorid_i;
			WHEN "110110" => RETURN skbid_i;
			WHEN "110111" => RETURN sksid_i;
			WHEN "111000" => RETURN skeqid_i;
			WHEN "111001" => RETURN skneqid_i;
			WHEN "111010" => RETURN addcid_i;
			WHEN "111011" => RETURN subcid_i;
			WHEN "111100" => RETURN mulid_i;
			WHEN "111101" => RETURN pops_i;
			WHEN "111110" => RETURN pushs_i;
			WHEN OTHERS	  => RETURN nop_i;
		END CASE;
	END FUNCTION get_op_from_code;		
	
	-- Determines wether a memory read is needed or not (true = memory read is needed)
	FUNCTION mem_read_from_bus_op(bus_op	 		: bus_ops; 
											indir_on 		: boolean;
											user_stack_on	: boolean) RETURN boolean IS
	BEGIN
		IF indir_on AND user_stack_on THEN
			RETURN bus_op = ld_i OR bus_op = ldid_i OR bus_op = pop_i;
		ELSIF indir_on AND (NOT user_stack_on) THEN
			RETURN bus_op = ld_i OR bus_op = ldid_i;
		ELSIF (NOT indir_on) AND user_stack_on THEN
			RETURN bus_op = ld_i OR bus_op = pop_i;
		ELSE
			RETURN bus_op = ld_i;
		END IF;
	END FUNCTION mem_read_from_bus_op;
	
	-- Determines wether a opcode is a Skip Operation or not (true = skip operation)
	FUNCTION op_is_skip (operation 		: all_ops;
								adv_skips_on	: boolean) RETURN boolean IS
	BEGIN
		CASE operation IS
			WHEN skc_i | sknc_i |
				  skeq_i | skeqi_i |
				  skneq_i | skneqi_i	=> RETURN true;
			WHEN skb_i | skbi_i | 
				  sks_i | sksi_i 		=> IF adv_skips_on THEN
													RETURN true;
												ELSE
													RETURN false;
												END IF;
			WHEN OTHERS					=> RETURN false;
		END CASE;
	END FUNCTION op_is_skip;
			
			
END PACKAGE BODY panda_pkg;
