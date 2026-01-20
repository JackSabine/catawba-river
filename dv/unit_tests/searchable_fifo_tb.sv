// Assert-based smoke test for generic_fifo's SEARCHABLE=1 mode, ported from
// store_queue_tb: search-recency semantics (most-recent-duplicate-wins),
// filling to DEPTH, draining while checking head/search at every step, and
// refilling+draining to confirm no stale valid bits/data linger. Run with
// xvlog/xelab/xsim or delete once covered by a real DV testbench.
module searchable_fifo_tb;

    localparam DEPTH = 4;

    bit clk = 0;
    bit rst;
    always #5 clk = ~clk;

    logic push, pop;
    logic [7:0] push_key, push_data;
    logic [7:0] head_key, head_data;
    logic full, empty;
    logic [7:0] search_key;
    logic search_hit;
    logic [7:0] search_data;

    searchable_fifo #(
        .fifo_data_t(logic [7:0]),
        .fifo_key_t(logic [7:0]),
        .DEPTH(DEPTH)
    ) dut (
        .clk,
        .rst,
        .push,
        .push_key,
        .push_data,
        .pop,
        .head_key,
        .head_data,
        .full,
        .empty,
        .search_key,
        .search_hit,
        .search_data
    );

    task automatic do_push(logic [7:0] k, logic [7:0] d);
        @(negedge clk);
        push = 1; pop = 0; push_key = k; push_data = d;
        @(negedge clk);
        push = 0;
    endtask

    task automatic do_pop();
        @(negedge clk);
        push = 0; pop = 1;
        @(negedge clk);
        pop = 0;
    endtask

    task automatic check_search(logic [7:0] key, logic exp_hit, logic [7:0] exp_data, string msg);
        search_key = key;
        #1;
        if (exp_hit) begin
            assert (search_hit && search_data == exp_data)
                else $fatal(1, "%s: expected hit=1 data=%0h, got hit=%0d data=%0h",
                            msg, exp_data, search_hit, search_data);
        end else begin
            assert (!search_hit)
                else $fatal(1, "%s: expected miss, got hit=1 data=%0h", msg, search_data);
        end
    endtask

    task automatic check_head(logic exp_empty, logic [7:0] exp_key, logic [7:0] exp_data, string msg);
        assert (empty == exp_empty)
            else $fatal(1, "%s: expected empty=%0d, got %0d", msg, exp_empty, empty);
        if (!exp_empty) begin
            assert (head_key == exp_key && head_data == exp_data)
                else $fatal(1, "%s: expected head key=%0h data=%0h, got key=%0h data=%0h",
                            msg, exp_key, exp_data, head_key, head_data);
        end
    endtask

    initial begin
        push = 0; pop = 0;
        push_key = '0; push_data = '0;
        rst = 1;
        repeat (2) @(negedge clk);
        rst = 0;

        // No entries yet: search must miss, fifo must report empty.
        check_search(8'hAA, 0, 'x, "empty fifo");
        check_head(1, 'x, 'x, "empty fifo has no head");

        // Fill to DEPTH (4) with a duplicate key (AA) among the entries:
        // AA/01, BB/02, AA/03, CC/04.
        assert (!full) else $fatal(1, "must not be full after 0 pushes");
        do_push(8'hAA, 8'h01);
        assert (!full) else $fatal(1, "must not be full after 1 push");
        do_push(8'hBB, 8'h02);
        assert (!full) else $fatal(1, "must not be full after 2 pushes");
        do_push(8'hAA, 8'h03);
        assert (!full) else $fatal(1, "must not be full after 3 pushes");
        do_push(8'hCC, 8'h04);
        assert (full) else $fatal(1, "must be full after 4 pushes into DEPTH=4 fifo");

        // Duplicates + no-match search while completely full.
        check_search(8'hAA, 1, 8'h03, "full fifo, most-recent AA");
        check_search(8'hBB, 1, 8'h02, "full fifo, BB");
        check_search(8'hCC, 1, 8'h04, "full fifo, CC");
        check_search(8'hEE, 0, 'x, "full fifo, no match expected");
        check_head(0, 8'hAA, 8'h01, "full fifo, oldest AA is head");

        // Drain and confirm every step along the way.
        do_pop();
        check_head(0, 8'hBB, 8'h02, "after 1st pop, BB is head");
        check_search(8'hAA, 1, 8'h03, "after 1st pop, AA(03) persists");

        do_pop();
        check_head(0, 8'hAA, 8'h03, "after 2nd pop, AA(03) is head");
        check_search(8'hBB, 0, 'x, "after 2nd pop, BB fully drained");

        do_pop();
        check_head(0, 8'hCC, 8'h04, "after 3rd pop, CC is head");
        check_search(8'hAA, 0, 'x, "after 3rd pop, AA fully drained");

        do_pop();
        check_head(1, 'x, 'x, "fifo empty after draining all entries");
        check_search(8'hCC, 0, 'x, "miss after all entries popped");
        assert (!full) else $fatal(1, "not full on empty fifo");

        // Fill to DEPTH again with fresh keys, drain completely, then
        // confirm searches for those same keys all miss on the now-empty
        // fifo (no stale valid bits/data linger).
        do_push(8'h11, 8'hA1);
        do_push(8'h22, 8'hA2);
        do_push(8'h33, 8'hA3);
        do_push(8'h44, 8'hA4);
        assert (full) else $fatal(1, "must be full again after refill");

        do_pop();
        do_pop();
        do_pop();
        do_pop();
        check_head(1, 'x, 'x, "fifo empty after draining the refill");

        check_search(8'h11, 0, 'x, "miss after drain: 11 no longer present");
        check_search(8'h22, 0, 'x, "miss after drain: 22 no longer present");
        check_search(8'h33, 0, 'x, "miss after drain: 33 no longer present");
        check_search(8'h44, 0, 'x, "miss after drain: 44 no longer present");

        // head > tail wraparound with matches at every valid entry: force
        // a known pointer state (rst), fill to DEPTH so tail wraps to 0,
        // pop 3 so head sits at the last remaining physical index (3),
        // then push 2 more so tail wraps back around past 0 to 2. Now
        // head(3) > tail(2) as raw indices, and every valid entry
        // (idx 3, 0, 1) shares the same search key. The physically lowest
        // index (1) holds the most recently pushed entry and must be the
        // one search returns, even though idx 3 is numerically higher.
        rst = 1;
        repeat (2) @(negedge clk);
        rst = 0;

        do_push(8'hAA, 8'h01); // idx0
        do_push(8'hAA, 8'h02); // idx1
        do_push(8'hAA, 8'h03); // idx2
        do_push(8'hAA, 8'h04); // idx3, tail wraps to 0, full

        do_pop(); // removes idx0 (01), head -> 1
        do_pop(); // removes idx1 (02), head -> 2
        do_pop(); // removes idx2 (03), head -> 3

        do_push(8'hAA, 8'h05); // idx0, tail -> 1
        do_push(8'hAA, 8'h06); // idx1, tail -> 2

        // head=3, tail=2: head > tail, valid entries at idx 3 (04), idx 0
        // (05), idx 1 (06) all keyed AA.
        assert (!full) else $fatal(1, "must not be full: only 3/4 entries valid");
        check_head(0, 8'hAA, 8'h04, "head>tail: oldest surviving entry (idx3) is head");
        check_search(8'hAA, 1, 8'h06,
            "head>tail: most recent match (idx1) must win over lower-age match at higher idx3");

        $display("searchable_fifo_tb: PASS");
        $finish;
    end

endmodule
