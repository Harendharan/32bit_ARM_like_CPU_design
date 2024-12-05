module dmem (
    input clk, 
    input we, 
    input [31:0] a, wd, 
    output wire [31:0] rd
);

  reg [31:0] RAM [63:0]; // 64 X 32
   
    assign rd = RAM[a[31:2]];  // Word-aligned read (a[31:2] gives the index)
   

    // Memory write
    always @(posedge clk) begin
        if (we) begin
            RAM[a[31:2]] <= wd;  // Write data to the corresponding address
        end
    end

endmodule
