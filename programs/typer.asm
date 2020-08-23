;******************************************************************************
        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02

        .define prescaler_l, 0x03
        .define prescaler_h, 0x04
        .define count_ctrl, 0x05

        .define uart_baud, 0x0A
        .define uart_ctrl, 0x0B
        .define uart_buffer, 0x0C

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80

        .define gpu_isr_vector, 0x0020
        .define top_isr_vector, 0x0030
;******************************************************************************

        .code

        ldi r0, 0xff            ; set all gpio to output
        out r0, dir_reg

        ldi r0, 0b00011000      ; setup the gpu
        out r0, gpu_ctrl_reg

        ldi r2, gpu_addr[l]     ; setup the pointer to the v-ram
        ldi r3, gpu_addr[h]

stable: in r0, gpu_ctrl_reg     ; wait for gpu clock to become stable
        ani r0, 0x80
        jz stable

        ldi r0, 103             ; set the baud rate to 9600
        out r0, uart_baud

loop1:  in r0, uart_ctrl        ; poll for full rx buffer
        ani r0, 1
        jz loop1                

        in r0, uart_buffer      ; capture the data

loop2:  in r1, uart_ctrl        ; poll for empty tx buffer
        ani r1, 2
        jz loop2
        out r0, uart_buffer     ; print the char to the uart

        out r0, port_reg        ; write the data to the gpio port

        cpi r0, 8               ; check if delete was sent
        jnz normal
        
        ldi r0, 32
        srd r0, p2              ; print space to clear cursor, and move back
        ldi r0, 95
        str r0, p2              ; delete char and print cursor
        jmp loop1

normal: sri r0, p2              ; write the data to the screen
        ldi r0, 95
        str r0, p2
        jmp loop1               ; go get another char
;******************************************************************************