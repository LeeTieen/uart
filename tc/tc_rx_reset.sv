class tc_rx_reset_seq extends tb_seq;
    `uvm_object_utils(tc_rx_reset_seq)

    function new(string name = "tc_rx_reset_seq");
        super.new(name);
    endfunction

    task body();
        bit [DATA_WIDTH-1:0] aborted_data = 8'hA5;

        // RESET when successfully received a frame
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        send_rx_byte(8'hA5);
        send_rx_byte(8'h7E);

        run(0, 1, 0, '0, 0);
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);

        send_rx_byte(8'h3C);

        run(1, 1, 1, '0, 0);

        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);

        // RESET when a frame is not successfully received
        // RESET in DATA
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        run(1, 0, 0, '0, 0);
        #104us;

        run(1, 1, 0, '0, 0);
        #104us;

        run(1, 0, 0, '0, 0);
        #104us;

        run(0, 1, 0, '0, 0);
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        #1100us;

        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);

        send_rx_byte(8'h3C);

        run(1, 1, 1, '0, 0);
        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);

        // RESET in START
        run(1, 0, 0, '0, 0);

        #26us;

        run(0, 1, 0, '0, 0);
        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        #1100us;

        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);

        send_rx_byte(8'h5A);

        run(1, 1, 1, '0, 0);

        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);

        // RESET in STOP
        run(1, 0, 0, '0, 0);
        #104us;

        for (int i = 0; i < DATA_WIDTH; i++) begin
            run(1, aborted_data[i], 0, '0, 0);
            #104us;
        end

        run(1, 1, 0, '0, 0); //Stop bit

        #26us; // quarter of stop bit time

        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        #1100us;

        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);

        send_rx_byte(8'hC3);

        run(1, 1, 1, '0, 0);

        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_rx_reset extends tb_test;
    `uvm_component_utils(tc_rx_reset)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_rx_reset_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass