class tb_drv extends uvm_driver #(tb_seq_item);
    `uvm_component_utils(tb_drv)

    virtual uart_inf #(DATA_WIDTH) vif;
    uvm_analysis_port #(tb_seq_item) rx_ap;

    function new(
        string name,
        uvm_component parent
    );
        super.new(name, parent);
        rx_ap = new("rx_ap", this);
    endfunction

    function void build_phase(
        uvm_phase phase
    );

        super.build_phase(phase);
        if (!uvm_config_db #(
            virtual uart_inf#(DATA_WIDTH)
        )::get(
            this,
            "",
            "vif", vif
            )
        ) begin
            `uvm_fatal(
                "[DRV]",
                "Cannot get virtual interface"
            );
        end
    endfunction

    task run_phase(
        uvm_phase phase
    );

        tb_seq_item seq;
        tb_seq_item rx_expected;
        forever begin
            seq_item_port.get_next_item(seq);

            @(negedge vif.clk_i)
                vif._rst_i      = seq._rst_i;
                vif.uartrx_i    = seq.uartrx_i;
                vif.rdrx_en_i   = seq.rdrx_en_i;
                vif.uarttx_i    = seq.uarttx_i;
                vif.wrtx_en_i   = seq.wrtx_en_i;

                if (seq.send_rx) begin
                    send_uart_byte(seq.rx_data);

                    rx_expected = tb_seq_item::type_id::create("rx_expected");
                    rx_expected._rst_i = 1;
                    rx_expected.send_rx = 1;
                    rx_expected.rx_data = seq.rx_data;

                    rx_ap.write(rx_expected);
                end

            @(posedge vif.clk_i)
                seq_item_port.item_done();
        end
    endtask

    task send_uart_byte(
        input logic [DATA_WIDTH-1:0] data
    );
        vif.uartrx_i = 1'b0;
        #(1s / 9600.0);

        for (int i = 0; i < DATA_WIDTH; i++) begin
            vif.uartrx_i = data[i];
            #(1s / 9600.0);
        end

        vif.uartrx_i = 1'b1;
        #(1s / 9600.0);
    endtask
endclass