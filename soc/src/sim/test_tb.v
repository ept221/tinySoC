module test_tb();

    reg clk = 0;

    wire [7:0] io_pins;
    
    //***************************************************************
    // Instantiate CPU
    
    //***************************************************************
    // Instantiate Instruction Memory
    wire iMemReadEnable;
    wire [15:0] iMemAddress;
    wire [15:0] iMemOut;
    
    //***************************************************************
    // Memory Map Logic
    wire [15:0] dMemIOAddress;
    reg [7:0] dMemIOOut;
    wire [7:0] dMemIOIn;
    wire dMemIOWriteEn;
    wire dMemIOReadEn;
    reg vMemWriteEn;
    wire [7:0] vMemOut;
    always @(*) begin
        if(dMemIOAddress >= 16'h0000 && dMemIOAddress <= 16'h07FF) begin         // D_MEM
            dMemWriteEn = dMemIOWriteEn;
            dMemReadEn = dMemIOReadEn;
            IOWriteEn = 0;
            IOReadEn = 0;
            vMemWriteEn = 0;
            dMemIOOut = dMemOut;
        end
        else if(dMemIOAddress >= 16'h1000 && dMemIOAddress <= 16'h10FF) begin    // I/O
            dMemWriteEn = 0;
            dMemReadEn = 0;
            IOWriteEn = dMemIOWriteEn;
            IOReadEn = dMemIOReadEn;
            vMemWriteEn = 0;
            if(dMemIOAddress == 16'h1080) begin
                dMemIOOut = vMemOut;
            end
            else begin
                dMemIOOut = IOOut;
            end
        end
        else if(dMemIOAddress >= 16'h2000 && dMemIOAddress <= 16'h2960) begin    // V_MEM
            dMemWriteEn = 0;
            dMemReadEn = 0;
            IOWriteEn = 0;
            IOReadEn = 0;
            vMemWriteEn = dMemIOWriteEn;
            dMemIOOut = vMemOut;
        end
        else begin
            dMemWriteEn = 0;
            dMemReadEn = 0;
            IOWriteEn = 0;
            IOReadEn = 0;
            vMemWriteEn = 0;
            dMemIOOut = 0;
        end
    end
    //***************************************************************
    // Instantiate Data Memory 
    wire [7:0] dMemOut;
    reg dMemWriteEn;
    reg dMemReadEn;

    //***************************************************************
    // Instantiate IO  
    reg IOWriteEn;
    reg IOReadEn;
    wire [7:0] IOOut;

    wire top_flag;
    wire match0_flag;
    wire match1_flag;

    wire top_flag_clr;
    wire match0_flag_clr;
    wire match1_flag_clr;

    initial begin
        $dumpfile("test_tb.vcd");
        $dumpvars(0, test_tb);
        repeat (5000) begin
            #1 clk = ~clk;
        end
        $finish;
    end

    cpu my_cpu(.clk(clk),
               .iMemAddress(iMemAddress),
               .iMemOut(iMemOut),
               .iMemReadEnable(iMemReadEnable),
               .dMemIOAddress(dMemIOAddress),
               .dMemIOIn(dMemIOIn),
               .dMemIOOut(dMemIOOut),
               .dMemIOWriteEn(dMemIOWriteEn),
               .dMemIOReadEn(dMemIOReadEn),
               .interrupt_0(top_flag),
               .interrupt_1(match0_flag),
               .interrupt_2(match1_flag),
               .interrupt_0_clr(top_flag_clr),
               .interrupt_1_clr(match0_flag_clr),
               .interrupt_2_clr(match1_flag_clr)
    );

    i_ram instructionMemory(.din(16'd0),
                            .w_addr(12'd0),
                            .w_en(1'd0),
                            .r_addr(iMemAddress[11:0]),
                            .r_en(iMemReadEnable),
                            .clk(clk),
                            .dout(iMemOut)
    );

    d_ram dataMemory(.din(dMemIOIn),
                     .w_addr(dMemIOAddress[10:0]),
                     .w_en(dMemWriteEn),
                     .r_addr(dMemIOAddress[10:0]),
                     .r_en(dMemReadEn),
                     .clk(clk),
                     .dout(dMemOut)
    );

    io my_io(.clk(clk),
             .din(dMemIOIn),
             .address(dMemIOAddress[7:0]),
             .w_en(IOWriteEn),
             .r_en(IOReadEn),
             .dout(IOOut),
             .io_pins(io_pins),
             .top_flag(top_flag),
             .match0_flag(match0_flag),
             .match1_flag(match1_flag),
             .top_flag_clr(top_flag_clr),
             .match0_flag_clr(match0_flag_clr),
             .match1_flag_clr(match1_flag_clr)
    );

endmodule