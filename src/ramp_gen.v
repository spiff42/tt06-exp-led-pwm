/*
 * Copyright (c) 2024 Mikkel Holm Olsen (spiff42)
 * SPDX-License-Identifier: Apache-2.0
 * Description: This module generates a ramp signal rising
 *   from 0 to 255, but where the first 16 steps take only
 *   1 clock each, the next 16 take 6 clocks. The last 16 steps
 *   (240-255) each take 724 clocks, for a total of 65535 clocks.
 *   The values are chosen to approximately match an X^3-curve,
 *   so fading looks "natural" to the huma eye.
 */

module ramp_gen (input clk, input reset, output [7:0] ramp);
  reg [9:0] ramp_low;
  reg [7:0] ramp_high;
  
  reg [9:0] low_limit;

  assign ramp = ramp_high;

  always @(ramp_high[7:4])
    begin
      case(ramp_high[7:4])
        4'd00 : low_limit = 1;
        4'd01 : low_limit = 6;
        4'd02 : low_limit = 19;
        4'd03 : low_limit = 36;
        4'd04 : low_limit = 60;
        4'd05 : low_limit = 90;
        4'd06 : low_limit = 126;
        4'd07 : low_limit = 168;
        4'd08 : low_limit = 216;
        4'd09 : low_limit = 271;
        4'd10 : low_limit = 313;
        4'd11 : low_limit = 397;
        4'd12 : low_limit = 473;
        4'd13 : low_limit = 545;
        4'd14 : low_limit = 633;
        4'd15 : low_limit = 724;
      endcase
    end

  always @(posedge clk or posedge reset)
    begin
      if (reset) begin
        ramp_low <= 0;
        ramp_high <= 0;
      end else begin
        if (ramp_low + 1 != low_limit)
          ramp_low <= ramp_low + 1;
        else begin
          ramp_high <= ramp_high + 1;
          ramp_low <= 0;
        end
      end
    end
endmodule

