class tb_mon extends uvm_monitor;

    `uvm_component_utils(tb_mon)
    virtual uart_inf #(DATA_WIDTH) vif;
    uvm_analysis_port #(tb_seq_item) ap;

    coverage cov;
    bit tx_active = 0;
    bit rx_active = 0;

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

        super.build_phase(phase);
        cov = new();

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

    task monitor_host();
        
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

                if (seq._rst_i)
                    cov.sample_activity(tx_active, rx_active);

                cov.sample(seq);
                ap.write(seq);
        end
    endtask

    task receive_uart_byte(
        output logic [DATA_WIDTH-1:0] data_out
    );
        
        @(negedge vif.uarttx_o);
        tx_active = 1;

        #(1.5 * 104us);
        for (int i = 0; i < DATA_WIDTH; i++) begin
            data_out[i] = vif.uarttx_o;
            #104us;
        end

        if (vif.uarttx_o !== 1'b1)
            `uvm_error(
                "[MON]",
                "TX stop bit should be 1"
                )
  endtask

  

    task monitor_tx();
        logic [DATA_WIDTH-1:0]  data;
        bit                     receive_done;
        tb_seq_item             tx_seq;
        

        forever begin
        wait (vif._rst_i === 1'b1);

        receive_done = 0;

        fork
                begin
                    receive_uart_byte(data);
                    receive_done = 1;
                end

                begin
                    forever begin
                        @(posedge vif.clk_i)
                            if (vif._rst_i === 1'b0)
                                break;
                    end
                end
            join_any

            disable fork;
            tx_active = 0;

            if (receive_done && (vif._rst_i === 1'b1)) begin
                tx_seq = tb_seq_item::type_id::create("tx_seq");

                tx_seq._rst_i           = 1'b1;
                tx_seq.tx_byte_valid    = 1'b1;
                tx_seq.tx_byte          = data;

                cov.sample(tx_seq);
                ap.write(tx_seq);
            end
        end
    endtask

    task monitor_rx_activity();
        forever begin
            wait (vif._rst_i === 1'b1);

            fork
                begin
                    @(negedge vif.uartrx_i);

                    rx_active = 1;

                    #((DATA_WIDTH + 1.5) * (1s / 9600.0));
                end

                begin
                    forever begin
                        @(posedge vif.clk_i);
                        if (vif._rst_i === 1'b0)
                            break;
                    end
                end
            join_any

            disable fork;
            rx_active = 0;
        end
    endtask

    task run_phase(uvm_phase phase);
        fork
            monitor_host();
            monitor_tx();
            monitor_rx_activity();
        join
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(
            "COVERAGE",
            $sformatf(
                "Data coverage: TX=%0.2f%%, RX=%0.2f%%",
                cov.uart_data_cg.cp_tx_data.get_inst_coverage(),
                cov.uart_data_cg.cp_rx_data.get_inst_coverage()
            ),
            UVM_NONE
        )

        `uvm_info(
            "COVERAGE",
            $sformatf(
                "Boundary coverage: %0.2f%%",
                cov.uart_boundary_cg.get_inst_coverage()
            ),
            UVM_NONE
            )

        `uvm_info(
            "COVERAGE",
            $sformatf(
                "Reset coverage: %0.2f%%",
                cov.uart_reset_cg.get_inst_coverage()
            ),
            UVM_NONE
        )

        `uvm_info(
            "COVERAGE",
            $sformatf(
                "Activity coverage: %0.2f%%",
                cov.uart_activity_cg.get_inst_coverage()
            ),
            UVM_NONE
        )

    endfunction
endclass
