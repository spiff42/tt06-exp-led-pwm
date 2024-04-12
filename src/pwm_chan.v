
module pwm_chan (input [7:0] value, input [7:0] ramp, output reg ch);
    always @(*)
    begin
        if (ramp >= value)
            ch = 0;
        else
            ch = 1;
    end
endmodule

