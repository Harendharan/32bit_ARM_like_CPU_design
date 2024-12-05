`include "cpu.v"
`include "imem.v"
`include "dmem.v"

module top (input clk, input reset);

    // Internal wires
    wire [31:0] PC, Instr, ReadData;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;

    // Instantiatioons
	cpu cpu(clk, reset, PC, Instr, MemWrite, DataAdr,WriteData, ReadData);
	imem imem(PC, Instr);
	dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
 

endmodule
