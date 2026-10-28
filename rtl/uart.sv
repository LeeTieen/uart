module uart #(parameter int DATA_WIDTH=8) 
  ( 
    input  logic                    clk_i,
    input  logic                    _rst_i,
    input  logic                    uartrx_i,
    input  logic                    rdrx_en_i,
    input  logic [DATA_WIDTH-1:0]   uarttx_i,
    input  logic                    wrtx_en_i, 

    output logic [DATA_WIDTH-1:0]   uartrx_o,
    output logic                    rx_notem_o,
    output logic                    rxfull_o,
    output logic                    uarttx_o, 
    output logic                    txfull_o
  );

  logic                     tick;
  logic [DATA_WIDTH-1:0]    uartrx_ff, uarttx_ff;
  logic                     ftx_notempty;
  logic                     txdone, txstart; 
  logic                     rxdone;

  
  uart_baud_gen ubg
                (
                  .clk_i       (clk_i),
                  ._rst_i      (_rst_i),
                  .tick_o      (tick)
                );
  uartrx urx
         (
           .clk_i       (clk_i),
           .uartrx_i    (uartrx_i),
           .baudtick_i  (tick),
           .uartrx_o    (uartrx_ff),
           .rxdone_o    (rxdone)
         );

  fifo_sync frx
       (
         .clk_i       (clk_i),
         ._rst_i      (_rst_i),
         .wrdata_i    (uartrx_ff),
         .rd_i        (rdrx_en_i),
         .wr_i        (rxdone),
         .notempty_o  (rx_notem_o),
         .full_o      (rxfull_o),
         .rddata_o    (uartrx_o)
       );
  uarttx utx
         (
           .clk_i       (clk_i),
           .uarttx_i    (uarttx_ff),
           .baudtick_i  (tick), 
           .txstart_i   (ftx_notempty),  
           .uarttx_o    (uarttx_o), 
           .txdone_o    (txdone)
         );

  fifo_sync ftx
       (
         .clk_i       (clk_i),
         ._rst_i      (_rst_i),
         .wrdata_i    (uarttx_i),
         .rd_i        (txdone),
         .wr_i        (wrtx_en_i),
         .notempty_o  (ftx_notempty),
         .full_o      (txfull_o),
         .rddata_o    (uarttx_ff)
       );


endmodule
