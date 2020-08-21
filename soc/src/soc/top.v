module top(input wire clk,
           output wire [7:0] io_pins,
           input wire rx,
           output wire tx,
           output wire R,
           output wire G,
           output wire B,
           output wire h_sync,
           output wire v_sync,
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
               .interrupt_0(blanking_start_interrupt_flag),
               .interrupt_1(top_flag),
               .interrupt_2(match0_flag),
               .interrupt_3(match1_flag),
               .interrupt_0_clr(blanking_start_interrupt_flag_clr),
               .interrupt_1_clr(top_flag_clr),
               .interrupt_2_clr(match0_flag_clr),
               .interrupt_3_clr(match1_flag_clr)
    );
    //***************************************************************
    // Instantiate Instruction Memory
    wire iMemReadEnable;
    wire [15:0] iMemAddress;
    wire [15:0] iMemOut;
    i_ram instructionMemory(.din(16'd0),
                            .w_addr(12'd0),
                            .w_en(1'd0),
                            .r_addr(iMemAddress[11:0]),
                            .r_en(iMemReadEnable),
                            .clk(clk),
                            .dout(iMemOut)
    );
    //***************************************************************
    // Instantiate Interface to Data Memory and IO  

    //***************************************************************
endmodule