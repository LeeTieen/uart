class tc_data_all_values_seq extends tb_seq;
    `uvm_object_utils(tc_data_all_values_seq)

    function new(string name = "tc_data_all_values_seq");
        super.new(name);
    endfunction

    task body();
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        for (int i = 0; i < 256; i++) begin
            send_rx_byte(i);

            run(1, 1, 1, i, 1);

            run(1, 1, 0, '0, 0);
        end
    endtask
endclass


class tc_data_all_values extends tb_test;
    `uvm_component_utils(tc_data_all_values)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_data_all_values_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass