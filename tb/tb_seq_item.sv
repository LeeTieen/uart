class tb_seq_item extends uvm_sequence_item;
    `uvm_object_utils(tb_seq_item)

    function new(
        string name = "seq_item"
    );
        super.new(name);
    endfunction

    bit                    clk_i;
    bit                    _rst_i;
    bit                    uartrx_i;
    bit                    rdrx_en_i;
    bit [DATA_WIDTH-1:0]   uarttx_i;
    bit                    wrtx_en_i; 

    bit [DATA_WIDTH-1:0]   uartrx_o;
    bit                    rx_notem_o;
    bit                    rxfull_o;
    bit                    uarttx_o; 
    bit                    txfull_o;

    bit [DATA_WIDTH-1:0]   uartrx_o_after;
    bit                    rx_notem_o_after;
    bit                    rxfull_o_after;
    bit                    uarttx_o_after; 
    bit                    txfull_o_after;
endclass