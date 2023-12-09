/*############################################################
##     Author: Engineer Youssef Nasser                      ##
##     Inferred Single-Port Memory                          ##
##     Verification using UVM                               ##                 
##     Async reset and Sync Write and Read Operation        ##
##     Copyright (c) 2023  DV Analyst Diploma               ##
#      round 10 Dr:Sherif   PhD. Sherif Hosny               ##
##     All rights reserved.                         	      ##
############################################################*/




/*############################################################
#                    CLASSES & UVM PACKAGE                   #
############################################################*/

package classes;

import uvm_pkg::*;
`include "uvm_macros.svh"

/*############################################################
#                    sequence_item CLASSE                    #
############################################################*/

class my_sequence_item extends uvm_sequence_item; // uvm_sequence_item extend uvm_transaction. //Object

  //      Registeration
  `uvm_object_utils (my_sequence_item);

  //      Declarations 
  bit rst;                       // Reset signal
  rand  logic [7:0] data_in;      // Data input (8 bits)
  rand  logic       WE;                 // Write enable
  rand  logic       RE;                 // Read enable
  randc logic [7:0] addr;        // Address input (8 bits)
  logic [7:0] data_out;          // Data output (8 bits)
  logic       valid_out;               // Valid output

  //    Dummy Constructor 
  function new(string name ="my_sequence_item");
    super.new(name);
    this.rst = 1'b0;
    this.data_in = 8'b0;
    this.WE = 1'b0;
    this.RE = 1'b0;
    this.addr = 8'b0;
    this.data_out = 8'b0;
    this.valid_out = 1'b0;
  endfunction

  // Randomization Constraints
  constraint const0 { data_in inside {[0:((2**8)-1)]}; }
  constraint const4 { addr inside {[0:((2**8)-1)]}; } // 2 power 8


endclass



/*############################################################
#                       sequence CLASS                       #
############################################################*/

class my_sequence extends uvm_sequence #(my_sequence_item);// test case 
  //      Registeration
  `uvm_object_utils (my_sequence);
  //      Declarations 
  my_sequence_item sequence_item;
  int i,j;
  //    Dummy Constructor 
  function new(string name ="my_sequence");
    super.new(name);
  endfunction

  task pre_body; // Build phase of object class
    sequence_item = my_sequence_item::type_id::create("sequence_item");
  endtask

  task body;  //Run phase of object class

    // direct reset
    start_item(sequence_item);
    sequence_item.rst = 1'b0;
    finish_item(sequence_item);

    start_item(sequence_item);
    sequence_item.rst = 1'b1;
    finish_item(sequence_item);

    start_item(sequence_item);
    sequence_item.rst = 1'b1;            
    sequence_item.data_in='d100;  
    sequence_item.WE=1'b1;      
    sequence_item.RE=1'b0;     
    sequence_item.addr= 'd300;  
    $display("adds out of range");     
    finish_item(sequence_item);

    for(i=0; i<1000; i++)
      begin
        start_item(sequence_item);
        void'(sequence_item.randomize()  with { sequence_item.WE == 1 && !sequence_item.RE; });
        finish_item(sequence_item);
      end

    for(j=0; j<1256; j++)
      begin
        start_item(sequence_item);
        void'(sequence_item.randomize()  with { sequence_item.RE == 1  && !sequence_item.WE; });
        finish_item(sequence_item);
      end

  endtask



endclass

/*############################################################
#                       sequencer  CLASSE                    #
############################################################*/
// UVM handle everything (built in)
class my_uvm_sequencer extends uvm_sequencer #(my_sequence_item);
  `uvm_component_utils (my_uvm_sequencer);
  // my_sequence_item seq3;
  function new(string name ="my_uvm_sequencer",uvm_component parent = null);
    super.new(name,parent);
  endfunction



  //instante
  my_sequence_item sequence_seq_item;
  //buliding phase
  function void build_phase (uvm_phase phase); 
    super.build_phase(phase);
    //create method for object
    sequence_seq_item=my_sequence_item::type_id::create("sequence_seq_item");
    $display("BUILDING PHASE OF MY SEQUENCER");
  endfunction
  //connecting phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    $display("CONNECTING PHASE OF MY SEQUENCER");
  endfunction
  //running phase
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    $display("RUNNING PHASE OF MY SEQUENCER");
  endtask


  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction




