lint: top.v
	verilator --lint-only -Wall top.v

sim: top.v test_tb.v
	mkdir -p build/sim
	iverilog -o build/sim/sim.vvp top.v test_tb.v
	vvp build/sim/sim.vvp
	mv test_tb.vcd build/sim/test_tb.vcd
	open -a Scansion build/sim/test_tb.vcd

build: synth pnr binary

synth: top.v
	mkdir -p build/synth
	yosys -p "synth_ice40 -json build/synth/hardware.json" top.v control.v i_ram.v regFile.v alu.v d_ram.v
pnr: build/synth/hardware.json
	mkdir -p build/pnr
	nextpnr-ice40 --lp8k --package cm81 --json build/synth/hardware.json --pcf pins.pcf --asc build/pnr/hardware.asc

binary: build/pnr/hardware.asc
	mkdir -p build/binary
	icepack build/pnr/hardware.asc build/binary/hardware.bin

upload: build/binary/hardware.bin
	tinyprog -p build/binary/hardware.bin

clean:
	rm -rf build