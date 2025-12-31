class pipe_state_transaction extends uvm_sequence_item;
    `uvm_object_utils(pipe_state_transaction)

    bit [catawba_params::XLEN-1:0] int_regs [0:`NUM_REGS-1];
    memory_t data_memory;

    function new(string name = "");
        super.new(name);
    endfunction

    function string convert2string();
        string s;

        s = "";

        s = {s, "----- Registers -----\n"};
        foreach (int_regs[i]) begin
            s = {s, $sformatf("x%0d: %08x/%d\n", i, int_regs[i], int_regs[i])};
        end

        s = {s, "----- Data Memory -----\n"};
        foreach (data_memory[i]) begin
            s = {s, $sformatf("0x%08x: %08x\n", i, data_memory[i])};
        end

        return s;
    endfunction

    virtual function void do_copy(uvm_object rhs);
        pipe_state_transaction _obj;
        $cast(_obj, rhs);

        // https://verificationacademy.com/forums/t/copy-assoc-array-to-assoc-arry/30549
        int_regs    = _obj.int_regs;
        data_memory = _obj.data_memory;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        pipe_state_transaction _obj;
        $cast(_obj, rhs);

        // https://verificationacademy.com/forums/t/compare-2-queues-2-associative-arrays-2-dynamic-arrays/36900
        return
            int_regs    == _obj.int_regs; // FIXME: need to compare memory and int_regs
            // int_regs    == _obj.int_regs    &
            // data_memory == _obj.data_memory ;
    endfunction
endclass
