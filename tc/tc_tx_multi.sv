class tc_tx_multi_seq extends tb_seq;
    `uvm_object_utils(tc_tx_multi_seq)

    function new(
        string name = "tc_tx_multi_seq"
    );
        super.new(name);
    endfunction

    task body();
        bit [DATA_WIDTH-1:0] data_list[5] = '{8'h00, 8'hFF, 8'h55, 8'hAA, 8'hA5};

        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        foreach (data_list[i]) begin
            run(1, 1, 0, data_list[i], 1);
            run(1, 1, 0, '0, 0);
        end
    endtask
endclass

class tc_tx_multi extends tb_test;
    `uvm_component_utils(tc_tx_multi)

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
            tc_tx_multi_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass