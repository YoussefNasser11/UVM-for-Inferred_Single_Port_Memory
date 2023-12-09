/*############################################################
##     Author: Engineer Youssef Nasser                      ##
##     Inferred Single-Port Memory                          ##                 
##     Async reset and Sync Write and Read Operation        ##
##     Copyright (c) 2023  DV Analyst Diploma               ##
#      round 10 Dr:Sherif   PhD. Sherif Hosny               ##
##     All rights reserved.                         	      ##
############################################################*/

module Inferred_Single_Port_Memory(intf1 vif);

  reg [7:0] memory [255:0];    // 256 locations, each with 8 bits
  integer i;

  // Write and Read operations
  always @(posedge vif.clk or negedge vif.rst) begin
    if (!vif.rst) 
      begin
        vif.valid_out <= 1'b0;
        vif.data_out  <= 8'b0;
        // Reset the memory to all zeros
        foreach (memory[i]) memory[i] <= 8'b0;
      end
    else if (vif.WE) begin
      // Write operation
      memory[vif.addr] <= vif.data_in;
      vif.valid_out <= 1'b0;
    end
    else if (vif.RE) begin
      // Read operation
      vif.valid_out <= 1'b1;
      vif.data_out <= memory[vif.addr];
    end
    else
      vif.valid_out <= 1'b0;
  end
endmodule