endclass



/*############################################################
#                       driver  CLASSE                       #
############################################################*/

class my_uvm_driver  extends uvm_driver  #(my_sequence_item);
  `uvm_component_utils (my_uvm_driver); // registeration at factory 
  my_sequence_item seq1;
  virtual intf1 vif; 
  function new(string name ="my_uvm_driver",uvm_component parent = null);
    super.new(name,parent); //uvm_driver
  endfunction
  //build
  function void build_phase(uvm_phase phase); // top down 3ashn hariarchy el uvm kda asln
    super.build_phase(phase);
    $display("driver build phase");
    seq1 = my_sequence_item::type_id::create("seq1"); // seq1 = new;
    //resources  
    if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",vif))
      `uvm_fatal(get_full_name(),"Error y zamala!")
      endfunction
      //connect
      function void connect_phase(uvm_phase phase); // bottom up?
    super.connect_phase(phase);
    $display(" driver connect phase");
  endfunction
  //run
  task run_phase(uvm_phase phase); // parallel 
    super.run_phase(phase);
    forever 
      begin

        @(negedge vif.clk) begin
          seq_item_port.get_next_item (seq1);
          vif.rst   <=  seq1.rst;  
          vif.data_in   <=  seq1.data_in; 
          vif.WE        <=  seq1.WE;      
          vif.RE        <=  seq1.RE;     
          vif.addr      <=  seq1.addr; 
          #1step 
          seq_item_port.item_done();
        end
      end
    $display("driver run phase");
  endtask
  //extract
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction

endclass

/*############################################################
#                       monitor  CLASSE                      #
############################################################*/


class my_uvm_monitor extends uvm_monitor;
  `uvm_component_utils (my_uvm_monitor);
  my_sequence_item seq2;
  virtual intf1 vif; 
  uvm_analysis_port #(my_sequence_item) analysis_port;
  logic [7:0] temp_adds;
  function new(string name ="my_uvm_monitor",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  //build
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    $display("monitor build phase");
    seq2 = my_sequence_item::type_id::create("seq2");
    analysis_port = new ("analysis_port",this);
    //resources    virtual intf1 vif; 
    if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",vif))
      `uvm_fatal(get_full_name(),"Error y zamala!")
      endfunction
      //connect
      function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    $display(" monitor connect phase");
  endfunction
  //run
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever
      begin
        @(negedge vif.clk)
        begin
          seq2.data_out <= vif.data_out;
          seq2.valid_out <= vif.valid_out;
          seq2.data_in  <=   vif.data_in ;
          seq2.rst  <=   vif.rst ;
          seq2.WE <=     vif.WE  ;
          seq2.RE <=   vif.RE ;  
          seq2.addr <=   vif.addr ;
          #1step
          analysis_port.write(seq2);
          //end
        end
        //$display("monitor run phase");
      end
  endtask
  //extract
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction
endclass



/*############################################################
#                       agent  CLASSE                        #
############################################################*/

class my_uvm_agent extends uvm_agent;
  `uvm_component_utils (my_uvm_agent); 
  my_uvm_driver drv;
  my_uvm_monitor mon;
  my_uvm_sequencer sequ;
  virtual intf1 vif; 
  function new(string name ="my_uvm_agent",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  //build
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    $display("agent build phase");
    drv = my_uvm_driver::type_id::create("drv",this);
    mon = my_uvm_monitor::type_id::create("mon",this);
    sequ = my_uvm_sequencer::type_id::create("sequ",this);
    //resources    
    if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",vif))
      `uvm_fatal(get_full_name(),"Error y zamala!")
      uvm_config_db#(virtual intf1)::set(this,"drv","my_vif",vif);
    uvm_config_db#(virtual intf1)::set(this,"mon","my_vif",vif);
  endfunction
  //connect
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sequ.seq_item_export);
    $display("agent connect phase");
  endfunction
  //run
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    $display("agent run phase");
  endtask
  //extract
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction
endclass

/*############################################################
#                       scoreboard  CLASSE                   #
############################################################*/

class my_uvm_score extends uvm_scoreboard;
  `uvm_component_utils (my_uvm_score); 

  static int error_Count;
  static int successfully_test;
  logic [7:0] golden_memory [255:0];
  my_sequence_item seq4;


  uvm_analysis_imp #(my_sequence_item,my_uvm_score) analysis_imp1;
  function new(string name ="my_uvm_score",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  //build
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    $display("score build phase");
    seq4 = my_sequence_item::type_id::create("seq4",this);
    analysis_imp1 = new("analysis_imp1",this);
  endfunction
  //connect
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    $display("score connect phase");
  endfunction

  // golden model
  task my_checker(my_sequence_item SEQ);	  
    seq4 = SEQ;
    $display("seq4 %p",seq4);
    if (seq4.rst == 1'b0) begin

      for (int i = 0; i < 256; i = i + 1) begin
        golden_memory[i] = 8'b0;
      end
    end
    else if (seq4.WE) begin
      $display("ID:1");
      golden_memory[seq4.addr] = seq4.data_in;
      $display("ID:1 data in",seq4.data_in);
      $display("ID:1 adds at writing is %d",seq4.addr);
      $display("ID:1 golden_memory at write operation is %d",golden_memory[seq4.addr]);
    end


    if (seq4.rst == 1'b0) begin
      if (seq4.valid_out == 1'b0) begin
        successfully_test++;
        $display("functionality is correct");
      end
      else begin
        $display("error @ this transaction at valid_out %0t %p", $time, seq4);
        error_Count++;
      end
    end


    if(seq4.valid_out)
      if (golden_memory[seq4.addr] != seq4.data_out) begin
        $display("error");
        error_Count++;

        $display("ID:2");
        $display("golden_memory is %d",golden_memory[seq4.addr]);
        $display("data out is %d",seq4.data_out);
        $display("adds at checking is %d",seq4.addr);
        $display("error @ this transaction %0t %p", $time, seq4);
      end
    else begin
      $display("test casee passed successfully");
      successfully_test++;
      $display("test passed and the transaction was %p at time %0t", seq4, $time);
    end

  endtask


  task Errors();
    // tssk to display errors and test results
    $display("number of succeed tests is %0d", successfully_test);
    if (error_Count == 0) begin
      $display("Simulation completed successfully!");
      $display("data out is %d at adds = %d ",seq4.data_out,seq4.addr);
    end
    else
      $display("the number of errors is %0d", error_Count);
  endtask

  virtual task write(my_sequence_item SEQ);
    $display("hello joe");
    seq4 = SEQ;
    my_checker(seq4);

    Errors();
  endtask 
  //run
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    $display("score run phase");
  endtask
  //extract
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction
endclass

/*############################################################
#                       subscriber  CLASSE                   #
############################################################*/

class my_uvm_subscriber  extends uvm_subscriber #(my_sequence_item);
  `uvm_component_utils (my_uvm_subscriber);
  my_sequence_item seq5;

  covergroup cg_data_valid();
    valid_out_cp: coverpoint seq5.valid_out;
  endgroup

  covergroup cg_data_out();
    data_out_cp: coverpoint seq5.data_out;
  endgroup

  covergroup cross_grp();
    cv1: coverpoint seq5.data_out;
    cv2: coverpoint seq5.valid_out {
      bins bin1[1] = {1};
    }
    cross cv1, cv2;
  endgroup

  //uvm_analysis_imp #(my_sequence_item,my_uvm_subscriber) analysis_imp1;
  function new(string name ="my_uvm_subscriber",uvm_component parent = null);
    super.new(name,parent);

    cg_data_valid = new;
    cg_data_out = new;
    cross_grp = new;
  endfunction
  //build
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    $display("subscriber build phase");
    seq5 = my_sequence_item::type_id::create("seq5",this);
    //analysis_imp1 = new("analysis_imp",this);
  endfunction
  //connect
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    $display("subscriber connect phase");
  endfunction
  //run
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    $display("subscriber run phase");
  endtask
  //extract
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction
  function void write (my_sequence_item t); // write  TLM 
    $display("hello round10");
    seq5 = t;
    cg_data_valid.sample();
    cg_data_out.sample();
    cross_grp.sample();
    $display("time is %0t coverage_valid is %f ", $time, cg_data_valid.get_coverage());
    $display("time is %0t coverage is %f ", $time, cg_data_out.get_coverage());

  endfunction
endclass

/*############################################################
#                       environment  CLASSE                  #
############################################################*/

class my_uvm_env extends uvm_env;
  `uvm_component_utils (my_uvm_env); 
  my_uvm_agent agent1;
  my_uvm_subscriber sub1;
  my_uvm_score score1;
  virtual intf1 vif;  
  function new(string name ="my_uvm_env",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  //build
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    $display("env build phase");
    agent1 = my_uvm_agent::type_id::create("agent1",this);
    sub1 = my_uvm_subscriber::type_id::create("sub1",this);
    score1 = my_uvm_score::type_id::create("score1",this);
    //resources 
    if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",vif))
      `uvm_fatal(get_full_name(),"Error y zamala!")
      uvm_config_db#(virtual intf1)::set(this,"agent1","my_vif",vif);
  endfunction
  //connect
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent1.mon.analysis_port.connect(score1.analysis_imp1);
    agent1.mon.analysis_port.connect(sub1.analysis_export); // check subscriber class from uvm
    $display("env connect phase");
  endfunction
  //run
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    $display("env run phase");
  endtask
  //extract
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction
endclass

/*############################################################
#                       test  CLASSE                         #
############################################################*/

class my_uvm_tst extends uvm_test;
  `uvm_component_utils (my_uvm_tst); 

  my_uvm_env env1;
  my_sequence my_seq;
  virtual intf1 vif; 
  function new(string name ="my_uvm_tst",uvm_component parent = null);
    super.new(name,parent);
  endfunction

  //build
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    $display("tst build phase");
    //new
    env1 = my_uvm_env::type_id::create("env1",this);
    my_seq = my_sequence::type_id::create("my_seq");
    //resources  
    if(!uvm_config_db#(virtual intf1)::get(this,"","my_vif",vif))
      `uvm_fatal(get_full_name(),"Error y zamala!")
      uvm_config_db#(virtual intf1)::set(this,"env1","my_vif",vif);
  endfunction
  //connect
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    $display("tst connect phase");
  endfunction
  //run
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this,"Starting Sequences");
    my_seq.start(env1.agent1.sequ); // shghal al sequence 3la al sequencer 
    phase.drop_objection(this,"Finished Sequences");
    $display("tst run phase");
  endtask
  //extract
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction
endclass


endpackage

/*############################################################
#                       interface	                         #
############################################################*/
// Definition of the 'vif' interface
interface intf1(input bit clk);

  // initialiazation in testbench is better
  logic [7:0] data_in   = 0;    // Data input (8 bits)
  logic       WE        = 0;              // Write enable
  logic       RE        = 0;              // Read enable
  logic [7:0] addr      = 0;      // Address input (8 bits)
  bit         rst       = 0;               // Reset input
  logic [7:0] data_out;
  logic       valid_out;


endinterface

/*############################################################
#                         TESTBENCH                          #
############################################################*/

module top_uvmm;
  `timescale 1ns/1ps
  import classes::*;
  // import pack1::*;
  import uvm_pkg::*;
  parameter clk_period = 10; // 100 MHz
  bit clk =1'b0;
  always #(clk_period / 2) clk = ~clk;
  intf1 intf(clk);
  Inferred_Single_Port_Memory DUT(intf); // won't access signals in eda playground

  initial
    begin
      uvm_config_db #(virtual intf1)::set(null,"uvm_test_top","my_vif",intf); //set(contxt,scope,name,value)
      run_test("my_uvm_tst");
    end

endmodule

/*############################################################
#                        Have A Good Day                     #
############################################################*/