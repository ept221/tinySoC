lint: src/top.v
	verilator --lint-only -Wall top.v

sim: src/top.v src/test_tb.v
	mkdir -p build/sim
	iverilog -o build/sim/sim.vvp src/top.v src/control.v src/i_ram.v src/regFile.v src/alu.v src/d_ram.v src/test_tb.v
	vvp build/sim/sim.vvp
	mv test_tb.vcd build/sim/test_tb.vcd
	open -a Scansion build/sim/test_tb.vcd

build: synth pnr pack

synth: src/top.v
	mkdir -p build/synth
	yosys -p "synth_ice40 -json build/synth/hardware.json" src/top.v src/control.v src/i_ram.v src/regFile.v src/alu.v src/d_ram.v src/gpu.v src/vga.v src/pll.v
pnr: build/synth/hardware.json
	mkdir -p build/pnr
	nextpnr-ice40 --lp8k --package cm81 --json build/synth/hardware.json --pcf src/pins.pcf --asc build/pnr/hardware.asc 

pack: build/pnr/hardware.asc
	mkdir -p build/binary
	icepack build/pnr/hardware.asc build/binary/hardware.bin

upload: build/binary/hardware.bin
	tinyprog -p build/binary/hardware.bin

clean:
	rm -rf build