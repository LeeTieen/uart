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
  logic                     fftx_notempty;
  logic                     txdone, txstart; 
  logic                     rxdone;

  
  uart_baud_gen u_bg
                (
                  .clk_i       (clk_i),
                  ._rst_i      (_rst_i),
                  .tick_o      (tick)
                );
  uart_rx #(.DATA_WIDTH(DATA_WIDTH))u_rx
         (
           .clk_i       (clk_i),
           .uartrx_i    (uartrx_i),
           .baudtick_i  (tick),
           .uartrx_o    (uartrx_ff),
           .rxdone_o    (rxdone),
           ._rst_i      (_rst_i)
         );

  fifo_sync #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(8)
  )ff_rx
       (
         .clk           (clk_i),
         .rst_n         (_rst_i),
         .din           (uartrx_ff),
         .rd_en         (rdrx_en_i),
         .wr_en         (rxdone),
         .not_empty     (rx_notem_o),
         .full          (rxfull_o),
         .dout          (uartrx_o)
       );
  uart_tx #(.DATA_WIDTH(DATA_WIDTH))u_tx
         (
           .clk_i       (clk_i),
           .uarttx_i    (uarttx_ff),
           .baudtick_i  (tick), 
           .txstart_i   (fftx_notempty),  
           .uarttx_o    (uarttx_o), 
           .txdone_o    (txdone),
           ._rst_i      (_rst_i)
         );

  fifo_sync #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(8)
  )ff_tx
       (
         .clk           (clk_i),
         .rst_n         (_rst_i),
         .din           (uarttx_i),
         .rd_en         (txdone),
         .wr_en         (wrtx_en_i),
         .not_empty     (fftx_notempty),
         .full          (txfull_o),
         .dout          (uarttx_ff)
       );


endmodule
