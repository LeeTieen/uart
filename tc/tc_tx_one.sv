class tc_tx_one_seq extends tb_seq;
    `uvm_object_utils(tc_tx_one_seq)

    function new(
        string name = "tc_tx_one_seq"
    );
        super.new(name);
    endfunction

    task body();
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        run(1, 1, 0, 8'h55, 1);
        run(1, 1, 0, 8'hAA, 0);
    endtask
endclass

class tc_tx_one extends tb_test;
    `uvm_component_utils(tc_tx_one)

    function new(
        string name,
        uvm_component parent
    );
        super.new(name, parent);
    endfunction

    function void build_phase(
        uvm_phase phase
    );
        tb_seq::type_id::set_type_override(
            tc_tx_one_seq::get_type()
        );
        super.build_phase(phase);
    endfunction
endclass