        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02
        .define gpu_lower_addr, 0x00
        .define gpu_upper_addr, 0x20
        .define gpu_ctrl_reg, 0x80
        .define gpu_isr_vector, 0x20
;******************************************************************************
        .code
        
        ldi r0, 1               ; set pin 1 to output
        out r0, dir_reg 

        ldi r14, 0xff           ; setup the stack pointer

        ldi r0, 0b00011110      ; setup the gpu control register
        out r0, gpu_ctrl_reg

        ldi r2, gpu_lower_addr  ; setup the vram pointer
        ldi r3, gpu_upper_addr

        ssr 8                   ; enable interrupts
loop:   jmp loop                ; do nothing and wait for an interrupt


        .org gpu_isr_vector
        in r0, pin_reg          ; read pin 1
        xoi r0, 1               ; flip the bit
        out r0, port_reg        ; toggle pin 1
        ldi r0, 65
        str r0, r2
        ssr 8                   ; enable interrupts
        ret                     ; return

;******************************************************************************
        .data

        .db 2, 3, 5, 7, 11, 13

strng:  .string "this is a test"
;******************************************************************************