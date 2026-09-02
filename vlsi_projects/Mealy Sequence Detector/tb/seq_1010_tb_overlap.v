`timescale 1ns/1ps
module seq_1010_tb_overlap;
    // Clock and reset signals
    reg     clk, rst, din;
    wire    dout;

    // Clock generation: 10 time units period (5 high, 5 low)
    parameter CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test for overlapping sequences: "101010" should detect two sequences
    // Input:      1  0  1  0  1  0
    // Expected:   0  0  0  1  0  1  (first 1010 at pos 0-3, second at pos 2-5)
    initial begin
        integer i;
        reg [31:0] test_vectors [0:5];
        reg [31:0] expected_outputs [0:5];

        // Define test vectors
        test_vectors[0] = 1; test_vectors[1] = 0; test_vectors[2] = 1;
        test_vectors[3] = 0; test_vectors[4] = 1; test_vectors[5] = 0;

        // Define expected outputs
        expected_outputs[0] = 0; expected_outputs[1] = 0; expected_outputs[2] = 0;
        expected_outputs[3] = 1; expected_outputs[4] = 0; expected_outputs[5] = 1;

        // Initialize signals
        clk = 0;
        rst = 1;
        din = 0;

        // Apply reset
        #25 rst = 0;

        // Apply test vectors synchronously with clock
        for (i = 0; i < 6; i = i + 1) begin
            @(negedge clk);  // Apply input on negative clock edge
            din = test_vectors[i];
            @(posedge clk);  // Wait for positive clock edge to check output
            #1;  // Small delay to allow output to settle
            if (dout !== expected_outputs[i]) begin
                $display("ERROR: Overlap test - At time %0t, cycle %0d: Expected dout = %b, Got dout = %b (input = %b)",
                         $time, i, expected_outputs[i], dout, test_vectors[i]);
            end else begin
                $display("OK:   Overlap test - At time %0t, cycle %0d: Input = %b, Expected dout = %b, Actual dout = %b",
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
        $dumpfile("seq_1010_tb_overlap.vcd");
        $dumpvars(0, seq_1010_tb_overlap);
    end
endmodule