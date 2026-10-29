class tb_drv extends uvm_driver #(tb_seq_item);
    `uvm_component_utils(tb_drv)

    virtual uart_inf #(DATA_WIDTH) vif;

    function new(
        string name,
        uvm_component parent
    );

        super.new(name, parent);

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
        forever begin
            seq_item_port.get_next_item(seq);

            @(negedge vif.clk_i)
                vif._rst_i      = seq._rst_i;
                vif.uartrx_i    = seq.uartrx_i;
                vif.rdrx_en_i   = seq.rdrx_en_i;
                vif.uarttx_i    = seq.uarttx_i;
                vif.wrtx_en_i   = seq.wrtx_en_i;

            @(posedge vif.clk_i)
                seq_item_port.item_done();
        end
    endtask
endclass