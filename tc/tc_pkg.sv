`timescale 1ns/1ps

package tc_pkg;
    import uvm_pkg::*;
    import tb_pkg::*;
    
    `include "uvm_macros.svh"
    `include "tc_reset.sv"
    `include "tc_tx_one.sv"
    `include "tc_tx_multi.sv"
    `include "tc_tx_full.sv"
    `include "tc_tx_reset.sv"
    `include "tc_rx_one.sv"
    `include "tc_rx_multi.sv"
    `include "tc_rx_empty.sv"
    `include "tc_rx_full.sv"
    `include "tc_rx_overflow.sv"
    `include "tc_rx_reset.sv"
    `include "tc_full_duplex.sv"
    `include "tc_host_simultaneous.sv"
    `include "tc_rx_back_to_back.sv"
    `include "tc_wire_loopback.sv"
    `include "tc_echo.sv"
    `include "tc_data_all_values.sv"
    `include "tc_tx_random.sv"
    `include "tc_rx_random.sv"
    `include "tc_mixed_random.sv"

endpackage