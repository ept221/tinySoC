mnm_r_i = {
	'LDI',
	'ANI',
	'ORI',
	'XOI',
	'ADI',
	'ACI',
	'CPI',
}

mnm_r_l = {
	'IN',
	'OUT',
}

mnm_r_r = {
	'AND',
	'OR',
	'XOR',
	'ADD',
	'ADC',
	'CMP',
	'SUB',
	'SBB',
}

mnm_r = {
	'NOT',
	'SLL',
	'SRL',
	'SRA',
}

mnm_r_rp = {
	'STR',
	'SRI',
	'SRD',
	'LDR',
	'LRI',
	'LRD',
}

mnm_rp = {
	'IRP',
	'DRP',
	'JMPI',
	'JCI',
	'JNCI',
	'JZI'
	'JNZI',
	'JNI',
	'JNZI',
}

mnm_a = {
	'JMP',
	'JC',
	'JNC',
	'JZ',
	'JNZ',
	'JN',
	'JNN',
	'CALL',
	'CC',
	'CNC',
	'CZ',
	'CNZ',
	'CN',
	'CNN',
}

mnm_n = {
	'RET',
	'RC',
	'RNC',
	'RZ',
	'RNZ',
	'RN',
	'RNN',
	'PUS',
	'POS',
	'HLT',
	'NOP',
}

mnm_m = {
	'SSR',
	'CSR',
}

reserved = mnm_r_i | mnm_r_l | mnm_r_r | mnm_r | mnm_r_rp | mnm_rp | mnm_a | mnm_n | mnm_m