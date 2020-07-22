;******************************************************************************
        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02

        .define prescaler_l, 0x03
        .define prescaler_h, 0x04
        .define count_ctrl, 0x05

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

        ldi r2, 0b00011110      ; configure gpu
        out r2, gpu_ctrl_reg

        ssr 8                   ; enable interrupts
loop:   jmp loop

        .org gpu_isr_vector
isr:    in r3, pin_reg          ; read pin register
        ani r3, 2               ; mask the button
        srl r3                  ; get the state of the button in the lsb
        out r3, port_reg        ; write the state to the led
        adi r3, 48              ; calculate the ascii (0 or 1) state of the button
        str r3, p0              ; write the char to the screen
        ssr 8                   ; enable interrupts
        ret                     ; return from isr
;******************************************************************************