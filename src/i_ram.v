module i_ram(din, w_addr, w_en, r_addr, r_en, clk, dout);

    initial begin
        $readmemb("src/i_ram.ini",mem);
    end

    parameter addr_width = 12;
    parameter data_width = 16;
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