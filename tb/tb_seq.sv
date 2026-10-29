class tb_seq extends uvm_sequence #(tb_seq_item);
    `uvm_object_utils(tb_seq)

    function new(
        string name = "tb_seq"
    );

        super.new(name);

    endfunction

    task run(
        bit                    _rst_i,
        bit                    uartrx_i,
        bit                    rdrx_en_i,
        bit [DATA_WIDTH-1:0]   uarttx_i,
        bit                    wrtx_en_i
    );

        tb_seq_item seq;

        seq = tb_seq_item::type_id::create("seq");
        
        start_item(seq);

        seq._rst_i      = _rst_i;
        seq.uartrx_i    = uartrx_i;
        seq.rdrx_en_i   = rdrx_en_i;
        seq.uarttx_i    = uarttx_i;
        seq.wrtx_en_i   = wrtx_en_i;

        finish_item(seq);
    endtask

    task body();
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);
    endtask
endclass