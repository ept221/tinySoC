module test_tb();

    reg clk = 0;

    wire [7:0] io_pins;
    
    wire [15:0] iMemAddress;
    wire [15:0] iMemOut;
    wire iMemReadEnable;

    wire [15:0] dMemIOAddress;
    reg [15:0] dMemIOOut;
    wire dMemIOWriteEn;
    wire dMemIOReadEn;


    wire [7:0] dMemOut;
    reg dMemWriteEn;
    reg dMemReadEn;

    wire [7:0] IOOut;
    reg IOWriteEn;
    reg IOReadEn;
    

    always @(*) begin
        if(dMemIOAddress >= 16'h0000 && dMemIOAddress <= 16'h07FF) begin                                      // D_MEM
            dMemWriteEn = dMemIOWriteEn;
            dMemReadEn = dMemIOReadEn;
            IOWriteEn = 0;
            IOReadEn = 0;
            dMemIOOut = dMemOut;
        end
        else if(dMemIOAddress >= 16'h1000 && dMemIOAddress <= 16'h10FF) begin    // I/O
            dMemWriteEn = 0;
            dMemReadEn = 0;
            IOWriteEn = dMemIOWriteEn;
            IOReadEn = dMemIOReadEn;
            dMemIOOut = IOOut;
        end
        else begin
            dMemWriteEn = 0;
            dMemReadEn = 0;
            IOWriteEn = 0;
            IOReadEn = 0;
            dMemIOOut = 0;
        end
    end


    wire [7:0] dMemIOIn;
    //***************************************************************

    cpu my_cpu(.clk(clk),
               .iMemAddress(iMemAddress),
               .iMemOut(iMemOut),
               .iMemReadEnable(iMemReadEnable),

               .dMemIOAddress(dMemIOAddress),
               .dMemIOIn(dMemIOIn),
               .dMemIOOut(dMemIOOut),
               .dMemIOWriteEn(dMemIOWriteEn),
               .dMemIOReadEn(dMemIOReadEn)
    );

    i_ram my_i_ram(.din(16'd0),
                   .w_addr(iMemAddress),
                   .w_en(1'b0),
                   .r_addr(iMemAddress),
                   .r_en(iMemReadEnable),
                   .clk(clk),
                   .dout(iMemOut)
    );

    d_ram my_d_ram(.din(dMemIOIn),
                   .w_addr(dMemIOAddress),
                   .w_en(dMemWriteEn),
                   .r_addr(dMemIOAddress),
                   .r_en(dMemReadEn),
                   .clk(clk),
                   .dout(dMemOut)
    );

    io my_io(.clk(clk),
             .din(dMemIOIn),
             .address(dMemIOAddress),
             .w_en(IOWriteEn),
             .r_en(IOReadEn),
             .dout(IOOut),
             .io_pins(io_pins)
    );

    initial begin
        $dumpfile("test_tb.vcd");
        $dumpvars(0, my_cpu, my_io);
        repeat (15) begin
            #1 clk = ~clk;
        end
        $finish;
    end


endmodule