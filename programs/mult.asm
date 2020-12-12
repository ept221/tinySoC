;******************************************************************************
        .define uart_baud, 0x0A
        .define uart_ctrl, 0x0B
        .define uart_buffer, 0x0C
;******************************************************************************         
        .code

        ldi r0, 103
        out r0, uart_baud       ; set the baud rate to 9600

mult:	ldi r0, 5 				; the multiplicand is stored in {r1,r0}
		ldi r1, 0

		ldi r2, 5				; the multiplier is stored in r2
		
		ldi r3, 8				; counter

		ldi r4, 0				; the result is put in {r4, r5}
		ldi r5, 0

loop:	cpi r3, 0
		jz end

		ldi r6, 1
		and r6, r2
		jz shift

		add r4, r0
		adc r5, r1

shift:  ldi r6, 0
		sll r0          		; shift lsbs of the multiplicand 
        jnc no_c
        ldi r6, 1
no_c:	sll r1          		; shift the msbs of the multiplicand
		add r1, r6

		srl r2
		adi  r3, -1
		jmp loop

end:	in r6, uart_ctrl
        ani r6, 2
        jz end                  ; poll for empty buffer

        out r4, uart_buffer     ; print the lsbs
        hlt