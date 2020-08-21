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

loop1:  in r0, uart_ctrl
        ani r0, 1
        jz loop1                ; poll for full rx buffer

        in r1, uart_buffer      ; capture the data

loop2:  in r0, uart_ctrl        ; poll for empty tx buffer
        ani r0, 2
        jz loop2

        out r1, uart_buffer     ; print the char

        jmp loop1