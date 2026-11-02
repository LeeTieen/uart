class tc_host_simultaneous_seq extends tb_seq;
    `uvm_object_utils(tc_host_simultaneous_seq)

    function new(string name = "tc_host_simultaneous_seq");
        super.new(name);
    endfunction

    task body();
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        send_rx_byte(8'hA5);
        send_rx_byte(8'h7E);

        run(1, 1, 1, 8'h12, 1);
        run(1, 1, 1, 8'h34, 1);

        run(1, 1, 1, 8'h56, 1);
        run(1, 1, 0, '0, 0);

        send_rx_byte(8'hA6);
        send_rx_byte(8'hB7);

        for (int i = 0; i < DEPTH + 4; i++) begin
            run(1, 1, 0, 8'h40 + i, 1);
            run(1, 1, 0, '0, 0);
        end

        run(1, 1, 1, 8'hF0, 1);
        run(1, 1, 1, 8'hF1, 1);

        run(1, 1, 1, 8'hF2, 1);
        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_host_simultaneous extends tb_test;
    `uvm_component_utils(tc_host_simultaneous)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_host_simultaneous_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass