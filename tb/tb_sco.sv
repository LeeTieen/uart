class tb_sco extends uvm_scoreboard;

    `uvm_component_utils(tb_sco)

    uvm_analysis_imp #(
        tb_seq_item,
        tb_sco
    ) analysis_export;

    bit [DATA_WIDTH-1:0] ffrx_mem[$];
    bit [DATA_WIDTH-1:0] fftx_mem[$];
    bit [DATA_WIDTH-1:0] expected_uartrx_o;

    int error_count = 0;
    bit tx_pending = 0;

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

        bit [DATA_WIDTH-1:0] expected_uarttx_o;

        if (!seq._rst_i) begin
            ffrx_mem.delete();
            fftx_mem.delete();
            tx_pending = 0;

            if ((seq.uarttx_o_after !== 1'b1) || (seq.uartrx_o_after !== 1'b0)) begin
                `uvm_error(
                    "SCO",
                    "Reset: uarttx_o should be 1 and uartrx_o should be 0"
                )
                error_count++;
            end

            if (seq.rx_notem_o_after === 1'b1) begin
                `uvm_error(
                    "SCO",
                    "Reset: rx_notem_o should be 0"
                )
                error_count++;
            end

            if ((seq.txfull_o_after !== 1'b0) || (seq.rxfull_o_after !== 1'b0)) begin
                `uvm_error(
                    "SCO",
                    "Reset: txfull_o and rxfull_o should be 0"
                )
                error_count++;
            end
            return;
        end

        if (seq.send_rx) begin
            if (ffrx_mem.size() < DEPTH) ffrx_mem.push_back(seq.rx_data);
            else begin
                `uvm_info(
                    "SCO",
                    "RX overflow: new byte is expected to discarded",
                    UVM_NONE
                )
            end

            return;
        end

        if (seq.tx_byte_valid) begin
            if (fftx_mem.size() == 0) begin
                `uvm_error(
                    "SCO",
                    "TX sent a byte but expected queue is empty"
                )
                error_count++;
            end

            else begin
                expected_uarttx_o = fftx_mem.pop_front();

                if (seq.tx_byte !== expected_uarttx_o) begin
                    `uvm_error(
                        "SCO",
                        $sformatf(
                            "TX FAIL: expected = %h, actual = %h",
                            expected_uarttx_o,
                            seq.tx_byte
                        )
                    )
                    error_count++;
                end
                else begin
                    `uvm_info(
                        "SCO",
                        $sformatf(
                            "TX MATCH: expected = %02h, actual = %02h",
                            expected_uarttx_o,
                            seq.tx_byte
                        ),
                        UVM_NONE
                    )
                end
            end
            tx_pending = (fftx_mem.size() > 0);
            return;
        end 

        read_ok     = seq.rdrx_en_i && seq.rx_notem_o;
        write_ok    = seq.wrtx_en_i && !seq.txfull_o;

        if (ffrx_mem.size() == DEPTH) begin
            if (seq.rxfull_o !== 1'b1) begin
                `uvm_error(
                    "SCO",
                    "RX FIFO has 8 expected bytes but full is not 1"
                )
                error_count++;
            end
        end

        if (read_ok) begin

            if (ffrx_mem.size() == 0) begin
                `uvm_error(
                    "SCO",
                    "RX read accepted but expected queue is empty"
                )
                error_count++;
            end

            else begin    
                expected_uartrx_o = ffrx_mem.pop_front();
                assert (seq.uartrx_o === expected_uartrx_o)
                begin
                    `uvm_info(
                        "SCO",
                        $sformatf(
                            "RX MATCH: expected=%02h, actual=%02h",
                            expected_uartrx_o,
                            seq.uartrx_o
                        ),
                        UVM_NONE
                    )
                end
                else begin
                    `uvm_error(
                        "SCO",
                        $sformatf(
                            "READ FAIL: expected = %h, actual = %h",
                            expected_uartrx_o,
                            seq.uartrx_o
                        )
                    )
                    error_count++;
                end
            end
        end

        else if (seq.rdrx_en_i) begin
            assert (seq.uartrx_o === '0)
            else begin
                `uvm_error(
                    "SCO",
                    $sformatf(
                        "READ REJECTED: UART empty, dout = %h",
                        seq.uartrx_o
                    )
                )
                error_count++;
            end
        end

        if (write_ok) begin
            fftx_mem.push_back(seq.uarttx_i);
            tx_pending = 1;
        end
        else if (seq.wrtx_en_i) begin
            `uvm_info(
                "SCO",
                $sformatf(
                    "TX FULL: write rejected, data = %02h",
                    seq.uarttx_i
                ),
                UVM_NONE
            )
        end
        
    endfunction

    function void check_phase(
        uvm_phase phase
    );

        super.check_phase(phase);

        if (fftx_mem.size() > 0) begin
            `uvm_error(
                "SCO",
                $sformatf(
                    "TX INCOMPLETE: %0d byte(s) still expected",
                    fftx_mem.size()
                )
            )
            error_count++;
        end
        else begin
            `uvm_info(
                "SCO",
                "TX expedted queue is empty",
                UVM_NONE
            )
        end

        if (ffrx_mem.size() > 0) begin
            `uvm_error(
                "SCO",
                $sformatf(
                    "RX INCOMPLETE: %0d byte(s) still expected",
                    ffrx_mem.size()
                )
            )
            error_count++;
        end
    endfunction

    function void report_phase(
        uvm_phase phase
    );
        super.report_phase(phase);

        if(error_count == 0) begin
            `uvm_info(
                "SCO",
                "TEST RESULT: PASS",
                UVM_NONE
            )
        end
        
        else begin
            `uvm_error(
                "SCO",
                $sformatf(
                    "TEST RESULT: FAIL - %0d error(s)",
                    error_count
                )
            )
        end
    endfunction

endclass