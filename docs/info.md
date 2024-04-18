<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is an 8-channel PWM controller for LED brightness.

The PWM duty cycle is generated according to an X^3^ curve, so the 
"percieved brightness" changes linearly with the register
setting. This design means we get the dynamic range of a 16-bit PWM but
use only 8 bits to specify the desired output. With an input clock of 32.7
MHz, the PWM frequency is 500 Hz.

## How to test

Play with the DIP-switches to see different segments of the 7-segment LED
display show different brightnesses.

## External hardware

Currently no external hardware is supported.
