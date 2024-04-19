# SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@tinytapeout.com>
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer
from i2c import I2cMaster

@cocotb.test()
async def test_pwm(dut):

  i2c = I2cMaster(sda=dut.sda, sda_o=dut.sda_tb,
                  scl=dut.scl, scl_o=dut.scl_tb, speed=400e3)

  dut._log.info("Start")

  clock = Clock(dut.clk, 30, units="ns")
  cocotb.start_soon(clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1

  # Set the input values, wait one clock cycle, and check the output
  dut._log.info("Test user inputs")
 
  await ClockCycles(dut.clk, 65536 * 2)

  dut.ui_in.value = 255

  await ClockCycles(dut.clk, 65536 * 2)

  dut.ui_in.value = 128

  await ClockCycles(dut.clk, 65536 * 2)

  dut._log.info("Test I2C")
  await i2c.write(0x6C, [0, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47])
  await i2c.send_stop()

  await ClockCycles(dut.clk, 65536 * 2)
  await i2c.write(0x6C, [2])
  data = await i2c.read(0x6C, 1)
  await i2c.send_stop()

  assert data[0] == 0x42

  await ClockCycles(dut.clk, 65536 * 2)
  await i2c.write(0x6C, [0x82])
  data = await i2c.read(0x6C, 6)
  await i2c.send_stop()
  dut._log.info("Test I2C")
  assert data == b'@Spiff'

  dut.ui_in.value = 0

  await ClockCycles(dut.clk, 65536 * 2)

  await Timer(10, 'ms')


