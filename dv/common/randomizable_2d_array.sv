class randomizable_2d_array #(type T = int);
    local rand T array[];

    rand int unsigned num_rows, num_cols;
    rand int unsigned array_size;

    function new(string name = "");
    endfunction

    constraint array_con {
        array.size() == array_size;
    }

    function T at(int unsigned row, int unsigned col);
        assert(row < num_rows && col < num_cols);
        return array[row * num_cols + col];
    endfunction

    function void set(int unsigned row, int unsigned col, T value);
        assert(row < num_rows && col < num_cols);
        array[row * num_cols + col] = value;
    endfunction

    function void post_randomize();
        assert(num_rows * num_cols == array_size)
            else $fatal(
                0,
                $sformatf(
                    "randomizable_2d_array::post_randomize found num_rows (%0d) * num_cols (%0d) != array_size (%0d)",
                    num_rows, num_cols, array_size
                )
            );
    endfunction

    function string convert2string();
        string s;

        s = $sformatf("array[%0d][%0d] = {\n", num_rows, num_cols);

        for (int unsigned row = 0; row < num_rows; row++) begin
            for (int unsigned col = 0; col < num_cols; col++) begin
              s = {s, $sformatf("    array[%0d][%0d] = %0x\n", row, col, array[row * num_cols + col])};
            end
        end

        s = {s, "};\n"};

        return s;
    endfunction

    function int unsigned get_num_rows();
        return num_rows;
    endfunction

    function int unsigned get_num_cols();
        return num_cols;
    endfunction
endclass