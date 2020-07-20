####################################################################################################
import sys
import argparse
####################################################################################################
# The lengths of the SoC's memories. These can change depending
# on the rtl implementation
i_ram_len = 4096
d_ram_len = 2048
####################################################################################################
def gen(in_file,out_file,length,convert_base,hex_width):
	hex_width_str = "0"+str(hex_width)+"x"
	address = 0
	pair = []
	while(address < length):
		if(not pair):
			line = in_file.readline()
			if(line):
				pair = line.strip().split(',')
				if(address == int(pair[0],base=16)):
					print(format(int(pair[1],base=convert_base), hex_width_str),file=out_file)
					pair = []
				else:
					print("0"*hex_width,file=out_file)
			else:
				print("0"*hex_width,file=out_file)
		else:
			if(address == int(pair[0],base=16)):
					print(format(int(pair[1],base=convert_base), hex_width_str),file=out_file)
					pair = []
			else:
				print("0"*hex_width,file=out_file)
		address += 1
####################################################################################################
instruction_file = open("test.instructions",'r')
gen(instruction_file,i_ram_len,2,4)

data_file = open("test.data",'r')
gen(data_file,d_ram_len,16,2)
####################################################################################################