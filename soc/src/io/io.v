module io(input wire clk,
          input wire [7:0] din,
          input wire [15:0] address,
          input wire w_en,
          input wire r_en,
          output reg [7:0] dout,

          // For gpio

          // For counter_timer
          output wire top_flag,
          output wire match0_flag,
          output wire match1_flag,
          input wire top_flag_clr,
          input wire match0_flag_clr,
          input wire match1_flag_clr,

          // For uart
          input wire rx,
          output wire tx,

          // For gpu
          output wire h_sync,
          output wire v_sync,
          output wire R,
          output wire G,
          output wire B,
          output wire blanking_start_interrupt_flag,
          input wire blanking_start_interrupt_flag_clr
);

// 0x00 - 0x02
gpio #(.GPIO_ADDRESS(8'h00)) 
     gpio_inst(.clk(clk),
               .din(din),
               .address(address[7:0]),
               .w_en(w_en),
               .r_en(r_en),
               .dout(dout),
               .dir(dir),
               .port(port),
               .pins(pins)
);

// 0x03 - 0x09
counter_timer #(.COUNTER_TIMER_ADDRESS(8'h03))
    counter_timer_inst(.clk(clk),
                       .din(din),
                       .address(address[7:0]),
                       .w_en(w_en),
                       .r_en(r_en),
                       .dout(dout),
                       .top_flag(top_flag),
                       .match0_flag(match0_flag),
                       .match1_flag(match1_flag),
                       .top_flag_clr(top_flag_clr),
                       .match0_flag_clr(match0_flag_clr),
                       .match1_flag_clr(match1_flag_clr)
);

// 0x0A - 0x0B
uart #(.UART_ADDRESS(8'h0A))
    uart_inst(.clk(clk),
              .din(din),
              .address(address[7:0]),
              .w_en(w_en),
              .r_en(r_en),
              .dout(dout),
              .rx(rx),
              .tx(tx)
);

// 0x80, 0x2000-0x2960
gpu #(.GPU_IO_ADDRESS(8'h80),
      .GPU_VRAM_ADDRESS(16'h2000))
    gpu_inst(.clk(clk),
             .din(din),
             .address(address[15:0]),
             .w_en(w_en),
             .r_en(r_en),
             .vram_w_en(vram_w_en),
             .dout(dout),
             .h_syncD2(h_sync),
             .v_syncD2(v_sync),
             .R(R),
             .G(G),
             .B(B),
             .blanking_start_interrupt_flag(blanking_start_interrupt_flag),
             .blanking_start_interrupt_flag_clr(blanking_start_interrupt_flag_clr)
);
endmodule