        .define dir_reg, 0x00
        .define port_reg, 0x01
        .define pin_reg, 0x02
        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
        .define gpu_isr_vector, 0x0020
        .define top_isr_vector, 0x0030
;******************************************************************************		
		.code
		
		ldi r14, 0xff		; set stack pointer

		ldi r0, 5			
		out r0, dir_reg		; set pin 1 to output

		ldi r0, 36
		out r0, 3 			; set LSBs of prescaler

		ldi r0, 244
		out r0, 4 			; set MSPs of prescaler

		ldi r0, 18 			
		out r0, 5			; set pwm mode, set top interrupt

		ssr 8 				; enable interrupts

		hlt

		.org top_isr_vector
isr:    in r0, 2			; read pin register
		xoi r0, 1			; toggle the led bit
		out r0, pin_reg 	; write to the port register
		ssr 8				; enable interrupts
		ret
;******************************************************************************