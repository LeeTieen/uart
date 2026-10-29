`timescale 1ns/1ps

interface uart_inf #(
    parameter int DATA_WIDTH = 8
)();

    logic                    clk_i;
    logic                    _rst_i;
    logic                    uartrx_i;
    logic                    rdrx_en_i;
    logic [DATA_WIDTH-1:0]   uarttx_i;
    logic                    wrtx_en_i; 

    logic [DATA_WIDTH-1:0]   uartrx_o;
    logic                    rx_notem_o;
    logic                    rxfull_o;
    logic                    uarttx_o; 
    logic                    txfull_o;

endinterface