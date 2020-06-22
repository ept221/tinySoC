lint: src/top.v
	verilator --lint-only -Wall src/cpu/alu.v src/cpu/control.v src/cpu/cpu.v src/cpu/regFile.v src/gpu/gpu.v src/gpu/pll.v src/gpu/vga.v src/io/io.v src/memory/d_ram.v src/memory/i_ram.v src/soc/top.v

sim: src/top.v src/test_tb.v
	mkdir -p build/sim
	iverilog -o build/sim/sim.vvp src/top.v test_tb.v
	vvp build/sim/sim.vvp
	mv test_tb.vcd build/sim/test_tb.vcd
	open -a Scansion build/sim/test_tb.vcd

build: synth pnr pack

synth: src/soc/top.v
	mkdir -p build/synth
	yosys -p "synth_ice40 -json build/synth/hardware.json" src/cpu/alu.v src/cpu/control.v src/cpu/cpu.v src/cpu/regFile.v src/gpu/gpu.v src/gpu/pll.v src/gpu/vga.v src/io/io.v src/memory/d_ram.v src/memory/i_ram.v src/soc/top.v
pnr: build/synth/hardware.json
	mkdir -p build/pnr
	nextpnr-ice40 --lp8k --package cm81 --json build/synth/hardware.json --pcf src/soc/pins.pcf --asc build/pnr/hardware.asc  --pcf-allow-unconstrained

pack: build/pnr/hardware.asc
	mkdir -p build/binary
	icepack build/pnr/hardware.asc build/binary/hardware.bin

upload: build/binary/hardware.bin
	tinyprog -p build/binary/hardware.bin

clean:
	rm -rf build