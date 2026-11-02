class tc_rx_full_seq extends tb_seq;
    `uvm_object_utils(tc_rx_full_seq)

    function new(string name = "tc_rx_full_seq");
        super.new(name);
    endfunction

    task body();
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);
        
        for (int i = 0; i < DEPTH; i++)
            send_rx_byte(i);

        repeat (3)
            run(1, 1, 0, '0, 0);

        repeat (DEPTH)
            run(1, 1, 1, '0, 0);

        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_rx_full extends tb_test;
    `uvm_component_utils(tc_rx_full)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_rx_full_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass