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
        .define motor_pwm0, 0x0F
        .define motor_pwm1, 0x10

        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80

        .define gpu_isr_vector, 0x0020
        .define top_isr_vector, 0x0030
;******************************************************************************        

		.code

		ldi r0, 103             ; set the baud rate to 9600
        out r0, uart_baud

        ldi r0, 0xff
        out r0, motor_enable

        ldi r0, 128
        out r0, motor_pwm0
        out r0, motor_pwm0

loop1:  in r0, uart_ctrl        ; poll for full rx buffer
        ani r0, 1
        jz loop1                

        in r0, uart_buffer      ; capture the data

        cpi r0, 115
        jz off
        cpi r0, 97
        jz cw
        cpi r0, 100
        jz ccw
        jmp loop1

off:	ldi r0, 0b00001111
		out r0, motor_control
		jmp loop1

cw:		ldi r0, 0b00001010
		out r0, motor_control
		jmp loop1

ccw:	ldi r0, 0b00000101
		out r0, motor_control
		jmp loop1