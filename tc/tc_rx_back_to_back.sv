class tc_rx_back_to_back_seq extends tb_seq;
    `uvm_object_utils(tc_rx_back_to_back_seq)

    virtual uart_inf #(DATA_WIDTH) vif;
    uvm_analysis_port #(tb_seq_item) rx_expected_ap;

    function new(string name = "tc_rx_back_to_back_seq");
        super.new(name);
    endfunction

    task send_frame(input bit [DATA_WIDTH-1:0] data);
        vif.uartrx_i = 0;
        #(1s / 9600.0);

        for (int i = 0; i < DATA_WIDTH; i++) begin
            vif.uartrx_i = data[i];
            #(1s / 9600.0);
        end

        vif.uartrx_i = 1;
        #(1s / 9600.0);
    endtask

    task body();
        bit [DATA_WIDTH-1:0] data_list[3] = '{
            8'hA5, 8'h3C, 8'h7E
        };

        tb_seq_item expected;

        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        @(negedge vif.clk_i);

        foreach (data_list[i]) begin
            send_frame(data_list[i]);

            expected            = tb_seq_item::type_id::create("expected");
            expected._rst_i     = 1;
            expected.send_rx    = 1;
            expected.rx_data    = data_list[i];

            rx_expected_ap.write(expected);
        end

        repeat (3)
            run(1, 1, 1, '0, 0);

        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_rx_back_to_back extends tb_test;
    `uvm_component_utils(tc_rx_back_to_back)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        tc_rx_back_to_back_seq seq;

        phase.raise_objection(this);

        seq                 = tc_rx_back_to_back_seq::type_id::create("seq");

        seq.vif             = env.drv.vif;
        seq.rx_expected_ap  = env.drv.rx_ap;

        seq.start(env.sqr);

        #1ns;

        phase.drop_objection(this);
    endtask
endclass