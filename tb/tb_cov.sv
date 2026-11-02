class coverage;

    covergroup uart_data_cg with function sample(
        bit                  is_tx,
        bit [DATA_WIDTH-1:0] data
    );
        option.per_instance = 1;

        cp_tx_data: coverpoint data iff (is_tx) {
            bins values[] = {[0:255]};
        }

        cp_rx_data: coverpoint data iff (!is_tx) {
            bins values[] = {[0:255]};
        }
    endgroup

    covergroup uart_boundary_cg with function sample(tb_seq_item t);
        option.per_instance = 1;

        cp_tx_full: coverpoint t.txfull_o {
            bins has_space = {0};
            bins full      = {1};

            bins becomes_full = (0 => 1);
            bins leaves_full  = (1 => 0);
        }

        cp_rx_state: coverpoint {
            t.rxfull_o,
            t.rx_notem_o
        } {
            bins empty  = {2'b00};
            bins normal = {2'b01};
            bins full   = {2'b11};

            bins empty_to_normal = (2'b00 => 2'b01);
            bins normal_to_full  = (2'b01 => 2'b11);
            bins full_to_normal  = (2'b11 => 2'b01);
            bins normal_to_empty = (2'b01 => 2'b00);

            illegal_bins invalid = {2'b10};
        }

        cp_tx_write: coverpoint t.txfull_o iff (t.wrtx_en_i) {
            bins accepted = {0};
            bins rejected = {1};
        }

        cp_rx_read: coverpoint t.rx_notem_o iff (t.rdrx_en_i) {
            bins accepted = {1};
            bins rejected = {0};
        }
    endgroup

    covergroup uart_reset_cg with function sample(bit rst_n);
        option.per_instance = 1;

        cp_reset: coverpoint rst_n {
            bins asserted   = {0};
            bins deasserted = {1};
        }
    endgroup

    covergroup uart_activity_cg with function sample(
        bit tx_active,
        bit rx_active
    );
        option.per_instance = 1;

        cp_activity: coverpoint {tx_active, rx_active} {
            bins idle        = {2'b00};
            bins rx_only     = {2'b01};
            bins tx_only     = {2'b10};
            bins full_duplex = {2'b11};
        }
    endgroup

    function new();
        uart_data_cg        = new();
        uart_boundary_cg    = new();
        uart_reset_cg       = new();
        uart_activity_cg    = new();
    endfunction

    function void sample(tb_seq_item seq);
        if (!seq.tx_byte_valid)
            uart_reset_cg.sample(seq._rst_i);

        if (!seq._rst_i)
            return;

        if (seq.tx_byte_valid) begin
            uart_data_cg.sample(1, seq.tx_byte);
        end
        else begin
            uart_boundary_cg.sample(seq);

            if (seq.rdrx_en_i && seq.rx_notem_o)
                uart_data_cg.sample(0, seq.uartrx_o);
        end
    endfunction

    function void sample_activity(
        bit tx_active,
        bit rx_active
    );
        uart_activity_cg.sample(tx_active, rx_active);
    endfunction

endclass
