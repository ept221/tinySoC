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
        
        push r0
        push r1
        push r4
        push r5
        push r6

        mov r2, r1              ; move the multiplier to r2
        ldi r1, 0
        ldi r3, 8               ; counter
        ldi r4, 0
        ldi r5, 0

loop:   cpi r3, 0
        bz end

        ldi r6, 1
        and r6, r2
        bz shift

        add r4, r0
        adc r5, r1

shift:  sll r0
        rlc r1

        srl r2
        adi r3, -1
        br loop

end:    mvp p2, p4

        pop r6
        pop r5
        pop r4
        pop r1
        pop r0

        ret
;******************************************************************************
div:    ; r0 is the dividened
        ; r1 is the divisor
        ; r2 holds the quotient
        ; r3 holds the remainder

        push r4
        push r5

        mov r3, r1   
        ldi r1, 0    

        ldi r4, 8

loop1:  cpi r4, 0
        bz end1

        sll r0
        rlc r1

        sub r1, r3
        mov r5, r1
        ani r5, 0x80
        bz other
        ani r0, 0xfe
        add r1, r3
        br foo
other:  ori r0, 1
foo:    adi r4, -1
        br loop1

end1:   mvp p2, p0

        pop r5
        pop r4
                
        ret
;******************************************************************************