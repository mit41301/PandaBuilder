;Pseudo Instructions Used
#NOLIST

JEQ		Macro	val, adr		;Jump if equal direct
			SKNEQ	val
			JMP	adr
			Endmacro

JEQ		Macro	#val, adr	;Jump if equal immediate
			SKNEQ	#val
			JMP	adr
			Endmacro
		
JNEQ		Macro	val, adr			;Jump if not equal direct
			SKEQ	val
			JMP	adr
			Endmacro

JNEQ		Macro	#val, adr		;Jump if not equal immediate
			SKEQ	#val
			JMP	adr
			Endmacro
			
JCA		Macro	adr				;Jump if Carry
			SKNC
			JMP	adr
			Endmacro
			
JNCA		Macro adr				;Jump if not Carry
			SKC
			JMP	adr
			Endmacro

JBI		Macro val, adr			;Jump if bigger direct
			SKB	val
			JMP	@2
			JMP	adr	
			Endmacro
			
JBI		Macro #val, adr		;Jump if bigger immediate
			SKB	#val
			JMP	@2
			JMP	adr
			Endmacro
			
JSM		Macro	val, adr			;Jump if smaller direct
			SKS	val
			JMP	@2
			JMP	adr
			Endmacro

JSM		Macro	#val, adr		;Jump if smaller immediate
			SKS	#val
			JMP	@2
			JMP	adr
			Endmacro
			
ADD16		Macro val1, val2, res		;16-bit addition direct (LB on lower address)
			LDA	val1
			ADD	val2
			STA	res
			LDA	val1+1
			ADDC	val2+1
			STA	res+1
			Endmacro	
			
ADD16		Macro val1, #val2, res		;16-bit addition immediate (LB on lower address)
			LDA	val1
			ADD	#val2
			STA	res
			LDA	val1+1
			ADDC	#val2+1
			STA	res+1
			Endmacro
			
SUB16		Macro val1, val2, res		;16-bit subtraction direct (LB on lower address)
			LDA	val1
			SUB	val2
			STA	res
			LDA	val1+1
			SUBC	val2+1
			STA	res+1
			Endmacro	
			
SUB16		Macro val1, #val2, res		;16-bit subtraction immediate (LB on lower address)
			LDA	val1
			SUB	#val2
			STA	res
			LDA	val1+1
			SUBC	#val2+1
			STA	res+1
			Endmacro
				
COMP		Macro				;Tows Complement of A
			INV	A
			ADD	#1
			Endmacro
			
	
			

			

