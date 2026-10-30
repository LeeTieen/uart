`timescale 1ns/1ps
module tb_top;
   import uvm_pkg::*;
   import tb_pkg::*;

   localparam realtime CLK_PERIOD = 1s/12_000_000.0;

   uart_inf #(DATA_WIDTH) inf();

   uart #(
    .DATA_WIDTH(DATA_WIDTH)
   ) dut(
        .clk_i      (inf.clk_i),
        ._rst_i     (inf._rst_i),
        .uartrx_i   (inf.uartrx_i),
        .rdrx_en_i  (inf.rdrx_en_i),
        .uarttx_i   (inf.uarttx_i),
        .wrtx_en_i  (inf.wrtx_en_i), 

        .uartrx_o   (inf.uartrx_o),
        .rx_notem_o (inf.rx_notem_o),
        .rxfull_o   (inf.rxfull_o),
        .uarttx_o   (inf.uarttx_o), 
        .txfull_o   (inf.txfull_o)
   );

   initial inf.clk_i = 0;

   always #(CLK_PERIOD / 2.0)
        inf.clk_i = ~inf.clk_i;

    initial begin
        inf._rst_i      = 0;
        inf.uartrx_i    = 1; //idle
        inf.rdrx_en_i   = 0;
        inf.uarttx_i    = 0;
        inf.wrtx_en_i   = 0;

        uvm_config_db #(
            virtual uart_inf #(DATA_WIDTH)
        )::set(
            null,
            "uvm_test_top.env.*",
            "vif",
            inf
        );

        run_test("tb_test");
    end
endmodule