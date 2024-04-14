/*
 * Copyright (c) 2024 Mikkel Holm Olsen (spiff42)
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_spiff42_exp_led_pwm (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
  );

  wire [7:0] ramp;

  reg i2c_control;
  reg [7:0] pwm_val [7:0];

  ramp_generator ramp_gen (.clk(clk), .rst_n(rst_n), .ramp(ramp));

  pwm_channel pwmch_0 (.value(pwm_val[0]), .ramp(ramp), .ch(uo_out[0]));
  pwm_channel pwmch_1 (.value(pwm_val[1]), .ramp(ramp), .ch(uo_out[1]));
  pwm_channel pwmch_2 (.value(pwm_val[2]), .ramp(ramp), .ch(uo_out[2]));
  pwm_channel pwmch_3 (.value(pwm_val[3]), .ramp(ramp), .ch(uo_out[3]));
  pwm_channel pwmch_4 (.value(pwm_val[4]), .ramp(ramp), .ch(uo_out[4]));
  pwm_channel pwmch_5 (.value(pwm_val[5]), .ramp(ramp), .ch(uo_out[5]));
  pwm_channel pwmch_6 (.value(pwm_val[6]), .ramp(ramp), .ch(uo_out[6]));
  pwm_channel pwmch_7 (.value(pwm_val[7]), .ramp(ramp), .ch(uo_out[7]));

/*
  pwm_channel pwmch_0 (.value(ui_in), .ramp(ramp), .ch(uo_out[0]));
  pwm_channel pwmch_1 (.value(ui_in ^ 8'h10), .ramp(ramp), .ch(uo_out[1]));
  pwm_channel pwmch_2 (.value(ui_in ^ 8'h20), .ramp(ramp), .ch(uo_out[2]));
  pwm_channel pwmch_3 (.value(ui_in ^ 8'h30), .ramp(ramp), .ch(uo_out[3]));
  pwm_channel pwmch_4 (.value(ui_in ^ 8'h40), .ramp(ramp), .ch(uo_out[4]));
  pwm_channel pwmch_5 (.value(ui_in ^ 8'h50), .ramp(ramp), .ch(uo_out[5]));
  pwm_channel pwmch_6 (.value(ui_in ^ 8'h60), .ramp(ramp), .ch(uo_out[6]));
  pwm_channel pwmch_7 (.value(ui_in ^ 8'h70), .ramp(ramp), .ch(uo_out[7]));
*/

  wire        i2c_rw;
  wire [7:0]  i2c_addr;
  wire        i2c_wen;
  wire [7:0]  i2c_wdata;
  wire        i2c_rdata_used;
  reg  [7:0]  i2c_rdata;

  i2c_slave i2c
  (
    .clk(clk),
    .rst_n(rst_n),
    .sda_o(uio_out[1]),
    .sda_oe(uio_oe[1]),
    .sda_i(uio_in[1]),
    .scl(uio_in[2]),

    // application interface
    .rw(i2c_rw),
    .addr(i2c_addr),
    .wen(i2c_wen),
    .wdata(i2c_wdata),
    .rdata_used(i2c_rdata_used),
    .rdata(i2c_rdata)
  );
  assign uio_oe[2]  = 1'b0; // SCL is input
  assign uio_out[2] = 1'b0;

  always @(ui_in or negedge rst_n) begin
    if (!rst_n)
      i2c_control <= 0;
    if (!i2c_control || !rst_n) begin
      pwm_val[0] <= ui_in;
      pwm_val[1] <= (ui_in == 0) ? 0 : ui_in ^ 8'h10;
      pwm_val[2] <= (ui_in == 0) ? 0 : ui_in ^ 8'h20;
      pwm_val[3] <= (ui_in == 0) ? 0 : ui_in ^ 8'h30;
      pwm_val[4] <= (ui_in == 0) ? 0 : ui_in ^ 8'h40;
      pwm_val[5] <= (ui_in == 0) ? 0 : ui_in ^ 8'h50;
      pwm_val[6] <= (ui_in == 0) ? 0 : ui_in ^ 8'h60;
      pwm_val[7] <= (ui_in == 0) ? 0 : ui_in ^ 8'h70;
    end
  end

  // Write to PWM control registers
  always @(posedge clk) begin
    if ((i2c_addr < 8) && i2c_wen) begin
      i2c_control <= 1;
      pwm_val[i2c_addr] <= i2c_wdata;
    end
  end

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_oe[0]  = 1'b0;
  assign uio_out[0] = 1'b0;
  assign uio_out[7:3] = 5'b0;
  assign uio_oe[7:3]  = 5'b0;

endmodule
