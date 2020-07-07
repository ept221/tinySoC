
f = open('src/memory/i_ram.ini', 'r');

for line in f:
	print('{0:0{1}X}'.format(int(line,2),4))

f.close();