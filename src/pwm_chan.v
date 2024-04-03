
module pwm_chan (input [7:0] value, input [7:0] ramp, output reg ch);
    always @(*)
    begin
/*
                if (value == 8'b00000000)
            ch <= 0; // Edge case: 0% PWM
        else if (value == 8'b11111111)
            ch <= 1; // Edge case: 100% PWM
        else
            */
        begin
            if (ramp >= value)
                ch <= 0;
            else
                ch <= 1;
            
        end
    end
endmodule
