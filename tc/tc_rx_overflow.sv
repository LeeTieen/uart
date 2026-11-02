class tc_rx_overflow_seq extends tb_seq;
    `uvm_object_utils(tc_rx_overflow_seq)

    function new(string name = "tc_rx_overflow_seq");
        super.new(name);
    endfunction

    task body();
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        for (int i = 0; i < DEPTH; i++)
            send_rx_byte(i);

        send_rx_byte(8'hFF);

        repeat (DEPTH)
            run(1, 1, 1, '0, 0);

        run(1, 1, 1, '0, 0);

        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_rx_overflow extends tb_test;
    `uvm_component_utils(tc_rx_overflow)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_rx_overflow_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass