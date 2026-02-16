class main_memory extends uvm_object;
    `uvm_object_utils(main_memory)

    local memory_t memory;

    function new(string name = "");
        super.new(name);
    endfunction

    local function uint32_t compute_default_value(uint32_t addr);
        return '0; // match spike BFM
    endfunction

    function uint32_t read(uint32_t addr, memory_operation_size_e op_size);
        uint32_t word_aligned_addr;
        uint32_t word_read;

        uint8_t  bytes [3:0];
        uint16_t halfs [1:0];
        uint8_t  piece_select;

        word_aligned_addr = addr & ~3; // Align to 4 bytes

        word_read = memory.exists(word_aligned_addr) ?
            memory[word_aligned_addr] :
            compute_default_value(word_aligned_addr);

        case (op_size)
            BYTE: begin
                bytes = {>>`BYTE{word_read}};
                piece_select = addr & 3;
                read = {24'h0, bytes[piece_select]};
            end
            HALF: begin
                halfs = {>>`HALF{word_read}};
                piece_select = (addr & 2) >> 1;
                read = {16'h0, halfs[piece_select]};
            end
            default: read = word_read;
        endcase
    endfunction

    function void write(uint32_t addr, memory_operation_size_e op_size, uint32_t data);
        uint32_t word_aligned_addr;
        uint32_t data_to_write;

        uint8_t  bytes [3:0];
        uint16_t halfs [1:0];
        uint8_t  piece_select;

        word_aligned_addr = addr & ~3; // Align to 4 bytes

        data_to_write = this.read(word_aligned_addr, WORD);

        case (op_size)
            BYTE: begin
                bytes = {>>`BYTE{data_to_write}};
                piece_select = addr & 3;
                bytes[piece_select] = data[7:0];
                data_to_write = {>>`BYTE{bytes[3:0]}};
            end
            HALF: begin
                halfs = {>>`HALF{data_to_write}};
                piece_select = (addr & 2) >> 1;
                halfs[piece_select] = data[15:0];
                data_to_write = {>>`HALF{halfs[1:0]}};
            end
            default: data_to_write = data;
        endcase

        memory[word_aligned_addr] = data_to_write;

        `uvm_info(
            get_full_name(),
            $sformatf("Received write to address 0x%08h with data 0x%08h", addr, data),
            UVM_MEDIUM
        )
    endfunction

    function void tb_write(uint32_t addr, uint32_t data);
        memory[addr] = data;
    endfunction

    function memory_t tb_pull_memory();
        return this.memory;
    endfunction
endclass
