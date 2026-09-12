#CPU PROTEUS								;Tells the Assembler which CPU is used

#SYMLIST										;Tells the Assembler to list all Symbols after compilation

;*****************************
;*** Peripherial Registers ***
;*****************************
				DSEG 		PORTS
				REGORG	0000h
a				RMW		1
b				RMW 		1									
		

;*********************
;*** Main Programm ***
;*********************
				CSEG		CODE	
start			LDR	R3, #0AAh