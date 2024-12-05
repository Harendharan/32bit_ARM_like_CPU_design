module cpu(
  input clk, reset,
  output [31:0] PC, 
  input [31:0] Instr, 
  output MemWrite, 
  output [31:0] ALUResult, WriteData,
  input [31:0] ReadData
);

    // Internal wires
    wire [3:0] ALUFlags;
    wire RegWrite, ALUSrc, MemtoReg, PCSrc;
    wire [1:0] RegSrc, ImmSrc, ALUControl;

    // Controller
    controller c (clk, reset, Instr[31:12], ALUFlags, RegSrc, RegWrite, ImmSrc, ALUSrc, ALUControl, MemWrite, MemtoReg, PCSrc);

    // Datapath 
    datapath dp (clk, reset, RegSrc, RegWrite, ImmSrc, ALUSrc, ALUControl, MemtoReg, PCSrc, ALUFlags, PC, Instr, ALUResult, WriteData, ReadData);

endmodule


//controller
module controller(
    input clk, reset,
    input [31:12] Instr,
    input [3:0] ALUFlags,
    output reg [1:0] RegSrc,
    output reg RegWrite,
    output reg [1:0] ImmSrc,
    output reg ALUSrc,
    output reg [1:0] ALUControl,
    output reg MemWrite,
    output reg MemtoReg,
    output reg PCSrc
);

    wire [1:0] FlagW;
    wire PCS, RegW, MemW;

    decoder dec(
        Instr[27:26], Instr[25:20], Instr[15:12],
        FlagW, PCS, RegW, MemW, MemtoReg,
        ALUSrc, ImmSrc, RegSrc, ALUControl
    );

    condlogic cl(
        clk, reset, Instr[31:28], ALUFlags,
        FlagW, PCS, RegW, MemW, PCSrc, RegWrite, MemWrite
    );

endmodule


//decoder
module decoder(input [1:0] Op, input [5:0] Funct, input [3:0] Rd, output reg [1:0] FlagW, output reg PCS, RegW, MemW, output reg MemtoReg, ALUSrc, output reg [1:0] ImmSrc, RegSrc, ALUControl);

  reg Branch, ALUOp;
  reg [9:0] controls;

  assign {Branch, MemtoReg, MemW, ALUSrc, ImmSrc, RegW, RegSrc, ALUOp} = controls;

  always @(*) begin
    case (Op)
      2'b00: begin
        if (Funct[5]) 
          controls = 10'b0001001001; // Data processing-immediate
        else 
          controls = 10'b0000001001; // Data processing-register
      end

      2'b01: begin
        if (Funct[0]) 
          controls = 10'b0101011000; // LDR
        else 
          controls = 10'b0011010100; // STR
      end

      2'b10: begin
        controls = 10'b1001100010; // B 
      end

      default: begin
        controls = 10'bx; 
      end
    endcase
  end

  // ALU Decoder 
  always @(*) begin
    if (ALUOp) begin 
      case (Funct[4:1])
        4'b0100: ALUControl = 2'b00; // ADD
        4'b0010: ALUControl = 2'b01; // SUB
        4'b0000: ALUControl = 2'b10; // AND
        4'b1100: ALUControl = 2'b11; // ORR
        default: ALUControl = 2'bx;  // Unimplemented operation
      endcase

      // Update flags if S bit is set (C & V only for arithmetic instructions)
      FlagW[1] = Funct[0]; // C flag (for arithmetic)
      FlagW[0] = Funct[0] & (ALUControl == 2'b00 || ALUControl == 2'b01); // V flag (for arithmetic)
    end else begin
      ALUControl = 2'b00; // Default to ADD for non-DP instructions
      FlagW = 2'b00; // Do not update flags for non-DP instructions
    end
  end

  // PC Logic
  assign PCS = ((Rd == 4'b1111) && RegW) | Branch;

endmodule

//condlogic
module condlogic(input logic clk, reset, input [3:0] Cond, input [3:0] ALUFlags, input [1:0] FlagW, input PCS, RegW, MemW, output reg PCSrc, RegWrite, MemWrite);

  wire [1:0] FlagWrite;
  wire [3:0] Flags;
  reg CondEx;

  flopenr #(.WIDTH(2)) flagreg1(clk, reset, FlagWrite[1], ALUFlags[3:2], Flags[3:2]);
  flopenr #(.WIDTH(2)) flagreg0(clk, reset, FlagWrite[0], ALUFlags[1:0], Flags[1:0]);
  
  condcheck cc(Cond, Flags, CondEx);

  assign FlagWrite = FlagW & {2{CondEx}};
  assign RegWrite = RegW & CondEx;
  assign MemWrite = MemW & CondEx;
  assign PCSrc = PCS & CondEx;

endmodule

//flopenr
module flopenr #(parameter WIDTH = 8) (input clk, reset, en, input [WIDTH-1:0] d, output reg [WIDTH-1:0] q);

  always@(posedge clk, posedge reset)
    if (reset) q <= 0;
    else if (en) q <= d;

endmodule

//concheck
module condcheck(input [3:0] Cond, input [3:0] Flags, output reg CondEx);

  wire neg, zero, carry, overflow, ge;
  assign {neg, zero, carry, overflow} = Flags;
  assign ge = ~(neg ^ overflow);

  always@(*) begin
    case(Cond)
      4'b0000: CondEx = zero;              // EQ (Equal)
      4'b0001: CondEx = ~zero;             // NE (Not Equal)
      4'b0010: CondEx = carry;             // CS (Carry Set)
      4'b0011: CondEx = ~carry;            // CC (Carry Clear)
      4'b0100: CondEx = neg;               // MI (Minus)
      4'b0101: CondEx = ~neg;              // PL (Plus)
      4'b0110: CondEx = overflow;          // VS (Overflow Set)
      4'b0111: CondEx = ~overflow;         // VC (Overflow Clear)
      4'b1000: CondEx = carry & ~zero;     // HI (Unsigned Higher)
      4'b1001: CondEx = ~(carry & ~zero);  // LS (Unsigned Lower or Same)
      4'b1010: CondEx = ge;                // GE (Signed Greater or Equal)
      4'b1011: CondEx = ~ge;               // LT (Signed Less Than)
      4'b1100: CondEx = ~zero & ge;        // GT (Signed Greater Than)
      4'b1101: CondEx = ~(~zero & ge);     // LE (Signed Less Than or Equal)
      4'b1110: CondEx = 1'b1;              // AL (Always)
      default: CondEx = 1'bx;              // Undefined condition

    endcase
  end

endmodule


//datapath
module datapath (
  input clk,
  input reset,
  input [1:0] RegSrc,
  input RegWrite,
  input [1:0] ImmSrc,
  input ALUSrc,
  input [1:0] ALUControl,
  input MemtoReg,
  input PCSrc,
  output reg [3:0] ALUFlags,
  output reg [31:0] PC,
  input [31:0] Instr,
  output reg [31:0] ALUResult,
  output reg [31:0] WriteData,
  input [31:0] ReadData
);

  // Internal wires
  wire [31:0] PCNext, PCPlus4, PCPlus8;
  wire [31:0] ExtImm, SrcA, SrcB, Result;
  wire [3:0]  RA1, RA2;

// PC logic
mux2 #(.WIDTH(32)) pcmux (PCPlus4, Result, PCSrc, PCNext);

flopr pcreg (clk, reset, PCNext, PC);

adder pcadd1 (PC, 32'b100, PCPlus4);

adder pcadd2 (PCPlus4, 32'b100, PCPlus8);

// Register file logic
mux2 #(.WIDTH(4)) ra1mux (Instr[19:16], 4'b1111, RegSrc[0], RA1);

mux2 #(.WIDTH(4)) ra2mux (Instr[3:0], Instr[15:12], RegSrc[1], RA2);

regfile rf (clk, RegWrite, RA1, RA2, Instr[15:12], Result, PCPlus8, SrcA, WriteData);

mux2 #(.WIDTH(32)) resmux (ALUResult, ReadData, MemtoReg, Result);

extend ext (Instr[23:0], ImmSrc, ExtImm);

// ALU logic
mux2 #(.WIDTH(32)) srcbmux (WriteData, ExtImm, ALUSrc, SrcB);

alu alu (SrcA, SrcB, ALUControl, ALUResult, ALUFlags);


endmodule


module mux2 #(parameter WIDTH = 8) (
  input  wire [WIDTH-1:0] d0,   // Input 0
  input  wire [WIDTH-1:0] d1,   // Input 1
  input  wire s,                // Select signal
  output reg  [WIDTH-1:0] y     // Output
);

  always @(*) begin
    if (s) 
      y = d1; 
    else 
      y = d0;
  end

endmodule


module flopr (
  input clk,                 // Clock signal
  input reset,               // Reset signal
  input  [31:0] d,           // Data input
  output reg [31:0] q        // Data output
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      q <= 32'b0;            // Reset the output to 0
    end else begin
      q <= d;                // Capture the input data on the rising edge of clk
    end
  end

endmodule


module adder (
    input  [31:0] a, b,
  output [31:0] y
);
    assign y = a + b;
endmodule


module regfile (
  input clk,                  // Clock signal
  input we3,                  // Write enable signal
  input  [3:0] ra1, ra2, wa3, // Read and write addresses
  input  [31:0] wd3, r15,     // Write data and special register value (r15)
  output [31:0] rd1, rd2      // Read data outputs
);

 
  reg [31:0] rf[14:0];  // 32 X 15 Register file 

  // Read 
  assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1]; 
  assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];
  
  // Write
  always @(posedge clk) begin
    if (we3) begin
      rf[wa3] <= wd3; // Write data to register 
    end
  end

endmodule


module extend(
    input [23:0] Instr,
    input [1:0] ImmSrc,
    output reg [31:0] ExtImm
);

always @(*) begin
    case(ImmSrc)
        2'b00: ExtImm = {24'b0, Instr[7:0]};        
        2'b01: ExtImm = {20'b0, Instr[11:0]};            
        2'b10: ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00}; 
        default: ExtImm = 32'bx;                       
    endcase
end

endmodule


module alu (
  input  [31:0] SrcA,           // 32-bit input A
  input  [31:0] SrcB,           // 32-bit input B
  input  [1:0] ALUControl,      // ALU control signal to select operation
  output reg [31:0] ALUResult,  // 32-bit result
  output reg [3:0] ALUFlag      // ALU flag 
);

  reg Negative, Zero, Carry, Overflow;

  always @(*) begin
    Carry=0;
    Overflow=0;
    case (ALUControl)
      2'b10: begin // AND
        ALUResult = SrcA & SrcB;
      end
      2'b11: begin // OR
        ALUResult = SrcA | SrcB;
      end
      2'b00: begin // ADD
        {Carry, ALUResult} = SrcA + SrcB; 
        Overflow = (SrcA[31] == SrcB[31]) && (ALUResult[31] != SrcA[31]);
      end
      2'b01: begin // SUB
        {Carry, ALUResult} = SrcA - SrcB;
        Overflow = (SrcA[31] != SrcB[31]) && (ALUResult[31] != SrcA[31]);
      end
      default: begin
        ALUResult = 32'b0;
      end
    endcase
  end


  assign Zero = (ALUResult == 32'b0);
  assign Negative = ALUResult[31];
  assign ALUFlag = {Negative, Zero, Carry, Overflow};

endmodule
