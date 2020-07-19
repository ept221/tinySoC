		.code
		
		ldi r14, 0xff		; set stack pointer

		ldi r0, 5			
		out r0, 0			; set pin 1 to output

		ldi r0, 36
		out r0, 3 			; set LSBs of prescaler

		ldi r0, 244
		out r0, 4 			; set MSPs of prescaler

		ldi r0, 18 			
		out r0, 5			; set pwm mode, set top interrupt

		ssr 8 				; enable interrupts

		hlt

isr:    in r0, 2			; read pin register
		xoi r0, 1			; toggle the led bit
		out r0, 1 			; write to the port register
		ssr 8				; enable interrupts
		ret