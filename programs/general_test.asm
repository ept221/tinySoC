        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02
        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
        .define gpu_isr_vector, 0x0020
        .define top_isr_vector, 0x0030
;******************************************************************************
        .code
        
        ldi r0, 1
        out r0, dir_reg         ; set the first pin to output

        ldi r0, gpu_addr[l]     ; setup gpu pointer
        ldi r1, gpu_addr[h]

        ldi r14, 0xff           ; set stack pointer

        ldi r2, 36
        out r2, 3               ; set LSBs of prescaler

        ldi r2, 244
        out r2, 4               ; set MSPs of prescaler

        ldi r2, 18          
        out r2, 5               ; set pwm mode, set top interrupt

        ssr 8                   ; enable interrupts

poll:   in r2, pin_reg          ; read pin register
        ani r2, 2               ; mask the button
        srl r2                  ; get the state of the button in the lsb
        adi r2, 48              ; calculate the ascii (0 or 1) state of the button
        str r2, p0              ; write the char to the screen
        jmp poll                ; poll the button again

        .org top_isr_vector
isr:    in r3, 2                ; read the status of the led
        xoi r3, 1               ; flip the first bit
        out r3, 1               ; toggle the led
        ssr 8                   ; enable interrupts
        ret                     ; return from isr
;******************************************************************************