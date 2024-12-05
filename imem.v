module imem(
  input logic [31:0] a,
  output wire [31:0] rd
);
  reg [31:0] RAM[63:0]; // 62 X 32
  initial begin
	$readmemh("memfile.dat",RAM);
   end
   assign rd = RAM[a[31:2]]; 
endmodule

