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

discription = 'A memory image generator for tinySoC'
p = argparse.ArgumentParser(description = discription)
p.add_argument("source", help="source file name")
args = p.parse_args()

try:
	instruction_file = open(args.source+".instructions",'r')
	data_file = open(args.source+".data",'r')

except FileNotFoundError:
    print("File not found!")
    sys.exit(2)

i_ram_image = open(args.source+"_i_ram_image.hex",'w')
d_ram_image = open(args.source+"_d_ram_image.hex",'w')

gen(instruction_file,i_ram_image,i_ram_len,2,4)
gen(data_file,d_ram_image,d_ram_len,16,2)
####################################################################################################