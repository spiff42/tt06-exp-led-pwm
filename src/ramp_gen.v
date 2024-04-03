
module ramp_gen (input clk, input reset, output [7:0] ramp);
  reg [7:0] ramp_low;
  reg [7:0] ramp_high;
  
  assign ramp = ramp_high;

  always @(posedge clk or posedge reset)
    begin
      if (reset) begin
        ramp_low <= 0;
        ramp_high <= 0;
      end else begin
        ramp_low <= ramp_low + 1;
        //if (ramp_low == 8'd0)
            ramp_high <= ramp_high + 1;
      end
    end

endmodule