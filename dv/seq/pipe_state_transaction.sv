class pipe_state_transaction extends uvm_sequence_item;
    `uvm_object_utils(pipe_state_transaction)

    bit [catawba_params::XLEN-1:0] int_regs [0:`NUM_REGS-1];
    memory_t data_memory;

    const static string register2abinames [0:`NUM_REGS-1] = '{
        "x0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
        "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
        "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
        "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
    };

    function new(string name = "");
        super.new(name);
    endfunction

    function string convert2string();
        string s;

        s = "";

        s = {s, "----- Int Registers -----\n"};
        foreach (int_regs[i]) begin
            s = {s, $sformatf("%-3s (x%-2d): %08x\n", register2abinames[i], i, int_regs[i])};
        end

        s = {s, "----- Memory -----\n"};
        foreach (data_memory[i]) begin
            s = {s, $sformatf("0x%08x: %08x\n", i, data_memory[i])};
        end

        return s;
    endfunction

    function string print_comparison(pipe_state_transaction other_tx);
        string s;

        s = "";

        s = {s, "----- Integer Registers -----\n"};
        foreach (int_regs[i]) begin
            s = {
                s,
                $sformatf(
                    "%-3s (x%-2d): %08x %1s %08x\n",
                    register2abinames[i], i,
                    int_regs[i],
                    (int_regs[i] == other_tx.int_regs[i]) ? "" : "|",
                    other_tx.int_regs[i]
                )
            };
        end

        s = {s, "----- Memory Comparison -----\n"};
        foreach (data_memory[i]) begin
            s = {
                s,
                $sformatf(
                    "0x%08x: %08x %1s %08x\n",
                    i,
                    data_memory[i],
                    (data_memory[i] == other_tx.data_memory[i]) ? "" : "|",
                    other_tx.data_memory[i]
                )
            };
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
            int_regs    == _obj.int_regs    &
            data_memory == _obj.data_memory ;
    endfunction
endclass
