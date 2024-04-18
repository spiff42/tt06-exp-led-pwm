/* By agreement to Mogens Isager, spiff42 copied this module.
 *
 * Copyright 2024 Mogens Isager
 * SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 * 
 * Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may
 * not use this file except in compliance with the License, or, at your option,
 * the Apache License version 2.0. You may obtain a copy of the License at
 * 
 * https://solderpad.org/licenses/SHL-2.1/
 * 
 * Unless required by applicable law or agreed to in writing, any work
 * distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

 module i2c_slave (
    input 		clk, reset_b,
    input 		pready,
    input [PDATA_WL-1:0] 	prdata,
    output [PDATA_WL-1:0] pwdata,
    output [PADDR_WL-1:0] paddr,
    output reg 		penable, psel, pwrite,
    input [6:0] 		device_address,
    input 		scl_in, sda_in,
    output 		scl_out, sda_out);
  
  
     //-----------------------------------------------------------------
     // External and internal parameters and constants
     //-----------------------------------------------------------------
  
     parameter PADDR_WL = 8;
     parameter PDATA_WL = 8;
  
     localparam DATA_WL = 8;
     localparam DEGLITCH_WL = 3;
     localparam OPER_WL = 2;
     localparam STATE_WL = 3;
  
  
     localparam DEVICE_OP = 0;
     localparam ADDR_OP = 1;
     localparam DATA_OP = 2;
  
     localparam IDLE_ST       = 0;
     localparam STARTED_ST    = 1;
     localparam WRITE_ST      = 2;
     localparam WRITE_DONE_ST = 3;
     localparam WRITE_ACK_ST  = 4;
     localparam READ_ST       = 5;
     localparam READ_DONE_ST  = 6;
     localparam READ_ACK_ST   = 7;
  
  
     //-----------------------------------------------------------------
     // 
     //-----------------------------------------------------------------
  
     reg 			ack;
     reg [3:0] 		bit_cnt;
     reg 			bit_cnt_clr;
     reg 			bit_cnt_en;
  
     reg [PADDR_WL-1:0] 	addr;
     reg 			addr_en;
     reg 			addr_inc;
  
     reg [DEGLITCH_WL-1:0] scl_d, sda_d;
     reg [OPER_WL-1:0] 	 oper, oper_next;
     reg [STATE_WL-1:0] 	 state, state_next;
     reg [STATE_WL-1:0] 	 amba_st, amba_next;
     reg 			 amba_write;
     reg 			 amba_read;
  
     reg [DATA_WL-1:0] 	 data;
     reg 			 data_en;
     reg 			 data_amba;
  
  
     //-----------------------------------------------------------------
     // Helper functions
     //-----------------------------------------------------------------
  
     function high;
        input [DEGLITCH_WL-1:0] s;
        high = s[DEGLITCH_WL-1:DEGLITCH_WL-2] == 2'b11;
     endfunction
  
     function rising;
        input [DEGLITCH_WL-1:0] s;
        rising = s[DEGLITCH_WL-1:DEGLITCH_WL-2] == 2'b01;
     endfunction
  
     function falling;
        input [DEGLITCH_WL-1:0] s;
        falling = s[DEGLITCH_WL-1:DEGLITCH_WL-2] == 2'b10;
     endfunction
  
  
     //-----------------------------------------------------------------
     // Outpute and registers
     //-----------------------------------------------------------------
  
     assign scl_out = 1'b1;
     assign sda_out = ack == 0 ? 0 : 1'b1;
  
     assign paddr = psel ? addr : 0;
     assign pwdata = psel && pwrite ? data : 0;
     
     // SCL and SDA de-glitchers
     always @(posedge clk or negedge reset_b)
       if (! reset_b)
         begin
        scl_d <= 0;
        sda_d <= 0;
         end
       else
         begin
        scl_d <= { scl_d[DEGLITCH_WL-2:0], scl_in }; 
        sda_d <= { sda_d[DEGLITCH_WL-2:0], sda_in }; 
         end
  
     // Bit counter with clear and enable
     always @(posedge clk or negedge reset_b)
       if (! reset_b)
         bit_cnt <= 0;
       else if (bit_cnt_clr)
         bit_cnt <= 0;
       else if (bit_cnt_en)
         bit_cnt <= bit_cnt+1;
  
     // Address regsiter
     always @(posedge clk or negedge reset_b)
       if (! reset_b)
         addr <= 0;
       else if (addr_en)
         addr <= data[PADDR_WL-1:0];
       else if (addr_inc)
         addr <= addr+1;
  
     // Data regsiter
     always @(posedge clk or negedge reset_b)
       if (! reset_b)
         data <= 0;
       else if (data_en)
         data <= { data[DATA_WL-2:0], sda_d[DEGLITCH_WL-2] };
       else if (data_amba)
         data <= prdata;
  
     
     //-----------------------------------------------------------------
     // I2C bus state machine
     //-----------------------------------------------------------------
  
     always @(posedge clk or negedge reset_b)
       if (! reset_b)
         begin
        oper <= DEVICE_OP;
        state <= IDLE_ST;
         end
       else
         begin
        oper <= oper_next;
        state <= state_next;
         end
  
     always @(*)
       begin
      addr_en     <= 0;
      ack         <= 1'b1;
      bit_cnt_clr <= 0;
      bit_cnt_en  <= 0;
      data_en     <= 0;
      amba_read   <= 0;
      amba_write  <= 0;
  
      oper_next <= oper;
      state_next <= state;
  
      if (high(scl_d) && rising(sda_d))
        begin
           oper_next <= DEVICE_OP;
           state_next <= IDLE_ST;
        end
      else
        case (state)
          IDLE_ST:
            begin
           bit_cnt_clr <= 1'b1;
  
           if (high(scl_d) && falling(sda_d)) // start condition
             state_next <= STARTED_ST;
            end
  
          STARTED_ST:
            begin
           oper_next <= DEVICE_OP;
           if (rising(scl_d))
             state_next <= WRITE_ST;
            end
          
          WRITE_ST:
            begin
           if (falling(scl_d))
             begin
                data_en <= 1'b1;
  
                if (bit_cnt == 4'd7)
              state_next <= WRITE_DONE_ST;
                else
              bit_cnt_en <= 1'b1;
             end
  
           else if (high(scl_d) && falling(sda_d)) // repeated start
             state_next <= STARTED_ST;
            end
  
          WRITE_DONE_ST:
            case (oper)
          DEVICE_OP:
            if (data[DATA_WL-1:1] == device_address)
              state_next <= WRITE_ACK_ST;
            else
              state_next <= IDLE_ST;
          ADDR_OP:
            begin
               addr_en <= 1'b1;
               state_next <= WRITE_ACK_ST;
            end
          DATA_OP:
            begin
               amba_write <= 1'b1;
               state_next <= WRITE_ACK_ST;
            end
          default:
            state_next <= IDLE_ST;
            endcase
  
          WRITE_ACK_ST:
            begin
            ack <= 0;
           bit_cnt_clr <= 1'b1;
  
           if (falling(scl_d))
             begin
                if (oper == DEVICE_OP && data[0] == 1'b0)
              begin
                 oper_next <= ADDR_OP;
                 state_next <= WRITE_ST;
              end
                else if (oper == ADDR_OP || oper == DATA_OP)
              begin
                 oper_next <= DATA_OP;
                 state_next <= WRITE_ST;
              end
                else
              begin
                 amba_read <= 1'b1;
                 state_next <= READ_ST;
              end
             end
            end
  
          READ_ST:
            begin
           ack <= data[DATA_WL-1-bit_cnt];
           if (falling(scl_d))
             begin
                if (bit_cnt == 4'd7)
              state_next <= READ_DONE_ST;
                else
              bit_cnt_en <= 1'b1;
             end
            end
  
          READ_DONE_ST:
            begin
           bit_cnt_clr <= 1'b1;
           if (rising(scl_d))
             if (sda_d[DEGLITCH_WL-2] == 1'b0) // ack
               begin
              amba_read <= 1'b1;
              state_next <= READ_ACK_ST;
               end
             else // nack
               state_next <= IDLE_ST;
            end
  
          READ_ACK_ST:
            if (falling(scl_d))
          state_next <= READ_ST;
        endcase
       end
  
  
     //-----------------------------------------------------------------
     // AMBA APB bus state machine
     //-----------------------------------------------------------------
  
     always @(posedge clk or negedge reset_b)
       if (! reset_b)
         amba_st <= IDLE_ST;
       else
         amba_st <= amba_next;
  
     always @(*)
       begin
      psel     <= 0;
      penable  <= 0;
      pwrite   <= 0;
      addr_inc <= 0;
      data_amba <= 0;
  
      amba_next <= amba_st;
      
      case (amba_st)
        IDLE_ST:
          if (amba_write)
            amba_next <= WRITE_ST;
          else if (amba_read)
            amba_next <= READ_ST;
        
        WRITE_ST:
          begin
             psel <= 1'b1;
             pwrite <= 1'b1;
             amba_next <= WRITE_DONE_ST;
          end
  
        WRITE_DONE_ST:
          begin
             psel <= 1'b1;
             penable <= 1'b1;
             pwrite <= 1'b1;
             addr_inc <= 1'b1;
             amba_next <= IDLE_ST;
          end
  
        READ_ST:
          begin
             psel <= 1'b1;
             amba_next <= READ_DONE_ST;
          end
  
        READ_DONE_ST:
          begin
             psel <= 1'b1;
             penable <= 1'b1;
             addr_inc <= 1'b1;
             data_amba <= 1'b1;
             amba_next <= IDLE_ST;
          end
      endcase
       end
     
  endmodule
  