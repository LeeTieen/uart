class tb_mon extends uvm_monitor;

    `uvm_component_utils(tb_mon)
    virtual uart_inf #(DATA_WIDTH) vif;
    uvm_analysis_port #(tb_seq_item) ap;

    function new(
        string name,
        uvm_component parent
    );
        
        super.new(name, parent);
        ap = new("ap", this);

    endfunction

    function void build_phase(
        uvm_phase phase
    );

        if (!uvm_config_db#(
            virtual uart_inf #(DATA_WIDTH)
        )::get(
            this,
            "",
            "vif",
            vif
            )
        ) begin
            `uvm_fatal(
                "[MON]",
                "Cannot get virtual interface"
            );
        end
    endfunction

    task run_phase(
        uvm_phase phase
    );
        super.build_phase(phase);
        tb_seq_item seq;
        forever begin
            @(posedge vif.clk_i)
                seq = tb_seq_item::type_id::create("seq");

                seq._rst_i      = vif._rst_i;
                seq.uartrx_i    = vif.uartrx_i;
                seq.rdrx_en_i   = vif.rdrx_en_i;
                seq.uarttx_i    = vif.uarttx_i;
                seq.wrtx_en_i   = vif.wrtx_en_i;


                seq.uartrx_o    = vif.uartrx_o;
                seq.rx_notem_o  = vif.rx_notem_o;
                seq.rxfull_o    = vif.rxfull_o;
                seq.uarttx_o    = vif.uarttx_o;
                seq.txfull_o    = vif.txfull_o;

                #1ps;
                seq.uartrx_o_after      = vif.uartrx_o;
                seq.rx_notem_o_after    = vif.rx_notem_o;
                seq.rxfull_o_after      = vif.rxfull_o;
                seq.uarttx_o_after      = vif.uarttx_o;
                seq.txfull_o_after      = vif.txfull_o;

                ap.write(seq);
        end
    endtask
endclass
