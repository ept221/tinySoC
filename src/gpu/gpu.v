module gpu(input wire clk,
		   output reg h_syncD2,
		   output reg v_syncD2,
		   output wire pixel
);
	
	// Create the VGA clock with the PLL
	wire vgaClk;
	pll vgaClkGen(.clock_in(clk),.clock_out(vgaClk),.locked());
	
	// Create the sync generator 
	wire [9:0] x, y;
	wire h_sync, v_sync, active, animate;
	vga syncGen(.clk(vgaClk),.h_sync(h_sync),.v_sync(v_sync), .active(active), .animate(animate), .x(x), .y(y));

	// The RAM and ROM modules each introduce one clock cycle of delay, so
	// in order for everything to be in sync, we need to produce delayed
	// versions of the control signals from the sync generator.
	reg [9:0] xD1, xD2, yD1;
	reg h_syncD1, v_syncD1, activeD1, activeD2, animateD1, animateD2;
	always @(posedge vgaClk) begin
		xD1 <= x;
		xD2 <= xD1;

		yD1 <= y;

		h_syncD1 <= h_sync;
		h_syncD2 <= h_syncD1;

		v_syncD1 <= v_sync;
		v_syncD2 <= v_syncD1;

		activeD1 <= active;
		activeD2 <= activeD1;

		animateD1 <= animate;
		animateD2 <= animateD1;
	end

	// Create the text RAM addressed by the current tile being displayed
	// by the vga sync generator.
	wire [7:0] char;
	wire [11:0] address = (x[9:3] + (y[9:4]*80));
	ram myRam(8'd0, 12'd0, 1'd0, address,1'd1,vgaClk,char);

	// Create the font ROM. The upper portion of the address comes from the 
	// output of the text RAM, which then has 32 subtracted from it, to
	// account for the ASCII code, which, which then gives the start of a
	// particular char, and the lower portion of the address comes from the 
	// row number output from the sync generator. The output pixelRow give
	// a single horizontal slice of a particular glyph.
	wire [7:0] pixelRow;
	wire [7:0] upper = char - 8'd32;
	rom myRom(8'd0,{upper,yD1[3:0]},1'd0,vgaClk,pixelRow);

	// We need to reverse the order of pixelRow to make it easy to index into
	// because the LSB is the rightmost pixel, but we need it to be the left
	// most pixel, because we display pixels from left to right.
	genvar i;
	wire [7:0] reversedPixleRow;
	for(i = 0; i < 8; i++) begin
		assign reversedPixleRow[i] = pixelRow[7-i];
	end
	assign pixel = activeD2 & reversedPixleRow[xD2[2:0]];

endmodule

module rom(din, addr, write_en, clk, dout);
	initial begin
		$readmemh("src/gpu/rom.ini",mem);
	end

	parameter addr_width = 11;
	parameter data_width = 8;
	input [addr_width-1:0] addr;
	input [data_width-1:0] din;
	input write_en, clk;
	output [data_width-1:0] dout;
	reg [data_width-1:0] dout;
	reg [data_width-1:0] mem [0:(1<<addr_width)-1];

	always @ (posedge clk)
	begin
		if(write_en)
			mem[addr] <= din;
		dout <= mem[addr];
	end

endmodule

module ram(din, w_addr, w_en, r_addr, r_en, clk, dout);

	initial begin
		$readmemh("src/gpu/ram.ini",mem);
	end

	parameter addr_width = 12;
	parameter data_width = 8;
	input [addr_width-1:0] w_addr;
	input [addr_width-1:0] r_addr;
	input [data_width-1:0] din;
	input w_en, r_en, clk;
	output [data_width-1:0] dout;
	reg [data_width-1:0] dout;
	reg [data_width-1:0] mem [0:(1<<addr_width)-1];

	always @(posedge clk) begin
		if(w_en)
			mem[w_addr] <= din;
	end

	always @(posedge clk) begin
		if(r_en)
			dout <= mem[r_addr];
	end

endmodule

