module motor_controller(input wire clk,
						input wire [7:0] din,
						input wire [7:0] address,
						input wire w_en,
						input wire r_en,
						output reg [7:0] dout,

						input wire [1:0] encoders,
						output reg [1:0] pwm,
						output reg [3:0] motor,
						output reg enable
);

	//***************************************************************
	parameter MOTOR_CONTROLLER_ADDRESS = 8'h00;
	localparam MOTOR_ADDRESS = MOTOR_CONTROLLER_ADDRESS;
	localparam ENABLE_ADDRESS = MOTOR_CONTROLLER_ADDRESS + 1;
	localparam PWM1_ADDRESS = MOTOR_CONTROLLER_ADDRESS + 2;
	localparam PWM2_ADDRESS = MOTOR_CONTROLLER_ADDRESS + 3;
	//***************************************************************
	always @(posedge clk) begin
		case(address)
			MOTOR_ADDRESS: begin
				if(w_en) begin
					motor <= din[3:0];
				end
				if(r_en) begin
					dout <= {4'b0,motor};
				end
			end
			ENABLE_ADDRESS: begin
				if(w_en) begin
					enable <= din[0];
				end
				if(r_en) begin
					dout <= {7'b0,enable};
				end
			end
			PWM1_ADDRESS: begin
				if(w_en) begin
					cmpr0 <= din;
				end
				if(r_en) begin
					dout <= cmpr0;
				end
			end
			PWM2_ADDRESS: begin
				if(w_en) begin
					cmpr1 <= din;
				end
				if(r_en) begin
					dout <= cmpr1;
				end
			end
		endcase 
	end
	//***************************************************************
	// PWM
	reg [15:0] prescaler;
	reg scaled;
	localparam SCALE_FACTOR = 16'd125;
	always @(posedge clk) begin
		if(prescaler == SCALE_FACTOR) begin
			scaled <= 1;
			prescaler <= 0;
		end
		else begin
			scaled <= 0;
			prescaler <= prescaler + 1;
		end
	end

	reg [7:0] pwm_counter;
	reg [7:0] cmpr0;
	reg [7:0] cmpr1;
	always @(posedge clk) begin
		if(scaled) begin
			if(pwm_counter == 8'd255) begin         // If finished 256 cycles
                    pwm[0] <= 1;                    // On next edge (start of zero), set the outputs to 1
                    pwm[1] <= 1;
            end
            else begin
                if(pwm_counter == cmpr0) begin     // On match
                	pwm[0] <= 0;                   // clear pwm[0]
                end
                if(pwm_counter == cmpr1) begin     // On match
                	pwm[1] <= 0;                   // clear pwm[1]
                end
            end
            pwm_counter <= pwm_counter + 1;
		end
	end
	//***************************************************************
	// Encoders

	// Synchronizers
	reg [1:0] d0;
	reg [1:0] d1;
	always @(posedge clk) begin
		d0 <= encoders;
		d1 <= d1;
	end

	// Counters
	reg [15:0] encoder_count_0;
	reg [15:0] encoder_count_1;
	reg [1:0] edge_delay;
	always @(posedge clk) begin
		edge_delay <= d1;
		if(edge_delay[0] && ~d0[0]) begin
			encoder_count_0 <= encoder_count_0 + 1;
		end
		if(edge_delay[1] && ~d0[1]) begin
			encoder_count_1 <= encoder_count_1 + 1;
		end
	end
	//***************************************************************
endmodule