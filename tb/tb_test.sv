class tb_test extends uvm_test;
    `uvm_component_utils(tb_test)

    tb_env env;

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

        env = tb_env::type_id::create("env", this);
    endfunction

    task run_phase(
        uvm_phase phase
    );

        tb_seq seq;

        phase.raise_objection(this);

        seq = tb_seq::type_id::create("seq");
        seq.start(env.sqr);

        phase.drop_objection(this);
    endtask
endclass