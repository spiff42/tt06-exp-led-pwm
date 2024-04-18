/*
 * Copyright (c) 2024 Mikkel Holm Olsen (spiff42)
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_spiff42_exp_led_pwm (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       clk,      // clock
    input  wire       rst_n,    // reset_n - low to reset
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [7:0] uio_in,   // IOs: Input path
    input  wire       ena       // will go high when the design is enabled
    /* verilator lint_on UNUSEDSIGNAL */
  );

  localparam PADDR_WL = 8;
  localparam PDATA_WL = 8;

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

  // hook up I2C IOs, we use UIO1=SDA and UIO2=SCL to use Rpi2040 I2C
  wire      scl_in = uio_in[2];
  wire      sda_in = uio_in[1];
  wire      scl_out;
  wire      sda_out;

  assign    uio_out[2] = 1'b0; // scl
  assign    uio_out[1] = 1'b0; // sda
  assign    uio_oe[2]  = ~scl_out;
  assign    uio_oe[1]  = ~sda_out;

  wire      pready = 1'b1;
  reg [7:0] i2c_rdata;
  wire [7:0] i2c_wdata;
  wire [7:0] paddr;
  wire penable;
  wire psel;
  wire pwrite;

  i2c_slave #(
    .PADDR_WL(PADDR_WL))
  i2c_inst (
    .clk(clk),
    .reset_b(rst_n),
    .pready(pready),
    .prdata(i2c_rdata),
    .pwdata(i2c_wdata),
    .paddr(paddr),
    .penable(penable),
    .psel(psel),
    .pwrite(pwrite),
    .device_address(7'h6C),
    .scl_in(scl_in),
    .sda_in(sda_in),
    .scl_out(scl_out),
    .sda_out(sda_out)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      i2c_control <= 0;
    end else if (pwrite) begin
      // I2C write
      if (paddr < 8) begin
        i2c_control <= 1;
        pwm_val[paddr[2:0]] <= i2c_wdata;
      end
    end
    else if (!i2c_control) begin
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

  always @(*) begin
    if (paddr < 8) begin
      i2c_rdata = pwm_val[paddr[2:0]];
    end
    else
      i2c_rdata = 8'h00;
  end

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out[0] = 1'b0;
  assign uio_out[7:3] = 5'b0;
  assign uio_oe[0]  = 1'b0;
  assign uio_oe[7:3]  = 5'b0;

endmodule
