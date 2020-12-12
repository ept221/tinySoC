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

        .define motor_control, 0x0D
        .define motor_enable, 0x0E

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80

        .define gpu_isr_vector, 0x0020
        .define top_isr_vector, 0x0030
;******************************************************************************

        .code

        ldi r0, 0xff            ; set all gpio to output
        out r0, dir_reg

        ldi r0, 0b00010100      ; setup the gpu
        out r0, gpu_ctrl_reg

        ldi r2, gpu_addr[l]     ; setup the pointer to the v-ram
        ldi r3, gpu_addr[h]

        ldi r4, 0               ; r4 is the column counter
        ldi r6, gpu_addr[l]
        ldi r7, gpu_addr[h]

stable: in r0, gpu_ctrl_reg     ; wait for gpu clock to become stable
        ani r0, 0x80
        jz stable

        ldi r0, 103             ; set the baud rate to 9600
        out r0, uart_baud
;******************************************************************************
loop1:  in r0, uart_ctrl        ; poll for full rx buffer
        ani r0, 1
        jz loop1                

        in r0, uart_buffer      ; capture the data

loop2:  in r1, uart_ctrl        ; poll for empty tx buffer
        ani r1, 2
        jz loop2
        out r0, uart_buffer     ; echo the char back over the uart

        out r0, port_reg        ; write the data to the gpio port
;******************************************************************************
        cpi r0, 8               ; check if delete was sent
        jz delete
        cpi r0, 10
        jz nl
        jmp normal
        
delete: ldi r0, 32
        str r0, p6              ; print space to remove cursor
        cpi r4, 0
        jnz skip1
        ldi r4, 79              ; set col counter to the end
        adi r2, -80             ; move up a row part 1
        aci r3, 0xff            ; move up a row part 2
        jmp done1
skip1:  adi r4, -1              ; move the col counter back one
done1:  mov r6, r2
        mov r7, r3
        add r6, r4              ; calculate the new pointer part 1
        aci r7, 0               ; calculate the new pointer part 2
        ldi r0, 95
        str r0, p6              ; delete char and print cursor
        jmp loop1

nl:     ldi r0, 32
        str r0, p6              ; print space to remove cursor
        ldi r4, 0               ; set col counter to the start
        adi r2, 80              ; move down a row part 1
        aci r3, 0x00            ; move down a row part 2
        mov r6, r2
        mov r7, r3
        ldi r0, 95
        str r0, p6              ; print cursor
        jmp loop1

normal: str r0, p6              ; write the data to the screen
        cpi r4, 79
        jnz skip2
        ldi r4, 0               ; set col counter to the start
        adi r2, 80              ; move down a row part 1
        aci r3, 0x00            ; move down a row part 2
        jmp done2
skip2:  adi r4, 1
done2:  mov r6, r2
        mov r7, r3
        add r6, r4              ; calculate the new pointer part 1
        aci r7, 0               ; calculate the new pointer part 2
        ldi r0, 95              
        str r0, p6              ; print cursor
        jmp loop1               ; go get another char
;******************************************************************************