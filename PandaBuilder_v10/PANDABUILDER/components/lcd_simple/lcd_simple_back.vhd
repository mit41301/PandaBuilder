--**************************************************************************
--* FILE      :   lcd_simple.vhd		                            	  		*
--* PROJECT   :   PANDA BUILDER                    							  	*
--*                                                                       	*
--* VERSION   DATE	     PROGRAMMER	      REMARKS                      	*
--* 1.0       03.09.2008  Bründler Oliver    File written              	  	*
--*                                                                       	*
--* USED BY                                                               	*
--* Logic Solutions Bründler					                                	*
--*                                                                       	*
--* INTRODUCTION                                                          	*
--* This block is a LCD controller. It allows to read/write the different	*
--* registers of a standard 16x2 LCD over 8-bit interface						*
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
ENTITY lcd_simple IS
	GENERIC (
		clk_frequency	: integer := 10000000
	);
	PORT (
		-- *** Standard Ports ***
		clk				: IN	std_logic;
		res_n				: IN	std_logic;
		-- *** Bus Ports ***
		cs					: IN	std_logic;
		din				: IN	std_logic_vector(7 DOWNTO 0);
		dout				: OUT	std_logic_vector(7 DOWNTO 0);
		wr					: IN	std_logic;
		rd					: IN	std_logic;
		adr				: IN 	std_logic_vector(1 DOWNTO 0);
		int				: OUT std_logic;
		-- *** External Ports ***
		rs					: OUT std_logic;
		rw					: OUT std_logic;
		en					: OUT std_logic;
		dbus				: INOUT std_logic_vector(7 DOWNTO 0)
	);
END ENTITY lcd_simple;

----------------------------------------------------------------------------
--  Architecture
----------------------------------------------------------------------------
ARCHITECTURE rtl OF lcd_simple IS
																									-- BASE + 0x00 = INST 	W
																									-- BASE + 0x01 = DATA	W
	SIGNAL state_reg	: std_logic_vector(1 DOWNTO 0);								-- BASE + 0x02 = STATE	R/W
	SIGNAL int_reg		: std_logic;														-- BASE + 0x03 = INT		R/W
	
	SIGNAL busy_sync : std_logic;
	
	ALIAS	busy IS state_reg(1);
	ALIAS inton IS state_reg(0);
BEGIN

----------------------------------------------------------------------------
--  reg_access Process
----------------------------------------------------------------------------
reg_access : PROCESS(clk, res_n)
BEGIN
	-- Reset
	IF res_n = '0' THEN
		dout <= (OTHERS => '0');
		inton <= '0';
	ELSIF rising_edge(clk) THEN
		-- Register Access
		IF cs = '1' THEN
			-- Write Access
			IF wr = '1' THEN
				CASE adr IS
					WHEN "00" =>	NULL;							-- INST (is implemented in lcd_access)
					WHEN "01" =>	NULL;							-- DATA (is implemented in lcd_access)
					WHEN "10" =>	inton <= din(0);			-- STATE
					WHEN "11" => 	NULL;							-- INT (is implemented in int_control)
					WHEN OTHERS => NULL;
				END CASE;
			-- Read Access
			ELSIF rd = '1' THEN
			dout <= (OTHERS => '0');
				CASE adr IS
					WHEN "10" =>	dout(1 DOWNTO 0) <= state_reg;	-- STATE
					WHEN "11" =>	dout(0) <= int_reg;					-- INT
					WHEN OTHERS => dout <= (OTHERS => 'X');
				END CASE;
			END IF;
		END IF;
	END IF;
END PROCESS reg_access;

----------------------------------------------------------------------------
--  lcd_access Process
----------------------------------------------------------------------------
lcd_access : PROCESS(clk, res_n)
	CONSTANT DELAY : integer := clk_frequency/2000000;								-- 500ns delay (min 1 clock cycle)
	VARIABLE delay_counter : integer RANGE 0 TO DELAY;
	TYPE state IS (idle, before_en, rise_en, during_en, fall_en, after_en); 
	VARIABLE my_state, next_state : state;
	VARIABLE tick : boolean;
	VARIABLE write_dat : std_logic_vector(7 DOWNTO 0);
	VARIABLE write_rs : std_logic;
BEGIN
	-- Reset
	IF res_n = '0' THEN
		busy <= '0';
		write_dat := (OTHERS => '0');
		write_rs := '0';
		rs <= '0';
		rw <= '0';
		en <= '0';
		dbus <= (OTHERS => 'Z');
		delay_counter := 0;
		my_state := idle;
		tick := false;
	ELSIF rising_edge(clk) THEN
		-- Delay Counter
		tick := (delay_counter = DELAY);
		IF (delay_counter = DELAY) OR (cs = '1' AND wr = '1' AND adr(1) = '0') THEN
			delay_counter := 0;
		ELSE
			delay_counter := delay_counter + 1;
		END IF;
		-- Statemachine
		CASE my_state IS
			WHEN idle =>			-- Next State
										IF cs = '1' AND wr = '1' AND adr(1) = '0' THEN
											next_state := before_en;
										ELSE
											next_state := idle;
										END IF;
										-- Internal Signals
										write_dat := din;
										write_rs := adr(0);
										-- LCD Signals
										rs <= '0';
										rw <= '1';
										en <= '0';
										dbus <= (OTHERS => 'Z');
										IF tick THEN
											busy <= busy_sync;
										END IF;
			WHEN before_en =>		-- Next State
										IF tick THEN
											next_state := rise_en;
										ELSE
											next_state := before_en;
										END IF;
										-- Internal Signals
										busy <= '1';
										-- LCD Signals
										rs <= write_rs;
										rw <= '0';										
			WHEN rise_en =>		-- Next State
										IF tick THEN
											next_state := during_en;
										ELSE
											next_state := rise_en;
										END IF;
										-- LCD Signals
										en <= '1';
			WHEN during_en =>		-- Next State
										IF tick THEN
											next_state := fall_en;
										ELSE
											next_state := during_en;
										END IF;
										-- LCD Signals
										dbus <= write_dat;
			WHEN fall_en =>		-- Next State
										IF tick THEN
											next_state := after_en;
										ELSE
											next_state := fall_en;
										END IF;
										-- LCD Signals
										en <= '0';	
			WHEN after_en =>		-- Next State
										IF tick THEN
											next_state := idle;
										ELSE
											next_state := after_en;
										END IF;
										-- LCD Signals
										dbus <= (OTHERS => 'Z');
			WHEN OTHERS => 		next_state := idle;
		END CASE;
		my_state := next_state;
	END IF;
END PROCESS lcd_access;

----------------------------------------------------------------------------
--  int_control Process
----------------------------------------------------------------------------
int_control : PROCESS(clk, res_n)
	VARIABLE busy_reg : std_logic;
	VARIABLE busy_old : std_logic;
BEGIN
	IF res_n = '0' THEN
		busy_reg := '0';
		busy_sync <= '0';
		busy_old := '0';
		int_reg <= '0';
	ELSIF rising_edge(clk) THEN		
		IF cs = '1' AND wr = '1' AND adr = "11" THEN
			int_reg <= int_reg AND din(0);
		ELSIF busy_sync = '0' AND busy_old = '1' THEN
			int_reg <= '1';
		END IF;
		busy_old := busy_sync;
		busy_sync <= busy_reg;
		busy_reg := dbus(7);
	END IF;
END PROCESS int_control;

int <= int_reg AND inton;

END ARCHITECTURE rtl;
