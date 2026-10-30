class tb_env extends uvm_env;
    `uvm_component_utils(tb_env)

    tb_drv          drv;
    tb_mon          mon;
    tb_sco          sco;
    tb_sequencer    sqr;

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

        drv = tb_drv::type_id::create("drv", this);
        mon = tb_mon::type_id::create("mon", this);
        sco = tb_sco::type_id::create("sco", this);
        sqr = tb_sequencer::type_id::create("sqr", this);
    endfunction

    function void connect_phase(
        uvm_phase phase
    );

        super.connect_phase(phase);

        drv.seq_item_port.connect(sqr.seq_item_export);
        mon.ap.connect(sco.analysis_export);
    endfunction
endclass