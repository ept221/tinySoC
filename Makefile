lint: 
	verilator --lint-only -Wall soc/src/cpu/alu.v soc/src/cpu/control.v soc/src/cpu/cpu.v soc/src/cpu/regFile.v soc/src/gpu/gpu.v soc/src/gpu/pll.v soc/src/gpu/vga.v soc/src/io/io.v soc/src/memory/d_ram.v soc/src/memory/i_ram.v soc/src/soc/top.v

sim:
	mkdir -p build/sim
	iverilog -o build/sim/sim.vvp soc/src/cpu/alu.v soc/src/cpu/control.v soc/src/cpu/cpu.v soc/src/cpu/regFile.v soc/src/sim/test_tb.v soc/src/memory/d_ram.v soc/src/memory/i_ram.v soc/src/io/io.v soc/src/sim/SB_IO.v
	vvp build/sim/sim.vvp
	mv test_tb.vcd build/sim/test_tb.vcd
	open -a Scansion build/sim/test_tb.vcd

synth: soc/src/soc/top.v
	mkdir -p build/synth
	yosys -p "synth_ice40 -json build/synth/hardware.json" soc/src/cpu/alu.v soc/src/cpu/control.v soc/src/cpu/cpu.v soc/src/cpu/regFile.v soc/src/gpu/gpu.v soc/src/gpu/pll.v soc/src/gpu/vga.v soc/src/io/io.v soc/src/memory/d_ram.v soc/src/memory/i_ram.v soc/src/soc/top.v

pnr: build/synth/hardware.json
	mkdir -p build/pnr
	nextpnr-ice40 --lp8k --package cm81 --json build/synth/hardware.json --pcf soc/src/soc/pins.pcf --asc build/pnr/hardware.asc  --pcf-allow-unconstrained --freq 16

refresh:
	find build/pnr -type f -not -name "hardware.asc" -delete
	rm -rf build/binary build/images

clean:
	rm -rf build