
// Compares the input and ramp, settting the output ch
// Assuming ramp goes from 0-255, ch will be a PWM signal wit a
// duty cycle as defined by value.
module pwm_channel (input [7:0] value, input [7:0] ramp, output reg ch);
    always @(*)
    begin
        if (ramp >= value)
            ch = 0;
        else
            ch = 1;
    end
endmodule

