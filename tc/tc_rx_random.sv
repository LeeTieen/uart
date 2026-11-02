class tc_rx_random_seq extends tb_seq;
    `uvm_object_utils(tc_rx_random_seq)

    function new(string name = "tc_rx_random_seq");
        super.new(name);
    endfunction

    task body();
        int num_bytes;
        int idle_cycles;
        bit [DATA_WIDTH-1:0] data;

        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        num_bytes = $urandom_range(DEPTH, 1);

        `uvm_info(
            "RX_RANDOM",
            $sformatf("Receiving %0d random bytes", num_bytes),
            UVM_NONE
        )

        repeat (num_bytes) begin
            data = $urandom_range(255, 0);
            send_rx_byte(data);
        end

        repeat (num_bytes) begin
            idle_cycles = $urandom_range(5, 0);

            repeat (idle_cycles)
                run(1, 1, 0, '0, 0);

            run(1, 1, 1, '0, 0);
            run(1, 1, 0, '0, 0);
        end
    endtask
endclass


class tc_rx_random extends tb_test;
    `uvm_component_utils(tc_rx_random)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_rx_random_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass