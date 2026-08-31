module seq_1010(
    input   i_clock,
    input   i_reset,
    input   i_btn,
    output  o_led
);
// Mealy FSM to detect binary sequence "1010"
// Mealy machine: Output depends on both current state and current input
localparam [2:0] s0 = 3'b000,  // Initial state, waiting for first '1'
                 s1 = 3'b001,  // Received first '1', waiting for '0'
                 s2 = 3'b010,  // Received "10", waiting for '1'
                 s3 = 3'b011,  // Received "101", waiting for '0' (sequence completion)
                 s4 = 3'b100;  // Sequence "1010" detected (output asserted)

reg [2:0] state, next_state;

// State register (synchronous reset)
always@(posedge i_clock) begin
    if(i_reset)
        state <= s0;
    else
        state <= next_state;
end

// Next state logic (combinational)
always@(*) begin
    next_state = state;  // Default: hold current state
    case(state)
        s0: next_state = i_btn ? s1 : s0;  // If input=1 -> s1, else stay in s0
        s1: next_state = i_btn ? s1 : s2;  // If input=1 -> s1 (still waiting for first 0), else -> s2
        s2: next_state = i_btn ? s3 : s0;  // If input=1 -> s3 (got "101"), else -> s0 (reset)
        s3: next_state = i_btn ? s1 : s4;  // If input=1 -> s1 (could be start of new sequence), else -> s4 (sequence detected!)
        s4: next_state = i_btn ? s1 : s0;  // If input=1 -> s1 (start looking for new sequence), else -> s0
    endcase
end

// Output logic (Mealy: output asserted when in state s4)
assign o_led = (state == s4) ? 1'b1 : 1'b0;
endmodule
