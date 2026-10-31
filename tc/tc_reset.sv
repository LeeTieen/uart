class tc_reset_seq extends tb_seq;
    `uvm_object_utils(tc_reset_seq)

    function new(
        string name = "tc_reset_seq"
    );
        super.new(name);
    endfunction

    task body();
        run(0, 1, 1, 8'h55, 1);
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        run(1, 1, 0, 8'hA5, 1);
        run(1, 1, 0, '0, 0);
    endtask
endclass

class tc_reset extends tb_test;
    `uvm_component_utils(tc_reset)

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
            tc_reset_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass