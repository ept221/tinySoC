module top(input wire clk,
           output wire h_sync,
           output wire v_sync,
           output wire R,
           output wire G,
           output wire B,
           output wire [7:0] io_pins
);
    //***************************************************************
    // Instantiate CPU
    cpu my_cpu(.clk(clk),
               .iMemAddress(iMemAddress),
               .iMemOut(iMemOut),
               .iMemReadEnable(iMemReadEnable),
               .dMemIOAddress(dMemIOAddress),
               .dMemIOIn(dMemIOIn),
               .dMemIOOut(dMemIOOut),
               .dMemIOWriteEn(dMemIOWriteEn),
               .dMemIOReadEn(dMemIOReadEn),
               .interrupt_0(top_interrupt),
               .interrupt_1(cmpr0_interrupt),
               .interrupt_2(cmpr1_interrupt)
    );
    //***************************************************************
    // Instantiate Instruction Memory
    wire iMemReadEnable;
    wire [15:0] iMemAddress;
    wire [15:0] iMemOut;
    i_ram instructionMemory(.din(16'd0),
                            .w_addr(16'd0),
                            .w_en(1'd0),
                            .r_addr(iMemAddress),
                            .r_en(iMemReadEnable),
                            .clk(clk),
                            .dout(iMemOut)
    );
    //***************************************************************
    // Memory Map Logic
    reg [15:0] dMemIOAddress;
    reg [7:0] dMemIOOut;
    wire [7:0] dMemIOIn;
    wire dMemIOWriteEn;
    wire dMemIOReadEn;

    always @(*) begin
        if(dMemIOAddress <= 16'h07FF) begin                                      // D_MEM
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
            dMemIOOut = IOOut;
        end
        else if(dMemIOAddress >= 16'h2000 && dMemIOAddress <= 16'h2960) begin    // V_MEM
            dMemWriteEn = 0;
            dMemReadEn = 0;
            IOWriteEn = 0;
            IOReadEn = 0;
            vMemWriteEn = dMemIOWriteEn;
            dMemIOOut = 0;
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
    reg [7:0] dMemOut;
    reg dMemWriteEn;
    reg dMemReadEn;

    d_ram dataMemory(.din(dMemIOIn),
                     .w_addr(dMemIOAddress),
                     .w_en(dMemWriteEn),
                     .r_addr(dMemIOAddress),
                     .r_en(dMemReadEn),
                     .clk(clk),
                     .dout(dMemOut)
    );
    //***************************************************************
    // Instantiate IO  
    reg IOWriteEn;
    reg IOReadEn;
    wire [7:0] IOOut;

    wire top_interrupt;
    wire cmpr0_interrupt;
    wire cmpr1_interrupt;

    io my_io(.clk(clk),
             .din(dMemIOIn),
             .address(dMemIOAddress),
             .w_en(IOWriteEn),
             .r_en(IOReadEn),
             .dout(IOOut),
             .io_pins(io_pins),
             .top_interrupt(top_interrupt),
             .cmpr0_interrupt(cmpr0_interrupt),
             .cmpr1_interrupt(cmpr1_interrupt)
    );
    //***************************************************************
    // Instantiate GPU
    reg vMemWriteEn;

    gpu my_gpu(.clk(clk),
               .h_syncD2(h_sync),
               .v_syncD2(v_sync),
               .R(R),
               .G(G),
               .B(B),
               .data_in(dMemIOIn),
               .write_address(dMemIOAddress),
               .w_en(vMemWriteEn));
    //***************************************************************
endmodule