module seq_1010_tb;
    // Clock and reset signals
    reg     clk, rst, din;
    wire    dout;

    // Test control
    integer i;
    reg [31:0] test_vectors [0:19];  // 20 test bits
    reg [31:0] expected_outputs [0:19]; // Expected outputs for each clock cycle

    // Clock generation: 10 time units period (5 high, 5 low)
    parameter CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test vectors: input sequence and expected outputs
    // We're testing: 1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
    // Expected:      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0
    // (The 1010 sequence should be detected at bit position 18-21, outputting high at cycle 20)
    initial begin
        // Define test vectors
        test_vectors[0]  = 1; test_vectors[1]  = 0; test_vectors[2]  = 1; test_vectors[3]  = 0;
        test_vectors[4]  = 1; test_vectors[5]  = 0; test_vectors[6]  = 1; test_vectors[7]  = 0;
        test_vectors[8]  = 1; test_vectors[9]  = 0; test_vectors[10] = 1; test_vectors[11] = 0;
        test_vectors[12] = 1; test_vectors[13] = 0; test_vectors[14] = 1; test_vectors[15] = 0;
        test_vectors[16] = 1; test_vectors[17] = 0; test_vectors[18] = 1; test_vectors[19] = 0;

        // Define expected outputs (high only when "1010" is detected)
        expected_outputs[0]  = 0; expected_outputs[1]  = 0; expected_outputs[2]  = 0; expected_outputs[3]  = 0;
        expected_outputs[4]  = 0; expected_outputs[5]  = 0; expected_outputs[6]  = 0; expected_outputs[7]  = 0;
        expected_outputs[8]  = 0; expected_outputs[9]  = 0; expected_outputs[10] = 0; expected_outputs[11] = 0;
        expected_outputs[12] = 0; expected_outputs[13] = 0; expected_outputs[14] = 0; expected_outputs[15] = 0;
        expected_outputs[16] = 0; expected_outputs[17] = 0; expected_outputs[18] = 0; expected_outputs[19] = 1;

        // Initialize signals
        clk = 0;
        rst = 1;
        din = 0;

        // Apply reset
        #25 rst = 0;

        // Apply test vectors synchronously with clock
        for (i = 0; i < 20; i = i + 1) begin
            @(negedge clk);  // Apply input on negative clock edge
            din = test_vectors[i];
            @(posedge clk);  // Wait for positive clock edge to check output
            #1;  // Small delay to allow output to settle
            if (dout !== expected_outputs[i]) begin
                $display("ERROR: At time %0t, cycle %0d: Expected dout = %b, Got dout = %b (input = %b)",
                         $time, i, expected_outputs[i], dout, test_vectors[i]);
            end else begin
                $display("OK:   At time %0t, cycle %0d: Input = %b, Expected dout = %b, Actual dout = %b",
                         $time, i, test_vectors[i], expected_outputs[i], dout);
            end
        end

        // Additional test: check reset functionality
        $display("\n--- Testing reset functionality ---");
        @(negedge clk);
        din = 1;  // Set input to 1
        @(posedge clk);  // Clock in the 1
        @(negedge clk);
        rst = 1;  // Assert reset
        @(posedge clk);  // Clock with reset
        #1;
        if (dout !== 0) begin
            $display("ERROR: Reset test failed: Expected dout = 0 during reset, Got dout = %b", dout);
        end else begin
            $display("OK:   Reset test passed: dout = %b during reset", dout);
        end

        // Deassert reset and continue
        @(negedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        // Final test: apply another sequence to verify recovery
        $display("\n--- Testing recovery after reset ---");
        test_vectors[0] = 1; test_vectors[1] = 0; test_vectors[2] = 1; test_vectors[3] = 0;
        expected_outputs[0] = 0; expected_outputs[1] = 0; expected_outputs[2] = 0; expected_outputs[3] = 1;
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            din = test_vectors[i];
            @(posedge clk);
            #1;
            if (dout !== expected_outputs[i]) begin
                $display("ERROR: Recovery test - At time %0t, cycle %0d: Expected dout = %b, Got dout = %b (input = %b)",
                         $time, i, expected_outputs[i], dout, test_vectors[i]);
            end else begin
                $display("OK:   Recovery test - At time %0t, cycle %0d: Input = %b, Expected dout = %b, Actual dout = %b",
                         $time, i, test_vectors[i], expected_outputs[i], dout);
            end
        end

        #20 $stop;
    end

    // Instantiate the unit under test
    seq_1010 uut(
        .i_clock(clk),
        .i_reset(rst),
        .i_btn(din),
        .o_led(dout)
    );

    // Optional: dump waveforms for viewing
    initial begin
        $dumpfile("seq_1010_tb.vcd");
        $dumpvars(0, seq_1010_tb);
    end
endmodule