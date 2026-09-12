--*************************************************************************
--* FILE      :   ASCII_CODE.vhd		                                  	  *
--* PROJECT   :   None		                                               *
--*                                                                       *
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      *
--* 1.0       28.04.2008  Bründler Oliver    Package written              *
--*                                                                       *
--* USED BY                                                               *
--* Logic Solutions Bründler					                                *
--*                                                                       *
--* INTRODUCTION                                                          *
--* This Package includes some useful constants and functions to 		     *
--* code / decode ASCII from an to std_ulogic_vector							  *
--*                                                                       *
--* COPYRIGHT (C) 2008  by Logic Solutions Bründler CH-6043 Adligenswil   *
--*************************************************************************

LIBRARY ieee;
	USE ieee.std_logic_1164.all;
	USE ieee.numeric_std.all;

PACKAGE ASCII_CODE IS
	
	SUBTYPE ascii_type IS std_ulogic_vector(7 DOWNTO 0);
	
	-- Column 0
	CONSTANT ASCII_NUL 	: ascii_type := X"00";	-- NUL
	CONSTANT ASCII_SOH 	: ascii_type := X"01";	-- SOH
	CONSTANT ASCII_STX 	: ascii_type := X"02";	-- STX
	CONSTANT ASCII_ETX 	: ascii_type := X"03";	-- ETX
	CONSTANT ASCII_EOT 	: ascii_type := X"04";	-- EOT
	CONSTANT ASCII_ENQ 	: ascii_type := X"05";	-- ENQ
	CONSTANT ASCII_ACK 	: ascii_type := X"06";	-- ACK
	CONSTANT ASCII_BELL  : ascii_type := X"07";	-- Bell
	CONSTANT ASCII_BS 	: ascii_type := X"08";	-- BS

	CONSTANT ASCII_HT 	: ascii_type := X"09";  -- HT
	CONSTANT ASCII_LF 	: ascii_type := X"0A";	-- LF
	CONSTANT ASCII_VT 	: ascii_type := X"0B";	-- VT
	CONSTANT ASCII_FF 	: ascii_type := X"0C";	-- FF
	CONSTANT ASCII_CR 	: ascii_type := X"0D";	-- CR
	CONSTANT ASCII_SO 	: ascii_type := X"0E";	-- SO
	CONSTANT ASCII_SI 	: ascii_type := X"0F";	-- SI
	-- Column 1
	CONSTANT ASCII_DLE 	: ascii_type := X"10";	-- DLE
	CONSTANT ASCII_DC1 	: ascii_type := X"11";	-- DC1 
	CONSTANT ASCII_DC2 	: ascii_type := X"12";	-- DC2
	CONSTANT ASCII_DC3 	: ascii_type := X"13";	-- DC3
	CONSTANT ASCII_DC4 	: ascii_type := X"14";	-- DC4 
	CONSTANT ASCII_NAK 	: ascii_type := X"15";	-- NAK 
	CONSTANT ASCII_SYN 	: ascii_type := X"16";	-- SYN
	CONSTANT ASCII_ETB   : ascii_type := X"17";	-- ETB 
	CONSTANT ASCII_CAN 	: ascii_type := X"18";	-- CAN

	CONSTANT ASCII_EM 	: ascii_type := X"19";  -- EM
	CONSTANT ASCII_SUB 	: ascii_type := X"1A";	-- SUB 
	CONSTANT ASCII_ESC 	: ascii_type := X"1B";	-- ESC
	CONSTANT ASCII_FS 	: ascii_type := X"1C";	-- FS 
	CONSTANT ASCII_GS 	: ascii_type := X"1D";	-- GS
	CONSTANT ASCII_RS 	: ascii_type := X"1E";	-- RS
	CONSTANT ASCII_US 	: ascii_type := X"1F";	-- US 
	-- Column 2
	CONSTANT ASCII_SPAC 	: ascii_type := X"20";	-- Space
	CONSTANT ASCII_EXCL	: ascii_type := X"21";	-- ! 
	CONSTANT ASCII_QUOT 	: ascii_type := X"22";	-- "
	CONSTANT ASCII_ROUT 	: ascii_type := X"23";	-- #
	CONSTANT ASCII_PERC 	: ascii_type := X"24";	-- % 
	CONSTANT ASCII_DOLL 	: ascii_type := X"25";	-- $ 
	CONSTANT ASCII_AND 	: ascii_type := X"26";	-- &
	CONSTANT ASCII_INCO 	: ascii_type := X"27";	-- '
	CONSTANT ASCII_BRO   : ascii_type := X"28";	-- (
	CONSTANT ASCII_BRC 	: ascii_type := X"29";	-- )
	CONSTANT ASCII_STAR	: ascii_type := X"2A";  -- *
	CONSTANT ASCII_PLUS 	: ascii_type := X"2B";	-- + 
	CONSTANT ASCII_COMA 	: ascii_type := X"2C";	-- ,
	CONSTANT ASCII_MINU	: ascii_type := X"2D";	-- - 
	CONSTANT ASCII_DOT 	: ascii_type := X"2E";	-- .
	CONSTANT ASCII_SLAS 	: ascii_type := X"2F";	-- /
	-- Column 3
	CONSTANT ASCII_0 		: ascii_type := X"30";	-- 0
	CONSTANT ASCII_1		: ascii_type := X"31";	-- 1 
	CONSTANT ASCII_2		: ascii_type := X"32";	-- 2
	CONSTANT ASCII_3	 	: ascii_type := X"33";	-- 3
	CONSTANT ASCII_4	 	: ascii_type := X"34";	-- 4 
	CONSTANT ASCII_5	 	: ascii_type := X"35";	-- 5
	CONSTANT ASCII_6	 	: ascii_type := X"36";	-- 6
	CONSTANT ASCII_7	 	: ascii_type := X"37";	-- 7
	CONSTANT ASCII_8		: ascii_type := X"38";	-- 8
	CONSTANT ASCII_9	 	: ascii_type := X"39";	-- 9
	CONSTANT ASCII_COLO	: ascii_type := X"3A";  -- :
	CONSTANT ASCII_SCOL 	: ascii_type := X"3B";	-- ; 
	CONSTANT ASCII_SMAL 	: ascii_type := X"3C";	-- <
	CONSTANT ASCII_EQU	: ascii_type := X"3D";	-- = 
	CONSTANT ASCII_BIG 	: ascii_type := X"3E";	-- >
	CONSTANT ASCII_INTE 	: ascii_type := X"3F";	-- ?
	-- Column 4
	CONSTANT ASCII_AT		: ascii_type := X"40";	-- @
	CONSTANT ASCII_A		: ascii_type := X"41";	-- A 
	CONSTANT ASCII_B		: ascii_type := X"42";	-- B
	CONSTANT ASCII_C	 	: ascii_type := X"43";	-- C
	CONSTANT ASCII_D	 	: ascii_type := X"44";	-- D 
	CONSTANT ASCII_E	 	: ascii_type := X"45";	-- E
	CONSTANT ASCII_F	 	: ascii_type := X"46";	-- F
	CONSTANT ASCII_G	 	: ascii_type := X"47";	-- G
	CONSTANT ASCII_H		: ascii_type := X"48";	-- H
	CONSTANT ASCII_I	 	: ascii_type := X"49";	-- I
	CONSTANT ASCII_J		: ascii_type := X"4A";  -- J
	CONSTANT ASCII_K	 	: ascii_type := X"4B";	-- K 
	CONSTANT ASCII_L	 	: ascii_type := X"4C";	-- L
	CONSTANT ASCII_M		: ascii_type := X"4D";	-- M 
	CONSTANT ASCII_N	 	: ascii_type := X"4E";	-- N
	CONSTANT ASCII_O	 	: ascii_type := X"4F";	-- O
	-- Column 5
	CONSTANT ASCII_P		: ascii_type := X"50";	-- P
	CONSTANT ASCII_Q		: ascii_type := X"51";	-- Q 
	CONSTANT ASCII_R		: ascii_type := X"52";	-- R
	CONSTANT ASCII_S	 	: ascii_type := X"53";	-- S
	CONSTANT ASCII_T	 	: ascii_type := X"54";	-- T 
	CONSTANT ASCII_U	 	: ascii_type := X"55";	-- U
	CONSTANT ASCII_V	 	: ascii_type := X"56";	-- V
	CONSTANT ASCII_W	 	: ascii_type := X"57";	-- W
	CONSTANT ASCII_X		: ascii_type := X"58";	-- X
	CONSTANT ASCII_Y 		: ascii_type := X"59";	-- Y
	CONSTANT ASCII_Z		: ascii_type := X"5A";  -- Z
	CONSTANT ASCII_SBRO 	: ascii_type := X"5B";	-- [ 
	CONSTANT ASCII_BSLA 	: ascii_type := X"5C";	-- \ 
	CONSTANT ASCII_SBRC	: ascii_type := X"5D";	-- ] 
	CONSTANT ASCII_ROOF	: ascii_type := X"5E";	-- ^
	CONSTANT ASCII_ULIN	: ascii_type := X"5F";	-- _
	-- Column 6
	CONSTANT ASCII_APPO	: ascii_type := X"60";	-- ´
	CONSTANT ASCII_a_s	: ascii_type := X"61";	-- a 
	CONSTANT ASCII_b_s	: ascii_type := X"62";	-- b
	CONSTANT ASCII_c_s 	: ascii_type := X"63";	-- c
	CONSTANT ASCII_d_s 	: ascii_type := X"64";	-- d 
	CONSTANT ASCII_e_s 	: ascii_type := X"65";	-- e
	CONSTANT ASCII_f_s 	: ascii_type := X"66";	-- f
	CONSTANT ASCII_g_s 	: ascii_type := X"67";	-- g
	CONSTANT ASCII_h_s	: ascii_type := X"68";	-- h
	CONSTANT ASCII_i_s 	: ascii_type := X"69";	-- i
	CONSTANT ASCII_j_s	: ascii_type := X"6A";  -- j
	CONSTANT ASCII_k_s 	: ascii_type := X"6B";	-- k 
	CONSTANT ASCII_l_s	: ascii_type := X"6C";	-- l 
	CONSTANT ASCII_m_s	: ascii_type := X"6D";	-- m 
	CONSTANT ASCII_n_s	: ascii_type := X"6E";	-- n
	CONSTANT ASCII_o_s	: ascii_type := X"6F";	-- o
	-- Column 7
	CONSTANT ASCII_p_s	: ascii_type := X"70";	-- p
	CONSTANT ASCII_q_s	: ascii_type := X"71";	-- q 
	CONSTANT ASCII_r_s	: ascii_type := X"72";	-- r
	CONSTANT ASCII_s_s	: ascii_type := X"73";	-- s
	CONSTANT ASCII_t_s 	: ascii_type := X"74";	-- t 
	CONSTANT ASCII_u_s 	: ascii_type := X"75";	-- u
	CONSTANT ASCII_v_s	: ascii_type := X"76";	-- v
	CONSTANT ASCII_w_s 	: ascii_type := X"77";	-- w
	CONSTANT ASCII_x_s	: ascii_type := X"78";	-- x
	CONSTANT ASCII_y_s 	: ascii_type := X"79";	-- y
	CONSTANT ASCII_z_s	: ascii_type := X"7A";  -- z
	CONSTANT ASCII_CBRO 	: ascii_type := X"7B";	-- { 
	CONSTANT ASCII_VERT 	: ascii_type := X"7C";	-- | 
	CONSTANT ASCII_CBRC	: ascii_type := X"7D";	-- } 
	CONSTANT ASCII_WAVE	: ascii_type := X"7E";	-- ~
	CONSTANT ASCII_DEL	: ascii_type := X"7F";	-- Delete
	
	-- Converts an ASCII into a Hex Cipher
	FUNCTION hex_from_ascii (ascii : ascii_type) RETURN std_ulogic_vector;
	
	-- Converts a Hex Cipher into ASCII
	FUNCTION ascii_from_hex (hex : std_ulogic_vector(3 DOWNTO 0)) RETURN ascii_type;
	
END ASCII_CODE;

PACKAGE BODY ASCII_CODE IS
	-- Converts an ASCII into a Hex Cipher
	FUNCTION hex_from_ascii (ascii : ascii_type) RETURN std_ulogic_vector IS
	BEGIN 
		CASE ascii IS
			WHEN ASCII_0 | ASCII_1 | ASCII_2 |
				  ASCII_3 | ASCII_4 | ASCII_5	|
				  ASCII_6 | ASCII_7 | ASCII_8 |
				  ASCII_9								=> RETURN ascii(3 DOWNTO 0);
			WHEN OTHERS									=> RETURN std_ulogic_vector((unsigned(ascii(3 DOWNTO 0)) + 9) mod 16);
		END CASE;
	END FUNCTION hex_from_ascii;
	
	-- Converts a Hex Cipher into ASCII
	FUNCTION ascii_from_hex (hex : std_ulogic_vector(3 DOWNTO 0)) RETURN ascii_type IS
	BEGIN
		IF unsigned(hex) < 10 THEN
			RETURN X"3" & hex;
		ELSE
			RETURN X"4" & std_ulogic_vector(unsigned(hex) - 9);
		END IF;
	END FUNCTION ascii_from_hex;
END PACKAGE BODY ASCII_CODE;