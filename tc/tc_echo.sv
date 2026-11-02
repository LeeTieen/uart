class tc_echo_seq extends tb_seq;
    `uvm_object_utils(tc_echo_seq)

    function new(string name = "tc_echo_seq");
        super.new(name);
    endfunction

    task body();
        virtual uart_inf #(DATA_WIDTH) vif;
        logic [DATA_WIDTH-1:0] received_data;

        if (!uvm_config_db#(
            virtual uart_inf #(DATA_WIDTH)
        )::get(
            null,
            "uvm_test_top.env.drv",
            "vif",
            vif
        )) begin
            `uvm_fatal("NO_VIF", "Cannot get virtual interface")
        end

        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        send_rx_byte(8'hA5);

        fork
            begin
                run(1, 1, 1, '0, 0);
            end

            begin
                @(negedge vif.clk_i);
                #1ps;

                if (vif.rx_notem_o !== 1'b1) begin
                    `uvm_fatal(
                        "ECHO_RX_EMPTY",
                        "RX FIFO has no data to echo"
                    )
                end

                received_data = vif.uartrx_o;
            end
        join

        run(1, 1, 0, received_data, 1);
        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_echo extends tb_test;
    `uvm_component_utils(tc_echo)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        tb_seq::type_id::set_type_override(
            tc_echo_seq::get_type()
        );

        super.build_phase(phase);
    endfunction
endclass