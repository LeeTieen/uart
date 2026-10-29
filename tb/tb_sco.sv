class tb_sco extends uvm_scoreboard;

    `uvm_component_utils(tb_sco)

    uvm_analysis_imp #(
        tb_seq_item,
        tb_sco
    ) analysis_export;

    bit [DATA_WIDTH-1:0] ffrx_mem[$];
    bit [DATA_WIDTH-1:0] fftx_mem[$];

    int error_count = 0;

    function new(
        string name,
        uvm_component parent
    );

        super.new(name, parent);
        analysis_export = new("analysis_export", this);

    endfunction

    function void write(
        tb_seq_item seq
    );

        bit read_ok;
        bit write_ok;

        bit [DATA_WIDTH-1:0] expected_dout;

        if (!seq._rst_i) begin
            ffrx_mem.delete();
            fftx_mem.delete();

            if ((seq.uarttx_o !== 1'b1) || (seq.uartrx_o !== 1'b0)) begin
                `uvm_error(
                    "[SCO]",
                    "Reset: uarttx_o should be 1 and uartrx_o should be 0"
                )
                error_count++;
            end

            if (seq.rx_notem_o === 1'b1) begin
                `uvm_error(
                    "[SCO]",
                    "Reset: rx_notem_o should be 0"
                )
            end

            if ((seq.txfull_o !== 1'b0) || (seq.rxfull_o !== 1'b0)) begin
                `uvm_error(
                    "[SCO]",
                    "Reset: txfull_o and rxfull_o should be 0"
                )
            end
        end
    endfunction

endclass