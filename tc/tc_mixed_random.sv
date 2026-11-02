class tc_mixed_random_seq extends tb_seq;
    `uvm_object_utils(tc_mixed_random_seq)

    function new(string name = "tc_mixed_random_seq");
        super.new(name);
    endfunction

    task body();
        int                     action;
        bit [DATA_WIDTH-1:0]    tx_data;
        bit [DATA_WIDTH-1:0]    rx_data;

        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        repeat (20) begin
            action  = $urandom_range(3, 0);
            tx_data = $urandom_range(255, 0);
            rx_data = $urandom_range(255, 0);

            case (action)
                0: begin
                    `uvm_info("MIXED_RANDOM", $sformatf("Action: TX, data = %02h", tx_data), UVM_NONE)

                    run(1, 1, 0, tx_data, 1);
                    run(1, 1, 0, '0, 0);
                end

                1: begin
                    `uvm_info("MIXED_RANDOM", $sformatf("Action: RX, data = %02h", rx_data), UVM_NONE)

                    send_rx_byte(rx_data);

                    run(1, 1, 1, '0, 0);
                    run(1, 1, 0, '0, 0);
                end

                2: begin
                    `uvm_info(
                        "MIXED_RANDOM",
                        $sformatf("Action: concurrent TX/RX, data TX = %02h, data RX = %02h", tx_data, rx_data),
                        UVM_NONE
                    )

                    run(1, 1, 0, tx_data, 1);
                    run(1, 1, 0, '0, 0);

                    send_rx_byte(rx_data);

                    run(1, 1, 1, '0, 0);
                    run(1, 1, 0, '0, 0);
                end

                3: begin
                    `uvm_info("MIXED_RANDOM", "Action: RESET", UVM_NONE)

                    run(0, 1, 0, '0, 0);
                    run(1, 1, 0, '0, 0);
                end
            endcase
        end

        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_mixed_random extends tb_test;
    `uvm_component_utils(tc_mixed_random)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_mixed_random_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass