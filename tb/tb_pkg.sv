`timescale 1ns/1ps
package tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int DATA_WIDTH = 8;
    parameter int DEPTH      = 8;
    
    `include "tb_seq_item.sv"
    `include "tb_sequencer.sv"
    `include "tb_seq.sv"
    `include "tb_drv.sv"
    `include "tb_mon.sv"
    `include "tb_sco.sv"
    `include "tb_env.sv"
    `include "tb_test.sv"
endpackage