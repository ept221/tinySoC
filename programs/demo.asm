        ldi r0, 1               ; set pin 1 to output
        out r0, 0 

        ldi r14, 0xff             ; setup the stack pointer


        ldi r0, 0b00011110        ; setup the gpu control register
        out r0, 0b10000000

        ldi r2, 0x00            ; setup the vram pointer
        ldi r3, 0x20

        ssr 8                   ; enable interrupts
loop:   jmp loop                ; do nothing and wait for an interrupt




isr:    in r0, 2                ; read pin 1
        xoi r0, 1               ; flip the bit
        out r0 1                ; toggle pin 1
        ldi r0, 65
        str r0, r2
        ssr 8                   ; enable interrupts
        ret                     ; return