class tc_full_duplex_seq extends tb_seq;
    `uvm_object_utils(tc_full_duplex_seq)

    function new(string name = "tc_full_duplex_seq");
        super.new(name);
    endfunction

    task body();
        bit [DATA_WIDTH-1:0] tx_data[3] = '{
            8'h55, 8'hAA, 8'hA5
        };

        bit [DATA_WIDTH-1:0] rx_data[3] = '{
            8'h12, 8'h34, 8'h56
        };

        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        foreach (tx_data[i]) begin
            run(1, 1, 0, tx_data[i], 1);
            run(1, 1, 0, '0, 0);
        end

        foreach (rx_data[i])
            send_rx_byte(rx_data[i]);

        repeat (3)
            run(1, 1, 1, '0, 0);

        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_full_duplex extends tb_test;
    `uvm_component_utils(tc_full_duplex)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_full_duplex_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass