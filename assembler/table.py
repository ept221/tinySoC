mnm_r_i = {
	'LDI': "DDDDIIIIIIII0001",
	'ANI': "DDDDIIIIIIII0011",
	'ORI': "DDDDIIIIIIII0101",
	'XOI': "DDDDIIIIIIII0111",
	'ADI': "DDDDIIIIIIII1001",
	'ACI': "DDDDIIIIIIII1011",
	'CPI': "DDDDIIIIIIII1101",
}

mnm_r_l = {
	'IN':  "DDDDLLLLLLLL0010",
	'OUT': "SSSSLLLLLLLL0100",
}

mnm_r_r = {
	'AND': "DDDDSSSS00001000",
	'OR':  "DDDDSSSS00010000",
	'XOR': "DDDDSSSS00011000",
	'ADD': "DDDDSSSS00100000",
	'ADC': "DDDDSSSS00101000",
	'CMP': "DDDDSSSS00110000",
	'SUB': "DDDDSSSS00111000",
	'SBB': "DDDDSSSS01000000",
}

mnm_r = {
	'NOT': "DDDD000001001000",
	'SLL': "DDDD000001010000",
	'SRL': "DDDD000001011000",
	'SRA': "DDDD000001100000",
}

mnm_r_rp = {
	'STR': "SSSSPPPP01101000",
	'SRI': "SSSSPPPP01110000",
	'SRD': "SSSSPPPP01111000",
	'LDR': "DDDDPPPP10000000",
	'LRI': "DDDDPPPP10001000",
	'LRD': "DDDDPPPP10010000",
}

mnm_rp = {
	'IRP':  "0000PPPP10011000",
	'DRP':  "0000PPPP10100000",
	'JMPI': "0000PPPP10101000",
	'JCI':  "0010PPPP10101000",
	'JNCI': "0100PPPP10101000",
	'JZI':  "0110PPPP10101000",
	'JNZI': "1000PPPP10101000",
	'JNI':  "1010PPPP10101000",
	'JNZI': "1100PPPP10101000",
}

mnm_a = {
	'JMP':  "0000000010110000",
	'JC':   "0010000010110000",
	'JNC':  "0100000010110000",
	'JZ':   "0110000010110000",
	'JNZ':  "1000000010110000",
	'JN':   "1010000010110000",
	'JNN':  "1100000010110000",
	'CALL': "0000000010111000",
	'CC':   "0010000010111000",
	'CNC':  "0100000010111000",
	'CZ':   "0110000010111000",
	'CNZ':  "1000000010111000",
	'CN':   "1010000010111000",
	'CNN':  "1100000010111000",
}

mnm_n = {
	'RET': "0000000011000000",
	'RC':  "0010000011000000",
	'RNC': "0100000011000000",
	'RZ':  "0110000011000000",
	'RNZ': "1000000011000000",
	'RN':  "1010000011000000",
	'RNN': "1100000011000000",
	'PUS': "0000000011001000",
	'POS': "0000000011010000",
	'HLT': "0000000011101000",
	'NOP': "0000000000000000",
}

mnm_m = {
	'SSR': "0000MMMM11011000",
	'CSR': "0000MMMM11100000",
}

drct_0 = {
	'.CODE',
	'.DATA',
}

reserved_mnm_r_i = {key for key in mnm_r_i}
reserved_mnm_r_l = {key for key in mnm_r_l}
reserved_mnm_r_r = {key for key in mnm_r_r}
reserved_mnm_r_rp = {key for key in mnm_r_rp}
reserved_mnm_rp = {key for key in mnm_rp}
reserved_mnm_a = {key for key in mnm_a}
reserved_mnm_n = {key for key in mnm_n}
reserved_mnm_m = {key for key in mnm_m}

reserved = (reserved_mnm_r_i | reserved_mnm_r_l | reserved_mnm_r_r |
            reserved_mnm_r_rp | reserved_mnm_rp | reserved_mnm_a |
            reserved_mnm_n | reserved_mnm_m | drct_0)