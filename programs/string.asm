;*************************************************
		.define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
        .define gpu_isr_vector, 0x20
;*************************************************		
		.code

		ldi r2, gpu_addr[l]
		ldi r3, gpu_addr[h]

		ldi r0, text[l]
		ldi r1, text[h]

;loop:	lri r4, p0
;		cpi r4, 0
;		jz end

;		sri r4, p2
;		jmp loop

		
		;ldi r4, 65
		ldr r4, p0
		sri r4, p2
		sri r4, p2
		sri r4, p2

end:	hlt
;*************************************************
		.data

text: 	.string "This is a test"
;*************************************************