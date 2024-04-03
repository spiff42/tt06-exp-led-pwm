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

  ramp_gen dut (.clk(clk), .reset(~rst_n), .ramp(ramp));
  pwm_chan pwmch (.value(ui_in), .ramp(ramp), .ch(uo_out[0]));


  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[7:1] = 0;
  assign uio_out = 0;
  assign uio_oe  = 0;

endmodule
