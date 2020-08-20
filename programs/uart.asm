;******************************************************************************
        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02

        .define prescaler_l, 0x03
        .define prescaler_h, 0x04
        .define count_ctrl, 0x05

        .define uart_ctrl, 0x0A
        .define uart_buffer, 0x0B

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80

        .define gpu_isr_vector, 0x0020
        .define top_isr_vector, 0x0030
;******************************************************************************         
        .code

        ldi r0, 1
        out r0, dir_reg

start:  ldi r2, text[l]
        ldi r3, text[h]

loop:   in r1, uart_ctrl
        ani r1, 2
        jz loop                 ; poll for empty buffer

        lri r0, p2              ; check for end of string
        cpi r0, 0
        jz start

        out r0, uart_buffer     ; print the char
        jnz loop
;******************************************************************************
        .data
text:   .string "GitHub repo at: https://github.com/ept221/tinySoC\n"