;******************************************************************************
        .define uart_baud, 0x0A
        .define uart_ctrl, 0x0B
        .define uart_buffer, 0x0C
;******************************************************************************         
        .code

        ldi r14, 0xff           ; set the stack pointer
        ldi r15, 0x00

        ldi r0, 103
        out r0, uart_baud       ; set the baud rate to 9600

        ldi r0, 11
        ldi r1, 3
        call div

poll:   in r1, uart_ctrl
        ani r1, 2
        jz poll                 ; poll for empty buffer

print:  out r2, uart_buffer     ; print the lsbs
        hlt
;******************************************************************************
mult:   ; r0 is the multiplicand
        ; r1 is the multiplier
        ; r2 and r3 will hold the results
        
        srd r4, p14
        srd r5, p14
        srd r6, p14

        mov r2, r1              ; move the multiplier to r2
        ldi r1, 0
        ldi r3, 8               ; counter
        ldi r4, 0
        ldi r5, 0

loop:   cpi r3, 0
        jz end

        ldi r6, 1
        and r6, r2
        jz shift

        add r4, r0
        adc r5, r1

shift:  ldi r6, 0
        sll r0                  ; shift lsbs of the multiplicand 
        jnc no_c
        ldi r6, 1
no_c:   sll r1                  ; shift the msbs of the multiplicand
        add r1, r6

        srl r2
        adi  r3, -1
        jmp loop

end:    mov r2, r4
        mov r3, r5

        lri r6, p14
        lri r5, p14
        lri r4, p14

        ret
;******************************************************************************
div:	; r0 is the dividened
		; r1 is the divisor
		; r2 holds the quotient
		; r3 holds the remainder

		srd r4, p14
        srd r5, p14

		mov r3, r1   
		ldi r1, 0    

		ldi r4, 8

loop1:	cpi r4, 0
		jz end1

		ldi r5, 0
		sll r0
		jnc no_c1
		ldi r5, 1
no_c1:	sll r1
		add r1, r5

		sub r1, r3
		mov r5, r1
		ani r5, 0x80
		jz other
		ani r0, 0xfe
		add r1, r3
		jmp foo
other:	ori r0, 1
foo:	adi r4, -1
		jmp loop1

end1:	mov r2, r0
		mov r3, r1

		lri r5, p14
        lri r4, p14
		
		ret
;******************************************************************************