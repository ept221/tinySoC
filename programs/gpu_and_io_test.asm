        .code
        ldi r0, 1
        out r0, 0       ; set the first pin to output
        ldi r0, 0x00    ; setup gpu pointer
        ldi r1, 0x20

poll:   in r2, 2        ; read pin register
        ani r2, 2       ; mask the button
        srl r2          ; get the state of the button in the lsb
        out r2, 1       ; set the led to the state of the button
        adi r2, 48      ; calculate the ascii (0 or 1) state of the button
        str r2, p0      ; write the char to the screen
        jmp poll        ; poll the button again