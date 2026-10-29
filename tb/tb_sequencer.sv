class tb_sequencer extends uvm_sequencer #(uvm_sequence_item);
  `uvm_component_utils(tb_sequencer)
  
  function new(
    string name,
    uvm_component parent
  );

    super.new(name, parent);

  endfunction : new

endclass