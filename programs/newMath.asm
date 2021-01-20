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
        call mult

poll:   in r1, uart_ctrl
        ani r1, 2
        jz poll                 ; poll for empty buffer

print:  out r2, uart_buffer     ; print the lsbs
        hlt
;******************************************************************************
mult:   ; r0 is the multiplicand
        ; r1 is the multiplier
        ; r2 and r3 will hold the results
        
        push r4
        push r5
        push r6

        mov r2, r1              ; move the multiplier to r2
        ldi r1, 0
        ldi r3, 8               ; counter
        ldi r4, 0
        ldi r5, 0
        ldi r7, 0

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
        adi r7, 1
        br loop

end:    mov r2, r4
        mov r3, r5

        pop r6
        pop r5
        pop r4

        ret
;******************************************************************************