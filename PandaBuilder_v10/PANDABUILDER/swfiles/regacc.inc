;****************************************
;*** Register Access Macros for PANDA ***
;****************************************

#NOLIST

;*** Set Register ***				
REG_SET 		Macro	register, value	;Sets a Register to the Value of a Variable			
				LDA	value				
				STA	register
	     		Endmacro
        	
REG_SET		Macro register, #value	;Sets a Register to an immediate Value	
				LDA	#value			
				STA	register
				Endmacro				
			
;*** Set Bits in a Register ***	
REG_SETB		Macro	register, value	;Sets all Bits of the Register which are			
				LDA	register				;'1' in the Value of a Variable
				OR		value				
				STA	register
	        	Endmacro
        	
REG_SETB		Macro	register, #value	;Sets all Bits of the Register which are
				LDA	register				;'1' in an immediate Value
				OR		#value			
				STA	register
				Endmacro
        	
;*** Clear Bits in a Register ***
REG_CLRB		Macro	register, value	;Clears all Bits of the Register which are
				LDA	value					;'1' in the Value of a Variable
				INV				
				AND	register
				STA	register
				Endmacro
			
REG_CLRB		Macro	register, #value	;Clears all Bits of the Register which are
				LDA	#value				;'1' in an immediate Value
				INV			
				AND	register
				STA	register
				Endmacro
				
;*** Set 16-Bit register ***
;Variables: LSB in Lower Address, MSB in Higher Address
REG_SET16	Macro	register, value	;Sets a REgister to the Value of a Variable
				LDA	value
				STA	register
				LDA	value+1
				STA	register+1
				Endmacro
				
REG_SET16	Macro	register, #value	;Sets a Register to an Immediate Value
				LDA	#(value%256)
				STA	register
				LDA	#(value/256)
				STA	register+1
				Endmacro
				
;*** Read 16-Bit Register into Variable ***
;Variables: LSB in Lower Address, MSB in Higher Address
REG_READ16	Macro	register, variable
				LDA	register
				STA	variable
				LDA	register+1
				STA	variable+1
				Endmacro

			
	
			

			

