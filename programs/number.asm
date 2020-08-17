;*************************************************
        .define gpu_addr, 0x2000
        .define gpu_ctrl_reg, 0x80
        .define gpu_isr_vector, 0x20
;*************************************************      
        .code

        ldi r0, 0b00011000
        out r0, gpu_ctrl_reg

        ldi r2, gpu_addr[l]
        ldi r3, gpu_addr[h]

start:  ldi r0, 65
        



print: str r0, p2       


end:    hlt
;*************************************************
