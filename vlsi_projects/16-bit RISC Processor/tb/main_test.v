
`timescale 1ns / 1ps

module main_test();

    // Variable Declaration: Regs
    reg clk;
    reg reset;
    reg ram_we = 0;
    reg [15:0] dataI = 0;

    // Wires
    wire [2:0] selA;
    wire [2:0] selB;
    wire [2:0] selD;

    wire [15:0] dataA;
    wire [15:0] dataB;
    wire [15:0] dataD;

    wire [4:0] aluop;
    wire [7:0] imm;
    wire [15:0] dataO;

    wire [1:0] opcode;
    wire [15:0] pcO;

    wire shldBranch;
    wire enfetch;
    wire enalu;
    wire endec;
    wire enmem;
    wire enrgrd;
    wire enrgwr;
    wire regwe;
    wire update;

    // Assignments
    assign enrgwr = regwe & update;

    assign opcode = reset ? 2'b11 :
                    shldBranch ? 2'b10 :
                    enmem ? 2'b01 : 2'b00;

    // Register File
    reg_file main_reg(
        .I_clk(clk),
        .I_en(enrgrd),
        .I_we(enrgwr),
        .I_selA(selA),
        .I_selB(selB),
        .I_selD(selD),
        .I_dataD(dataD),
        .O_dataA(dataA),
        .O_dataB(dataB)
    );

    // Instruction Decoder
    inst_dec main_inst(
        .I_clk(clk),
        .I_en(endec),
        .I_inst(dataO),
        .O_aluop(aluop),
        .O_selA(selA),
        .O_selB(selB),
        .O_selD(selD),
        .O_imm(imm),
        .O_regwe(regwe)
    );

    // ALU
    alu main_alu(
        .I_clk(clk),
        .I_en(enalu),
        .I_aluop(aluop),
        .I_dataA(dataA),
        .I_dataB(dataB),
        .I_imm(imm),
        .O_dataResult(dataD),
        .O_shldBranch(shldBranch)
    );

    // Control Unit
    ctrl_unit main_ctrl(
        .I_clk(clk),
        .I_reset(reset),
        .O_enfetch(enfetch),
        .O_endec(endec),
        .O_enrgrd(enrgrd),
        .O_enalu(enalu),
        .O_enrgwr(update),
        .O_enmem(enmem)
    );

    // Program Counter
    pc_unit pc_main(
        .I_clk(clk),
        .I_opcode(opcode),
        .I_pc(dataD),
        .O_pc(pcO)
    );

    // RAM
    fake_ram main_ram(
        .I_clk(clk),
        .I_we(ram_we),
        .I_addr(pcO),
        .I_data(dataI),
        .O_data(dataO)
    );

    // Test Sequence
    initial begin
        clk = 0;
        reset = 1;

        #20;
        reset = 0;
    end

    // Clock Generation
    always begin
        #5;
        clk = ~clk;
    end

endmodule
