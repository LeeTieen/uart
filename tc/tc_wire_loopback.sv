class tc_wire_loopback_seq extends tb_seq;
    `uvm_object_utils(tc_wire_loopback_seq)

    virtual uart_inf #(DATA_WIDTH) vif;
    uvm_analysis_port #(tb_seq_item) rx_expected_ap;

    function new(string name = "tc_wire_loopback_seq");
        super.new(name);
    endfunction

    task body();
        tb_seq_item expected;
        bit         rx_received = 0;

        run(0, 1, 0, '0, 0);
        run(1, 1, 0, '0, 0);

        expected            = tb_seq_item::type_id::create("expected");
        expected._rst_i     = 1;
        expected.send_rx    = 1;
        expected.rx_data    = 8'hA5;
        rx_expected_ap.write(expected);

        // Host ghi A5 để UART TX phát
        run(1, 1, 0, 8'hA5, 1);
        run(1, 1, 0, '0, 0);

        fork
            // Đưa mọi thay đổi của TX sang RX
            begin
                forever begin
                    vif.uartrx_i = vif.uarttx_o;
                    @(vif.uarttx_o);
                end
            end

            // Chờ RX nhận được byte
            begin
                for (int i = 0; i < 20000; i++) begin
                    @(posedge vif.clk_i);
                    #1ps;

                    if (vif.rx_notem_o === 1'b1) begin
                        rx_received = 1;
                        break;
                    end
                end

                if (!rx_received) begin
                    `uvm_fatal(
                        "LOOPBACK_TIMEOUT",
                        "RX did not receive loopback data"
                    )
                end
            end
        join_any

        disable fork;

        // Kết thúc chuyển tiếp serial, giữ RX ở mức nghỉ
        vif.uartrx_i = 1;

        // Đọc byte nhận lại
        run(1, 1, 1, '0, 0);

        // Đọc thêm: không được có byte thừa
        run(1, 1, 1, '0, 0);
        run(1, 1, 0, '0, 0);
    endtask
endclass


class tc_wire_loopback extends tb_test;
    `uvm_component_utils(tc_wire_loopback)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        tc_wire_loopback_seq seq;

        phase.raise_objection(this);

        seq = tc_wire_loopback_seq::type_id::create("seq");
        seq.vif = env.drv.vif;
        seq.rx_expected_ap = env.drv.rx_ap;

        seq.start(env.sqr);

        fork
            begin
                wait (env.sco.tx_pending == 0);
                #1100us;
            end

            begin
                #3ms;
                `uvm_fatal(
                    "TX_TIMEOUT",
                    "Timeout waiting for loopback TX result"
                )
            end
        join_any

        disable fork;
        phase.drop_objection(this);
    endtask
endclass