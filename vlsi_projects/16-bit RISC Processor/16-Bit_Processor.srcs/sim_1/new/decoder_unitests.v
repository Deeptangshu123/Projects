
`timescale 1ns / 1ps

module decoder_unittests();

    // Variable Declaration: Regs
    reg I_Clk;
    reg I_En;
    reg [15:0] I_Inst;

    // Wires
    wire [4:0] O_Aluop;
    wire [2:0] O_SelA;
    wire [2:0] O_SelB;
    wire [2:0] O_SelD;
    wire [15:0] O_Imm;
    wire O_Regwe;

    // DUT: Device Under Test
    inst_dec inst_unit(
        // Inputs
        .I_clk(I_Clk),
        .I_en(I_En),
        .I_inst(I_Inst),

        // Outputs
        .O_aluop(O_Aluop),
        .O_selA(O_SelA),
        .O_selB(O_SelB),
        .O_selD(O_SelD),
        .O_imm(O_Imm),
        .O_regwe(O_Regwe)
    );

    initial begin
        // Time = 0
        I_Clk = 0;
        I_En = 0;
        I_Inst = 0;

        // Time = 10 ns
        #10;
        I_Inst = 16'b0001011100000100;

        // Time = 20 ns
        #10;
        I_En = 1;
    end

    // Clock Generation
    always begin
        #5;
        I_Clk = ~I_Clk;
    end

endmodule
