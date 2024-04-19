
// Compares the input and ramp, settting the output ch
// Assuming ramp goes from 0-255, ch will be a PWM signal with a
// duty cycle as defined by value.
module pwm_channel (input [7:0] value, input [7:0] ramp, output reg ch);
    always @(*)
    begin
        if ((ramp < value) || (value == 255))
            ch = 1;
        else
            ch = 0;
    end
endmodule

