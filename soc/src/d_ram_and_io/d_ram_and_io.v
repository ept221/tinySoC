module d_ram_and_io(input wire clk,
                    input wire rst,
                    input wire [7:0] din,
                    input wire [15:0] address,
                    input wire w_en,
                    input wire r_en,
                    output reg [7:0] dout,

                    // For gpio
                    inout wire [7:0] gpio_pins,

                    // For uart
                    input wire rx,
                    output wire tx,

                    // For pic
                    output wire interrupt,
                    output wire [15:0] intVect,
                    input wire intAck,

                    // For gpu
                    output wire h_sync,
                    output wire v_sync,
                    output wire R,
                    output wire G,
                    output wire B,
);
    //***********************************************************************************
    // Memory control
    reg d_ram_w_en;
    reg d_ram_r_en;
    reg io_w_en;
    reg io_r_en;
    always @(*) begin
        if(address >= 16'h0000 && address <= 16'h07FF) begin            // d_ram
            d_ram_w_en = w_en;
            d_ram_r_en = r_en;
            io_w_en = 0;
            io_r_en = 0;
            dout = d_ram_dout;     
        end
        else if(address >= 16'h1000 && address <= 16'h10FF) begin      // io
            d_ram_w_en = 0;
            d_ram_r_en = 0;
            io_w_en = w_en;
            io_r_en = r_en;
            dout = gpio_dout | counter_timer_dout | uart_dout | gpu_dout | pic_dout;
        end
        else begin
            d_ram_w_en = 0;
            d_ram_r_en = 0;
            io_w_en = 0;
            io_r_en = 0;
            dout = 0;
        end
    end
    //***********************************************************************************
    // Memory from
    wire [7:0] d_ram_dout;

    d_ram dataMemory(.din(din),
                     .w_addr(address[10:0]),
                     .w_en(d_ram_w_en),
                     .r_addr(address[10:0]),
                     .r_en(d_ram_r_en),
                     .clk(clk),
                     .dout(d_ram_dout)
    );
    //***********************************************************************************
    // Physical pin instantiation 
    wire pin_6 = (out0_en == 1) ? out0 : port[6];
    wire pin_7 = (out1_en == 1) ? out1 : port[7];

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) io_block_instance0 [7:0](
        .PACKAGE_PIN(gpio_pins),
        .OUTPUT_ENABLE(dir),
        .D_OUT_0({pin_7,pin_6,port[5:0]}),
        .D_IN_0(pins)
    );
    //***********************************************************************************
    // gpio from: 0x1000 - 0x1002
    wire [7:0] dir;
    wire [7:0] port;
    wire [7:0] pins;
    wire [7:0] gpio_dout;
    
    gpio #(.GPIO_ADDRESS(8'h00)) 
         gpio_inst(.clk(clk),
                   .rst(rst),
                   .din(din),
                   .address(address[7:0]),
                   .w_en(io_w_en),
                   .r_en(io_r_en),
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
    wire top_flag;
    wire match0_flag;
    wire match1_flag;
    wire [7:0] counter_timer_dout;

    counter_timer #(.COUNTER_TIMER_ADDRESS(8'h03))
        counter_timer_inst(.clk(clk),
                           .rst(rst),
                           .din(din),
                           .address(address[7:0]),
                           .w_en(io_w_en),
                           .r_en(io_r_en),
                           .dout(counter_timer_dout),
                           .out0(out0),
                           .out1(out1),
                           .out0_en(out0_en),
                           .out1_en(out1_en),
                           .top_flag(top_flag),
                           .match0_flag(match0_flag),
                           .match1_flag(match1_flag)
    );
    //***********************************************************************************
    // uart from: 0x100A - 0x100C
    wire [7:0] uart_dout;

    uart #(.UART_ADDRESS(8'h0A))
        uart_inst(.clk(clk),
                  .rst(rst),
                  .din(din),
                  .address(address[7:0]),
                  .w_en(io_w_en),
                  .r_en(io_r_en),
                  .dout(uart_dout),
                  .rx(rx),
                  .tx(tx)
    );
    //***********************************************************************************
    // pic at 0x100D - 0x1017
    wire [7:0] pic_dout;
    pic #(.PIC_ADDRESS(8'h0D))
        pic_inst(.clk(clk),
                 .din(din),
                 .address(address[7:0]),
                 .w_en(io_w_en),
                 .r_en(io_r_en),
                 .dout(pic_dout),
                 .interrupt(interrupt),
                 .intVect(intVect),
                 .intAck(intAck),
                 .irq_0(blanking_start_interrupt_flag),
                 .irq_1(top_flag),
                 .irq_2(match0_flag),
                 .irq_3(match1_flag),
    );
    //***********************************************************************************
    // gpu from: 0x1080, 0x2000-0x2960
    wire [7:0] gpu_dout;
    wire blanking_start_interrupt_flag;
    gpu #(.GPU_IO_ADDRESS(8'h80),
          .GPU_VRAM_ADDRESS(16'h2000))
        gpu_inst(.clk(clk),
                 .rst(rst),
                 .din(din),
                 .address(address[15:0]),
                 .w_en(io_w_en),
                 .r_en(io_r_en),
                 .vram_w_en(w_en),
                 .dout(gpu_dout),
                 .h_syncD2(h_sync),
                 .v_syncD2(v_sync),
                 .R(R),
                 .G(G),
                 .B(B),
                 .blanking_start_interrupt_flag(blanking_start_interrupt_flag)
    );
    //***********************************************************************************
endmodule