module interface(input wire clk,
                 input wire [7:0] din,
                 input wire [15:0] address,
                 input wire w_en,
                 input wire r_en,
                 output reg [7:0] dout,

                 // For gpio
                 inout wire [7:0] gpio_pins,

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
    //***********************************************************************************
    // Memory control
    always @(*) begin
        if(address >= 16'h0000 && address <= 16'h07FF) begin            // d_ram
            d_ram_w_en = w_en;
            d_ram_r_en = r_en;
            gpio_w_en = 0;
            gpio_r_en = 0;
            counter_timer_w_en = 0;
            counter_timer_r_en = 0;
            uart_w_en = 0;
            uart_r_en = 0;
            gpu_w_en = 0;
            gpu_r_en = 0;
            gpu_vram_w_en = 0;
            dout = d_ram_dout;
        end
        else if(address >= 16'h1000 && address <= 16'h1002) begin      // gpio
            d_ram_w_en = 0;
            d_ram_r_en = 0;
            gpio_w_en = w_en;
            gpio_r_en = r_en;
            counter_timer_w_en = 0;
            counter_timer_r_en = 0;
            uart_w_en = 0;
            uart_r_en = 0;
            gpu_w_en = 0;
            gpu_r_en = 0;
            gpu_vram_w_en = 0;
            dout = d_ram_dout;
        end
        else if(address >= 16'h1000 && address <= 16'h1002) begin      // gpio

        end
    end
    //***********************************************************************************
    // Memory from
    wire d_ram_dout;
    reg d_ram_w_en;
    reg d_ram_r_en;
    d_ram dataMemory(.din(dMemIOIn),
                     .w_addr(address[10:0]),
                     .w_en(d_ram_w_en),
                     .r_addr(address[10:0]),
                     .r_en(d_ram_r_en),
                     .clk(clk),
                     .dout(d_ram_dout)
    );
    //***********************************************************************************
    // Physical pin instantiation 
    SB_IO #(.PIN_TYPE(6'b 1010_01),
            .PULLUP(1'b 0))
    io_block_instance0 [7:0](
            .PACKAGE_PIN(gpio_pins),
            .OUTPUT_ENABLE(dir),
            .D_OUT_0({pin_7,pin_6,port[5:0]}),
            .D_IN_0(pins)
    );

    wire pin_6 = (out0_en == 1) ? out0 : port[6];
    wire pin_7 = (out1_en == 1) ? out1 : port[7];
    //***********************************************************************************
    // gpio from: 0x1000 - 0x1002
    wire [7:0] dir;
    wire [7:0] port;
    wire [7:0] pins;
    wire gpio_dout;
    reg gpio_w_en;
    reg gpio_r_en;
    gpio #(.GPIO_ADDRESS(8'h00)) 
         gpio_inst(.clk(clk),
                   .din(din),
                   .address(address[7:0]),
                   .w_en(gpio_w_en),
                   .r_en(gpio_r_en),
                   .dout(gpio_dout),
                   .dir(dir),
                   .port(port),
                   .pins(pins)
    );
    //***********************************************************************************
    // counter_timer from: 0x1003 - 0x1009
    wire out0;
    wire out1;
    wire out0_en;
    wire out1_en;
    wire counter_timer_dout;
    reg counter_timer_w_en;
    reg counter_timer_r_en;
    counter_timer #(.COUNTER_TIMER_ADDRESS(8'h03))
        counter_timer_inst(.clk(clk),
                           .din(din),
                           .address(address[7:0]),
                           .w_en(counter_timer_w_en),
                           .r_en(counter_timer_r_en),
                           .dout(counter_timer_dout),
                           .out0(out0)
                           .out1(out1),
                           .out0_en(out0_en),
                           .out1_en(out1_en),
                           .top_flag(top_flag),
                           .match0_flag(match0_flag),
                           .match1_flag(match1_flag),
                           .top_flag_clr(top_flag_clr),
                           .match0_flag_clr(match0_flag_clr),
                           .match1_flag_clr(match1_flag_clr)
    );
    //***********************************************************************************
    // uart from: 0x100A - 0x100B
    wire uart_dout;
    reg uart_w_en;
    reg uart_r_en;
    uart #(.UART_ADDRESS(8'h0A))
        uart_inst(.clk(clk),
                  .din(din),
                  .address(address[7:0]),
                  .w_en(uart_w_en),
                  .r_en(uart_r_en),
                  .dout(uart_dout),
                  .rx(rx),
                  .tx(tx)
    );
    //***********************************************************************************
    // gpu from: 0x1080, 0x2000-0x2960
    wire gpu_dout;
    reg gpu_w_en;
    reg gpu_r_en;
    reg gpu_vram_w_en;
    gpu #(.GPU_IO_ADDRESS(8'h80),
          .GPU_VRAM_ADDRESS(16'h2000))
        gpu_inst(.clk(clk),
                 .din(din),
                 .address(address[15:0]),
                 .w_en(gpu_w_en),
                 .r_en(gpu_r_en),
                 .vram_w_en(gpu_vram_w_en),
                 .dout(gpu_dout),
                 .h_syncD2(h_sync),
                 .v_syncD2(v_sync),
                 .R(R),
                 .G(G),
                 .B(B),
                 .blanking_start_interrupt_flag(blanking_start_interrupt_flag),
                 .blanking_start_interrupt_flag_clr(blanking_start_interrupt_flag_clr)
    );
    //***********************************************************************************
endmodule